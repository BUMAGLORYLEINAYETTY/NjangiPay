const { v4: uuidv4 } = require('uuid');

const isSandbox = () =>
  process.env.NODE_ENV === 'sandbox' ||
  !process.env.ORANGE_CLIENT_ID ||
  process.env.ORANGE_CLIENT_ID === '';

const isConfigured = () =>
  !!(process.env.ORANGE_CLIENT_ID && process.env.ORANGE_CLIENT_SECRET && process.env.ORANGE_MERCHANT_KEY);

const sandboxPayments = new Map();

const requestPayment = async ({ amount, phone, reference, groupName }) => {
  const externalId = reference || uuidv4();

  if (isSandbox()) {
    sandboxPayments.set(externalId, {
      status: 'PENDING',
      phone, amount, groupName,
      createdAt: Date.now(),
    });
    console.log(`[SANDBOX Orange] Payment stored: +237${phone} | ${amount} XAF | ref=${externalId}`);
    return { success: true, externalId };
  }

  return { success: false, message: 'Orange Money not configured. Add credentials to .env' };
};

const confirmAndCheck = async (externalId) => {
  if (isSandbox()) {
    const record = sandboxPayments.get(externalId);
    if (!record) return { success: false, status: 'FAILED', message: 'Payment not found' };

    const ageMinutes = (Date.now() - record.createdAt) / 1000 / 60;
    if (ageMinutes > 10) {
      return { success: false, status: 'FAILED', message: 'Payment expired. Please start again.' };
    }

    sandboxPayments.set(externalId, { ...record, status: 'SUCCESSFUL' });
    console.log(`[SANDBOX Orange] Payment confirmed: ${externalId}`);
    return { success: true, status: 'SUCCESSFUL', transactionId: `ORANGE_SANDBOX_${Date.now()}` };
  }

  return { success: false, status: 'FAILED', message: 'Orange Money not configured' };
};

module.exports = { requestPayment, confirmAndCheck, isConfigured, isSandbox };
