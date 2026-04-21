const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');
const { success, error } = require('../utils/response');
const { sendNotification } = require('../services/notification.service');

const prisma = new PrismaClient();

const getEscrowBalance = async (req, res) => {
  try {
    const userId = req.user.id;

    const escrows = await prisma.escrowTransaction.findMany({
      where: { userId, status: 'ACTIVE' },
      include: { group: { select: { id: true, name: true, currentCycle: true } } },
      orderBy: { createdAt: 'desc' },
    });

    const total = escrows.reduce((sum, e) => sum + e.remainingHeld, 0);

    return success(res, { totalHeld: total, escrows });
  } catch (err) {
    return error(res, 'Failed to fetch escrow balance');
  }
};

// Release escrow for a user when they pay on time in a cycle
const checkAndReleaseEscrow = async (userId, groupId, cycleNumber) => {
  const activeEscrows = await prisma.escrowTransaction.findMany({
    where: { userId, groupId, status: 'ACTIVE' },
  });

  for (const escrow of activeEscrows) {
    const schedule = escrow.releaseSchedule;
    const dueNow = schedule.find((s) => s.cycleNumber === cycleNumber && !s.released);

    if (dueNow) {
      const updatedSchedule = schedule.map((s) =>
        s.cycleNumber === cycleNumber ? { ...s, released: true } : s
      );

      const newRemaining = parseFloat((escrow.remainingHeld - dueNow.amount).toFixed(2));
      const allReleased = updatedSchedule.every((s) => s.released);

      await prisma.$transaction(async (tx) => {
        await tx.escrowTransaction.update({
          where: { id: escrow.id },
          data: {
            releaseSchedule: updatedSchedule,
            amountReleased: { increment: dueNow.amount },
            remainingHeld: newRemaining,
            status: allReleased ? 'FULLY_RELEASED' : 'ACTIVE',
          },
        });

        await tx.escrowRelease.create({
          data: { escrowId: escrow.id, amount: dueNow.amount, cycleNumber, isEarly: false },
        });

        await tx.transaction.create({
          data: {
            userId, groupId, amount: dueNow.amount,
            type: 'ESCROW_RELEASE', status: 'SUCCESS',
            reference: uuidv4(),
            note: `Escrow release — Cycle ${cycleNumber}`,
          },
        });
      });

      await sendNotification({
        userId, groupId,
        type: 'ESCROW_RELEASE',
        channel: 'IN_APP',
        title: '💸 Escrow Released!',
        body: `${new Intl.NumberFormat('fr-CM').format(dueNow.amount)} FCFA has been released from escrow to your account.`,
        data: { amount: dueNow.amount, cycleNumber },
      });
    }
  }
};

const requestEarlyRelease = async (req, res) => {
  try {
    const { escrowId } = req.body;
    const userId = req.user.id;

    const escrow = await prisma.escrowTransaction.findUnique({
      where: { id: escrowId },
      include: { group: { include: { members: true } } },
    });

    if (!escrow) return error(res, 'Escrow not found', 404);
    if (escrow.userId !== userId) return error(res, 'Unauthorized', 403);
    if (escrow.status !== 'ACTIVE') return error(res, 'Escrow is not active', 400);
    if (escrow.remainingHeld <= 0) return error(res, 'No funds held in escrow', 400);

    // Check lifetime limit of 2 early releases
    const previousEarlyReleases = await prisma.escrowRelease.count({
      where: { escrow: { userId }, isEarly: true },
    });
    if (previousEarlyReleases >= 2) {
      return error(res, 'Maximum 2 early releases per lifetime reached', 400);
    }

    const fee = parseFloat((escrow.remainingHeld * 0.05).toFixed(2));
    const netRelease = parseFloat((escrow.remainingHeld - fee).toFixed(2));

    // TODO: In production, create a group vote record and require 60% approval.
    // For now, auto-approve and process.
    await prisma.$transaction(async (tx) => {
      await tx.escrowTransaction.update({
        where: { id: escrowId },
        data: { status: 'EARLY_RELEASED', remainingHeld: 0, amountReleased: escrow.totalHeld },
      });

      await tx.escrowRelease.create({
        data: { escrowId, amount: netRelease, cycleNumber: escrow.cycleWon, isEarly: true, fee },
      });

      // Fee goes to insurance fund
      await tx.groupWallet.update({
        where: { groupId: escrow.groupId },
        data: { insuranceBalance: { increment: fee } },
      });

      await tx.transaction.create({
        data: {
          userId, groupId: escrow.groupId, amount: netRelease,
          type: 'ESCROW_RELEASE', status: 'SUCCESS',
          reference: uuidv4(),
          note: `Early escrow release (5% fee: ${fee} FCFA)`,
        },
      });
    });

    return success(res, {
      released: netRelease,
      fee,
      message: `${new Intl.NumberFormat('fr-CM').format(netRelease)} FCFA released. Fee of ${new Intl.NumberFormat('fr-CM').format(fee)} FCFA added to group insurance.`,
    }, 'Early release processed');
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to process early release');
  }
};

module.exports = { getEscrowBalance, checkAndReleaseEscrow, requestEarlyRelease };
