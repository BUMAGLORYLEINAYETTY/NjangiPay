const { PrismaClient } = require('@prisma/client');
const { success, error } = require('../utils/response');

const prisma = new PrismaClient();

// Generate a short 6-char uppercase invite code
const generateInviteCode = () => {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
};

const createGroup = async (req, res) => {
  try {
    const { name, description, contributionAmt, frequency, maxMembers, startDate } = req.body;

    let inviteCode;
    let exists = true;
    while (exists) {
      inviteCode = generateInviteCode();
      const found = await prisma.group.findUnique({ where: { inviteCode } });
      exists = !!found;
    }

    const group = await prisma.group.create({
      data: {
        name,
        description,
        contributionAmt: parseFloat(contributionAmt),
        frequency,
        maxMembers: parseInt(maxMembers),
        startDate: new Date(startDate),
        inviteCode,
        members: {
          create: { userId: req.user.id, role: 'ADMIN', payoutOrder: 1 },
        },
      },
      include: {
        members: {
          include: { user: { select: { id: true, fullName: true, email: true } } },
        },
      },
    });

    return success(res, group, 'Group created successfully', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to create group');
  }
};

const getAllGroups = async (req, res) => {
  try {
    const groups = await prisma.group.findMany({
      where: { members: { some: { userId: req.user.id } } },
      include: {
        _count: { select: { members: true } },
        members: {
          where: { userId: req.user.id },
          select: { role: true, payoutOrder: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return success(res, groups);
  } catch (err) {
    return error(res, 'Failed to fetch groups');
  }
};

const getGroupById = async (req, res) => {
  try {
    const { id } = req.params;

    const group = await prisma.group.findUnique({
      where: { id },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, fullName: true, email: true, phone: true, trustScore: true },
            },
          },
          orderBy: { payoutOrder: 'asc' },
        },
        transactions: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          include: { user: { select: { id: true, fullName: true } } },
        },
        payouts: {
          orderBy: { scheduledAt: 'asc' },
          include: { user: { select: { id: true, fullName: true } } },
        },
        _count: { select: { members: true, transactions: true } },
      },
    });

    if (!group) return error(res, 'Group not found', 404);

    const isMember = group.members.some((m) => m.userId === req.user.id);
    if (!isMember) return error(res, 'Access denied', 403);

    // Calculate escrow: sum of all successful contributions
    const escrow = await prisma.transaction.aggregate({
      where: { groupId: id, type: 'CONTRIBUTION', status: 'SUCCESS' },
      _sum: { amount: true },
    });

    // Calculate how much current user has contributed
    const myContributions = await prisma.transaction.aggregate({
      where: { groupId: id, userId: req.user.id, type: 'CONTRIBUTION', status: 'SUCCESS' },
      _sum: { amount: true },
    });

    return success(res, {
      ...group,
      escrowBalance: escrow._sum.amount || 0,
      myContributions: myContributions._sum.amount || 0,
    });
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to fetch group');
  }
};

const joinByInviteCode = async (req, res) => {
  try {
    const { inviteCode } = req.body;

    const group = await prisma.group.findUnique({
      where: { inviteCode: inviteCode.toUpperCase() },
      include: { _count: { select: { members: true } } },
    });

    if (!group) return error(res, 'Invalid invite code', 404);
    if (group.status === 'CANCELLED') return error(res, 'This group has been cancelled', 400);
    if (group.status === 'COMPLETED') return error(res, 'This group has already completed', 400);
    if (group._count.members >= group.maxMembers) return error(res, 'Group is full', 400);

    const existing = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId: group.id } },
    });
    if (existing) return error(res, 'You are already a member of this group', 409);

    const member = await prisma.groupMember.create({
      data: {
        userId: req.user.id,
        groupId: group.id,
        role: 'MEMBER',
        payoutOrder: group._count.members + 1,
      },
    });

    return success(res, { group, member }, 'Joined group successfully', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Failed to join group');
  }
};

const joinGroup = async (req, res) => {
  try {
    const { id } = req.params;

    const group = await prisma.group.findUnique({
      where: { id },
      include: { _count: { select: { members: true } } },
    });

    if (!group) return error(res, 'Group not found', 404);
    if (group.status !== 'PENDING' && group.status !== 'ACTIVE')
      return error(res, 'Group is not accepting members', 400);
    if (group._count.members >= group.maxMembers) return error(res, 'Group is full', 400);

    const existing = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId: id } },
    });
    if (existing) return error(res, 'Already a member', 409);

    const member = await prisma.groupMember.create({
      data: {
        userId: req.user.id,
        groupId: id,
        role: 'MEMBER',
        payoutOrder: group._count.members + 1,
      },
    });

    return success(res, member, 'Joined group successfully', 201);
  } catch (err) {
    return error(res, 'Failed to join group');
  }
};

const activateGroup = async (req, res) => {
  try {
    const { id } = req.params;

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId: id } },
    });
    if (!membership || membership.role !== 'ADMIN')
      return error(res, 'Only admin can activate the group', 403);

    const group = await prisma.group.update({
      where: { id },
      data: { status: 'ACTIVE' },
    });

    return success(res, group, 'Group activated');
  } catch (err) {
    return error(res, 'Failed to activate group');
  }
};

const deleteGroup = async (req, res) => {
  try {
    const { id } = req.params;

    const membership = await prisma.groupMember.findUnique({
      where: { userId_groupId: { userId: req.user.id, groupId: id } },
    });
    if (!membership || membership.role !== 'ADMIN')
      return error(res, 'Only admin can cancel the group', 403);

    await prisma.group.update({ where: { id }, data: { status: 'CANCELLED' } });

    return success(res, null, 'Group cancelled');
  } catch (err) {
    return error(res, 'Failed to cancel group');
  }
};

module.exports = {
  createGroup,
  getAllGroups,
  getGroupById,
  joinByInviteCode,
  joinGroup,
  activateGroup,
  deleteGroup,
};
