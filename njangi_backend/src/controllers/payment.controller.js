const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');
const { success, error } = require('../utils/response');
const { validateCameroonPhone } = require('../utils/phone');
const { getPayoutBreakdown, buildReleaseSchedule, TRUST_CHANGES, clamp } = require('../utils/trust');
const { notifyPaymentMade, notifyWinner } = require('../services/notification.service');
const mtn    = require('../services/mtn.service');
const orange = require('../services/orange.service');

const prisma = new PrismaClient();

// ─── INITIATE ─────────────────────────────────────────────────────────────────
const initiatePayment = async (req, res) => {
  try {
    const { groupId, amount, method, phone, note } = req.body;
    const userId = req.user.id;

    const cleanPhone = validateCameroonPhone(phone);
    if (!cleanPhone) {
      return error(res, 'Invalid phone number. Use 9 digits starting with 6. Example: 670123456', 400);
    }

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId, groupId } },
    });
    if (!membership) return error(res, 'You are not a member of this group', 403);

    const group = await prisma.group.findUnique({
      where: { id: groupId },
      include: { wallet: true },
    });
    if (!group) return error(res, 'Group not found', 404);
    if (group.status !== 'ACTIVE') {
      return error(res, `Group is "${group.status}". Ask the admin to activate it first.`, 400);
    }

    const gross = parseFloat(amount);
    if (Math.abs(gross - group.contributionAmt) > 0.01) {
      return error(res, `Amount must be exactly ${group.contributionAmt} XAF`, 400);
    }

    const duplicate = await prisma.payment.findFirst({
      where: { userId, groupId, cycleNumber: group.currentCycle, status: 'SUCCESS' },
    });
    if (duplicate) return error(res, `You already paid for cycle ${group.currentCycle}`, 409);

    const platformFee  = parseFloat((gross * 0.01).toFixed(2));
    const insuranceFee = parseFloat((gross * 0.005).toFixed(2));
    const netAmount    = parseFloat((gross - platformFee - insuranceFee).toFixed(2));
    const reference    = uuidv4();

    let apiResult;
    if (method === 'MTN_MOMO') {
      apiResult = await mtn.requestPayment({ amount: gross, phone: cleanPhone, reference, groupName: group.name });
    } else if (method === 'ORANGE_MONEY') {
      apiResult = await orange.requestPayment({ amount: gross, phone: cleanPhone, reference, groupName: group.name });
    } else {
      return error(res, 'Invalid payment method. Use MTN_MOMO or ORANGE_MONEY', 400);
    }

    if (!apiResult.success) {
      return error(res, `Payment error: ${apiResult.message}`, 502);
    }

    const payment = await prisma.payment.create({
      data: {
        userId, groupId, amount: gross, method,
        phone: cleanPhone, status: 'PROCESSING',
        reference, externalRef: apiResult.externalId || reference,
        cycleNumber: group.currentCycle,
        platformFee, insuranceFee, netAmount,
        note: note || null,
      },
    });

    const sandbox = process.env.NODE_ENV === 'sandbox' || !process.env.MTN_SUBSCRIPTION_KEY || process.env.MTN_SUBSCRIPTION_KEY === '';

    return success(res, {
      reference:   payment.reference,
      externalRef: payment.externalRef,
      status:      'PROCESSING',
      phone:       cleanPhone,
      method,
      sandbox,
      message: sandbox
        ? `Sandbox mode: payment queued for +237${cleanPhone}. Tap confirm to complete.`
        : `USSD prompt sent to +237${cleanPhone}. Enter your PIN then tap confirm.`,
      breakdown: { gross, platformFee, insuranceFee, netAmount },
    }, 'Payment initiated', 201);

  } catch (err) {
    console.error('[initiatePayment]', err.message);
    return error(res, `Payment failed: ${err.message}`);
  }
};

// ─── CONFIRM ──────────────────────────────────────────────────────────────────
const confirmPayment = async (req, res) => {
  try {
    const { reference } = req.body;
    const userId = req.user.id;

    const payment = await prisma.payment.findUnique({
      where: { reference },
      include: {
        group: { include: { wallet: true, members: true } },
        user:  true,
      },
    });

    if (!payment)                       return error(res, 'Payment not found', 404);
    if (payment.userId !== userId)      return error(res, 'Unauthorized', 403);
    if (payment.status === 'SUCCESS')   return error(res, 'Already confirmed', 409);
    if (payment.status === 'FAILED')    return error(res, 'Payment failed. Please start a new payment.', 400);
    if (payment.status === 'CANCELLED') return error(res, 'Payment was cancelled.', 400);

    let gatewayResult;
    if (payment.method === 'MTN_MOMO') {
      gatewayResult = await mtn.confirmAndCheck(payment.externalRef);
    } else {
      gatewayResult = await orange.confirmAndCheck(payment.externalRef);
    }

    if (gatewayResult.status === 'PENDING') {
      return error(res, 'Payment not confirmed yet. Please try again.', 400);
    }

    if (gatewayResult.status === 'FAILED' || !gatewayResult.success) {
      await prisma.payment.update({ where: { id: payment.id }, data: { status: 'FAILED' } });
      return error(res, gatewayResult.message || 'Payment was rejected. Please try again.', 400);
    }

    const group = payment.group;

    await prisma.$transaction(async (tx) => {
      await tx.payment.update({
        where: { id: payment.id },
        data:  { status: 'SUCCESS', paidAt: new Date() },
      });

      await tx.transaction.create({
        data: {
          userId, groupId: payment.groupId,
          amount: payment.amount,
          type: 'CONTRIBUTION', status: 'SUCCESS',
          reference: uuidv4(),
          note: `Cycle ${payment.cycleNumber} — ${payment.method}`,
        },
      });

      if (group.wallet) {
        await tx.groupWallet.update({
          where: { groupId: payment.groupId },
          data: {
            potBalance:       { increment: payment.netAmount },
            insuranceBalance: { increment: payment.insuranceFee },
            totalCollected:   { increment: payment.amount },
          },
        });
      } else {
        await tx.groupWallet.create({
          data: {
            groupId:          payment.groupId,
            potBalance:       payment.netAmount,
            insuranceBalance: payment.insuranceFee,
            totalCollected:   payment.amount,
          },
        });
      }

      const user     = await tx.user.findUnique({ where: { id: userId } });
      const newScore = clamp(user.trustScore + TRUST_CHANGES.ON_TIME_PAYMENT);
      await tx.user.update({ where: { id: userId }, data: { trustScore: newScore } });
      await tx.trustScoreHistory.create({
        data: {
          userId, groupId: payment.groupId,
          change:      TRUST_CHANGES.ON_TIME_PAYMENT,
          reason:      'ON_TIME_PAYMENT',
          description: `On-time payment — Cycle ${payment.cycleNumber} of ${group.name}`,
          scoreBefore: user.trustScore,
          scoreAfter:  newScore,
        },
      });
    });

    const paidCount  = await prisma.payment.count({
      where: { groupId: payment.groupId, cycleNumber: group.currentCycle, status: 'SUCCESS' },
    });
    const totalCount = group.members.length;

    await notifyPaymentMade({
      groupId:   payment.groupId,
      payerName: payment.user.fullName,
      amount:    payment.amount,
      method:    payment.method,
      paidCount,
      totalCount,
    });

    let payoutResult = null;
    if (paidCount >= totalCount) {
      payoutResult = await _processCyclePayout(payment.groupId, group.currentCycle);
    }

    return success(res, {
      payment: { reference, status: 'SUCCESS', amount: payment.amount, paidAt: new Date() },
      progress: { paidCount, totalCount, allPaid: paidCount >= totalCount },
      payout: payoutResult,
    }, 'Payment confirmed successfully');

  } catch (err) {
    console.error('[confirmPayment]', err.message);
    return error(res, `Confirmation failed: ${err.message}`);
  }
};

// ─── CYCLE PAYOUT ─────────────────────────────────────────────────────────────
const _processCyclePayout = async (groupId, cycleNumber) => {
  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      wallet:  true,
      members: { orderBy: { payoutOrder: 'asc' }, include: { user: true } },
    },
  });

  const winnerMembership =
    group.members.find((m) => m.payoutOrder === cycleNumber) || group.members[0];
  const winner   = winnerMembership.user;
  const totalPot = group.wallet?.potBalance || 0;

  const breakdown       = getPayoutBreakdown(winner.trustScore);
  const nowAmount       = parseFloat((totalPot * breakdown.nowPercent / 100).toFixed(2));
  const heldAmount      = parseFloat((totalPot - nowAmount).toFixed(2));
  const releaseSchedule = buildReleaseSchedule(heldAmount, breakdown.releaseCycles, cycleNumber);

  await prisma.$transaction(async (tx) => {
    await tx.payout.create({
      data: { userId: winner.id, groupId, amount: nowAmount, status: 'PAID', scheduledAt: new Date(), paidAt: new Date() },
    });

    await tx.transaction.create({
      data: { userId: winner.id, groupId, amount: nowAmount, type: 'PAYOUT', status: 'SUCCESS', reference: uuidv4(), note: `Cycle ${cycleNumber} payout — ${breakdown.nowPercent}% (trust: ${winner.trustScore})` },
    });

    if (heldAmount > 0) {
      await tx.escrowTransaction.create({
        data: { userId: winner.id, groupId, totalHeld: heldAmount, remainingHeld: heldAmount, releaseSchedule, cycleWon: cycleNumber, trustScoreAtWin: winner.trustScore, winnerPayout: totalPot },
      });
    }

    await tx.groupWallet.update({ where: { groupId }, data: { potBalance: 0 } });
    await tx.group.update({ where: { id: groupId }, data: { currentCycle: { increment: 1 } } });

    const newScore = clamp(winner.trustScore + TRUST_CHANGES.CYCLE_COMPLETE);
    await tx.user.update({ where: { id: winner.id }, data: { trustScore: newScore } });
    await tx.trustScoreHistory.create({
      data: { userId: winner.id, groupId, change: TRUST_CHANGES.CYCLE_COMPLETE, reason: 'CYCLE_COMPLETE', description: `Completed cycle ${cycleNumber} of ${group.name}`, scoreBefore: winner.trustScore, scoreAfter: newScore },
    });
  });

  const nextMember = group.members.find((m) => m.payoutOrder === cycleNumber + 1);
  await notifyWinner({
    groupId,
    winnerName:      winner.fullName,
    totalPot,
    nowAmount,
    heldAmount,
    nextWinnerName:  nextMember?.user.fullName || 'TBD',
  });

  return {
    winner:         winner.fullName,
    totalPot,
    nowAmount,
    heldAmount,
    releaseSchedule,
    nextWinner:     nextMember?.user.fullName || 'TBD',
    trustScore:     winner.trustScore,
    payoutPercent:  breakdown.nowPercent,
  };
};

// ─── OTHER ENDPOINTS ──────────────────────────────────────────────────────────
const getPaymentStatus = async (req, res) => {
  try {
    const payment = await prisma.payment.findUnique({
      where: { reference: req.params.reference },
      include: { group: { select: { name: true } } },
    });
    if (!payment) return error(res, 'Not found', 404);
    if (payment.userId !== req.user.id) return error(res, 'Unauthorized', 403);
    return success(res, payment);
  } catch (err) { return error(res, 'Failed'); }
};

const getPaymentHistory = async (req, res) => {
  try {
    const { page = 1, limit = 20, groupId, status } = req.query;
    const skip  = (parseInt(page) - 1) * parseInt(limit);
    const where = { userId: req.user.id };
    if (groupId) where.groupId = groupId;
    if (status)  where.status  = status;
    const [payments, total] = await Promise.all([
      prisma.payment.findMany({ where, skip, take: parseInt(limit), include: { group: { select: { name: true } } }, orderBy: { createdAt: 'desc' } }),
      prisma.payment.count({ where }),
    ]);
    return success(res, { payments, pagination: { total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / parseInt(limit)) } });
  } catch (err) { return error(res, 'Failed'); }
};

const savePaymentMethod = async (req, res) => {
  try {
    const { method, phone, isDefault } = req.body;
    const cleanPhone = validateCameroonPhone(phone);
    if (!cleanPhone) return error(res, 'Invalid phone number', 400);
    if (isDefault) {
      await prisma.userPaymentMethod.updateMany({ where: { userId: req.user.id }, data: { isDefault: false } });
    }
    const saved = await prisma.userPaymentMethod.create({
      data: { userId: req.user.id, method, phone: cleanPhone, isDefault: isDefault ?? false },
    });
    return success(res, saved, 'Payment method saved', 201);
  } catch (err) { return error(res, 'Failed to save payment method'); }
};

const getPaymentMethods = async (req, res) => {
  try {
    const methods = await prisma.userPaymentMethod.findMany({
      where: { userId: req.user.id }, orderBy: { isDefault: 'desc' },
    });
    return success(res, methods);
  } catch (err) { return error(res, 'Failed'); }
};

const enableAutoPay = async (req, res) => {
  try {
    const { groupId, dayOfMonth, method, phone } = req.body;
    const cleanPhone = validateCameroonPhone(phone);
    if (!cleanPhone) return error(res, 'Invalid phone number', 400);
    if (dayOfMonth < 1 || dayOfMonth > 31) return error(res, 'Day must be between 1 and 31', 400);
    const membership = await prisma.groupMember.findUnique({ where: { userId_groupId: { userId: req.user.id, groupId } } });
    if (!membership) return error(res, 'Not a group member', 403);
    const setting = await prisma.autoPaySetting.upsert({
      where:  { userId_groupId: { userId: req.user.id, groupId } },
      update: { isEnabled: true, dayOfMonth, method, phone: cleanPhone },
      create: { userId: req.user.id, groupId, isEnabled: true, dayOfMonth, method, phone: cleanPhone },
    });
    return success(res, setting, 'Auto-Pay enabled');
  } catch (err) { return error(res, 'Failed to enable Auto-Pay'); }
};

const disableAutoPay = async (req, res) => {
  try {
    const { groupId } = req.body;
    await prisma.autoPaySetting.updateMany({ where: { userId: req.user.id, groupId }, data: { isEnabled: false } });
    return success(res, null, 'Auto-Pay disabled');
  } catch (err) { return error(res, 'Failed'); }
};

const generateQRCode = async (req, res) => {
  try {
    const { groupId } = req.body;
    const group = await prisma.group.findUnique({ where: { id: groupId }, include: { members: { where: { userId: req.user.id } } } });
    if (!group) return error(res, 'Group not found', 404);
    if (!group.members.length) return error(res, 'Not a group member', 403);
    const qrData = JSON.stringify({ app: 'njangipay', groupId: group.id, groupName: group.name, amount: group.contributionAmt, inviteCode: group.inviteCode });
    const qrCode = await prisma.qRCode.upsert({ where: { groupId }, update: { data: qrData }, create: { groupId, data: qrData } });
    return success(res, { qrData: qrCode.data, groupId });
  } catch (err) { return error(res, 'Failed to generate QR code'); }
};

const getQRCode = async (req, res) => {
  try {
    const qrCode = await prisma.qRCode.findUnique({ where: { groupId: req.params.groupId } });
    if (!qrCode) return error(res, 'QR code not found — generate one first', 404);
    return success(res, qrCode);
  } catch (err) { return error(res, 'Failed'); }
};

module.exports = {
  initiatePayment, confirmPayment, getPaymentStatus,
  getPaymentHistory, savePaymentMethod, getPaymentMethods,
  enableAutoPay, disableAutoPay, generateQRCode, getQRCode,
};
