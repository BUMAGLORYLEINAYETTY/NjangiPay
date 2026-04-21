const { PrismaClient } = require('@prisma/client');
const { success, error } = require('../utils/response');
const { v4: uuidv4 } = require('uuid');

const prisma = new PrismaClient();

const makeContribution = async (req, res) => {
  try {
    const { groupId, amount, note } = req.body;

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId } },
    });
    if (!membership) return error(res, 'You are not a member of this group', 403);

    const group = await prisma.group.findUnique({ where: { id: groupId } });
    if (!group || group.status !== 'ACTIVE') return error(res, 'Group is not active', 400);

    if (parseFloat(amount) !== group.contributionAmt) {
      return error(res, `Contribution must be exactly XAF ${group.contributionAmt}`, 400);
    }

    const transaction = await prisma.transaction.create({
      data: {
        userId: req.user.id,
        groupId,
        amount: parseFloat(amount),
        type: 'CONTRIBUTION',
        status: 'SUCCESS',
        reference: uuidv4(),
        note,
      },
      include: {
        user: { select: { id: true, fullName: true } },
        group: { select: { id: true, name: true } },
      },
    });

    return success(res, transaction, 'Contribution recorded successfully', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to record contribution');
  }
};

const getUserTransactions = async (req, res) => {
  try {
    const { page = 1, limit = 20, type, status } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = { userId: req.user.id };
    if (type) where.type = type;
    if (status) where.status = status;

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where,
        include: { group: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.transaction.count({ where }),
    ]);

    return success(res, {
      transactions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (err) {
    return error(res, 'Failed to fetch transactions');
  }
};

const getGroupTransactions = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId } },
    });
    if (!membership) return error(res, 'Access denied', 403);

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where: { groupId },
        include: { user: { select: { id: true, fullName: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.transaction.count({ where: { groupId } }),
    ]);

    return success(res, {
      transactions,
      pagination: { total, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / parseInt(limit)) },
    });
  } catch (err) {
    return error(res, 'Failed to fetch group transactions');
  }
};

const getSummary = async (req, res) => {
  try {
    const userId = req.user.id;

    const [totalContributed, totalReceived, activeGroups, recentTransactions] = await Promise.all([
      prisma.transaction.aggregate({
        where: { userId, type: 'CONTRIBUTION', status: 'SUCCESS' },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId, type: 'PAYOUT', status: 'SUCCESS' },
        _sum: { amount: true },
      }),
      prisma.groupMember.count({
        where: { userId, group: { status: 'ACTIVE' } },
      }),
      prisma.transaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: { group: { select: { id: true, name: true } } },
      }),
    ]);

    return success(res, {
      totalContributed: totalContributed._sum.amount || 0,
      totalReceived: totalReceived._sum.amount || 0,
      activeGroups,
      recentTransactions,
    });
  } catch (err) {
    return error(res, 'Failed to fetch summary');
  }
};

module.exports = { makeContribution, getUserTransactions, getGroupTransactions, getSummary };
