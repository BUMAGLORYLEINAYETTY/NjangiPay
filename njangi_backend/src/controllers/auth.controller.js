const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const { generateToken } = require('../utils/jwt');
const { success, error } = require('../utils/response');

const prisma = new PrismaClient();

const register = async (req, res) => {
  try {
    const { fullName, email, phone, password } = req.body;

    const existingUser = await prisma.user.findFirst({
      where: { OR: [{ email }, { phone }] },
    });
    if (existingUser) {
      return error(res, 'Email or phone already registered', 409);
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: { fullName, email, phone, passwordHash },
      select: { id: true, fullName: true, email: true, phone: true, trustScore: true, createdAt: true },
    });

    const token = generateToken({ userId: user.id });

    return success(res, { user, token }, 'Account created successfully', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Registration failed');
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return error(res, 'Invalid email or password', 401);

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return error(res, 'Invalid email or password', 401);

    const token = generateToken({ userId: user.id });

    const { passwordHash, ...safeUser } = user;

    return success(res, { user: safeUser, token }, 'Login successful');
  } catch (err) {
    console.error(err);
    return error(res, 'Login failed');
  }
};

const getMe = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        trustScore: true,
        isVerified: true,
        createdAt: true,
        _count: { select: { memberships: true, transactions: true } },
      },
    });
    return success(res, user);
  } catch (err) {
    return error(res, 'Failed to fetch profile');
  }
};

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isMatch) return error(res, 'Current password is incorrect', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({ where: { id: req.user.id }, data: { passwordHash } });

    return success(res, null, 'Password changed successfully');
  } catch (err) {
    return error(res, 'Failed to change password');
  }
};

module.exports = { register, login, getMe, changePassword };
