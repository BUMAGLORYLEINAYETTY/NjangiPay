const { PrismaClient } = require('@prisma/client');
const { success, error } = require('../utils/response');
const { v4: uuidv4 } = require('uuid');

const prisma = new PrismaClient();

const schedulePayouts = async (req, res) => {
  try {
    const { groupId } = req.params;

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId } },
    });
    if (!membership || membership.role !== 'ADMIN') return error(res, 'Only admin can schedule payouts', 403);

    const group = await prisma.group.findUnique({
      where: { id: groupId },
      include: { members: { orderBy: { payoutOrder: 'asc' } } },
    });
    if (!group || group.status !== 'ACTIVE') return error(res, 'Group must be active', 400);

    const existingPayouts = await prisma.payout.count({ where: { groupId } });
    if (existingPayouts > 0) return error(res, 'Payouts already scheduled for this group', 409);

    const frequencyDays = { DAILY: 1, WEEKLY: 7, BIWEEKLY: 14, MONTHLY: 30 };
    const days = frequencyDays[group.frequency];
    const totalPayout = group.contributionAmt * group.members.length;

    const payoutsData = group.members.map((member, index) => {
      const scheduledAt = new Date(group.startDate);
      scheduledAt.setDate(scheduledAt.getDate() + days * index);
      return {
        userId: member.userId,
        groupId,
        amount: totalPayout,
        scheduledAt,
      };
    });

    await prisma.payout.createMany({ data: payoutsData });

    const payouts = await prisma.payout.findMany({
      where: { groupId },
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: { scheduledAt: 'asc' },
    });

    return success(res, payouts, 'Payouts scheduled successfully', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to schedule payouts');
  }
};

const getGroupPayouts = async (req, res) => {
  try {
    const { groupId } = req.params;

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId } },
    });
    if (!membership) return error(res, 'Access denied', 403);

    const payouts = await prisma.payout.findMany({
      where: { groupId },
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: { scheduledAt: 'asc' },
    });

    return success(res, payouts);
  } catch (err) {
    return error(res, 'Failed to fetch payouts');
  }
};

const markPayoutPaid = async (req, res) => {
  try {
    const { payoutId } = req.params;

    const payout = await prisma.payout.findUnique({
      where: { id: payoutId },
      include: { group: { include: { members: true } } },
    });
    if (!payout) return error(res, 'Payout not found', 404);

    const isAdmin = payout.group.members.some(
      (m) => m.userId === req.user.id && m.role === 'ADMIN'
    );
    if (!isAdmin) return error(res, 'Only admin can mark payouts', 403);

    const updatedPayout = await prisma.payout.update({
      where: { id: payoutId },
      data: { status: 'PAID', paidAt: new Date() },
    });

    await prisma.transaction.create({
      data: {
        userId: payout.userId,
        groupId: payout.groupId,
        amount: payout.amount,
        type: 'PAYOUT',
        status: 'SUCCESS',
        reference: uuidv4(),
        note: 'Njangi payout received',
      },
    });

    return success(res, updatedPayout, 'Payout marked as paid');
  } catch (err) {
    return error(res, 'Failed to update payout');
  }
};

const getMyPayouts = async (req, res) => {
  try {
    const payouts = await prisma.payout.findMany({
      where: { userId: req.user.id },
      include: { group: { select: { id: true, name: true, frequency: true } } },
      orderBy: { scheduledAt: 'asc' },
    });
    return success(res, payouts);
  } catch (err) {
    return error(res, 'Failed to fetch your payouts');
  }
};

module.exports = { schedulePayouts, getGroupPayouts, markPayoutPaid, getMyPayouts };
