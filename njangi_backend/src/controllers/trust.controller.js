const { PrismaClient } = require('@prisma/client');
const { success, error } = require('../utils/response');
const { getPayoutBreakdown } = require('../utils/trust');

const prisma = new PrismaClient();

const getTrustScore = async (req, res) => {
  try {
    const userId = req.user.id;

    const [user, history] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { trustScore: true, fullName: true },
      }),
      prisma.trustScoreHistory.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    ]);

    const breakdown = getPayoutBreakdown(user.trustScore);

    // Calculate next tier target
    const tiers = [60, 70, 80, 90, 100];
    const nextTier = tiers.find((t) => t > user.trustScore) || 100;
    const pointsToNextTier = nextTier - user.trustScore;

    return success(res, {
      currentScore: user.trustScore,
      payoutBreakdown: breakdown,
      nextTier,
      pointsToNextTier,
      history,
      improvements: [
        { action: 'Pay on time each cycle', points: '+2 per payment' },
        { action: 'Complete a full cycle', points: '+5' },
        { action: '5 on-time payments in a row', points: '+15 bonus' },
        { action: 'Invite a friend who joins', points: '+3' },
        { action: 'Refer a reliable member', points: '+10' },
      ],
      warnings: [
        { action: 'Late payment (1-3 days)', points: '-10' },
        { action: 'Late payment (4-7 days)', points: '-20' },
        { action: 'Missed payment', points: '-30' },
        { action: 'Default (disappear)', points: '-50' },
        { action: 'Reported by members', points: '-25' },
      ],
    });
  } catch (err) {
    return error(res, 'Failed to fetch trust score');
  }
};

const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 30, unreadOnly } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const where = { userId: req.user.id };
    if (unreadOnly === 'true') where.isRead = false;

    const [notifications, total, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where, skip, take: parseInt(limit),
        orderBy: { sentAt: 'desc' },
      }),
      prisma.notification.count({ where }),
      prisma.notification.count({ where: { userId: req.user.id, isRead: false } }),
    ]);

    return success(res, { notifications, total, unreadCount });
  } catch (err) {
    return error(res, 'Failed to fetch notifications');
  }
};

const markNotificationsRead = async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });
    return success(res, null, 'Notifications marked as read');
  } catch (err) {
    return error(res, 'Failed to update notifications');
  }
};

module.exports = { getTrustScore, getNotifications, markNotificationsRead };
