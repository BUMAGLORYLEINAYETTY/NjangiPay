const { v4: uuidv4 } = require('uuid');

const isSandbox = () =>
  process.env.NODE_ENV === 'sandbox' ||
  !process.env.MTN_SUBSCRIPTION_KEY ||
  process.env.MTN_SUBSCRIPTION_KEY === '';

// In-memory store: reference → payment record
const sandboxStore = new Map();

const requestPayment = async ({ amount, phone, reference, groupName }) => {
  const externalId = reference || uuidv4();

  if (isSandbox()) {
    sandboxStore.set(externalId, {
      status:    'PENDING',
      phone,
      amount,
      groupName,
      createdAt: Date.now(),
      pinEntered: false,
    });
    console.log(`[MTN Sandbox] ▶ Payment queued`);
    console.log(`              Phone  : +237${phone}`);
    console.log(`              Amount : ${amount} XAF`);
    console.log(`              Group  : ${groupName}`);
    console.log(`              Ref    : ${externalId}`);
    return { success: true, externalId };
  }

  // Real MTN API
  try {
    const axios = require('axios');
    const token = await _getToken();
    await axios.post(
      `${process.env.MTN_BASE_URL}/collection/v1_0/requesttopay`,
      {
        amount:      String(amount),
        currency:    process.env.MTN_CURRENCY || 'XAF',
        externalId,
        payer:       { partyIdType: 'MSISDN', partyId: `237${phone}` },
        payerMessage: `NjangiPay - ${groupName}`,
        payeeNote:   'Group savings contribution',
      },
      {
        headers: {
          'Authorization':             `Bearer ${token}`,
          'X-Reference-Id':            externalId,
          'X-Target-Environment':      process.env.MTN_TARGET_ENV || 'sandbox',
          'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
          'Content-Type':              'application/json',
        },
      }
    );
    return { success: true, externalId };
  } catch (err) {
    const msg = err.response?.data?.message || err.message;
    console.error('[MTN] requestPayment error:', msg);
    return { success: false, message: msg };
  }
};

// Called when user taps confirm after PIN
const confirmAndCheck = async (externalId) => {
  if (isSandbox()) {
    const record = sandboxStore.get(externalId);
    if (!record) {
      return { success: false, status: 'FAILED', message: 'Payment session expired. Please start again.' };
    }
    // Expire after 10 minutes
    if ((Date.now() - record.createdAt) > 10 * 60 * 1000) {
      sandboxStore.delete(externalId);
      return { success: false, status: 'FAILED', message: 'Payment timed out. Please start again.' };
    }
    sandboxStore.set(externalId, { ...record, status: 'SUCCESSFUL', pinEntered: true });
    console.log(`[MTN Sandbox] ✅ Payment confirmed: ${externalId}`);
    return {
      success:       true,
      status:        'SUCCESSFUL',
      transactionId: `MTN${Date.now()}`,
    };
  }

  // Real MTN status check
  try {
    const axios = require('axios');
    const token = await _getToken();
    const res = await axios.get(
      `${process.env.MTN_BASE_URL}/collection/v1_0/requesttopay/${externalId}`,
      {
        headers: {
          'Authorization':             `Bearer ${token}`,
          'X-Target-Environment':      process.env.MTN_TARGET_ENV || 'sandbox',
          'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY,
        },
      }
    );
    return {
      success:       res.data.status === 'SUCCESSFUL',
      status:        res.data.status,
      transactionId: res.data.financialTransactionId,
    };
  } catch (err) {
    return { success: false, status: 'FAILED', message: err.message };
  }
};

const testCredentials = async () => {
  if (isSandbox()) return { valid: true, mode: 'sandbox' };
  try { await _getToken(); return { valid: true, mode: 'production' }; }
  catch (err) { return { valid: false, message: err.message }; }
};

const _getToken = async () => {
  const axios = require('axios');
  const creds = Buffer.from(`${process.env.MTN_API_USER}:${process.env.MTN_API_KEY}`).toString('base64');
  const res = await axios.post(
    `${process.env.MTN_BASE_URL}/collection/token/`,
    {},
    { headers: { 'Authorization': `Basic ${creds}`, 'Ocp-Apim-Subscription-Key': process.env.MTN_SUBSCRIPTION_KEY } }
  );
  return res.data.access_token;
};

module.exports = { requestPayment, confirmAndCheck, testCredentials };
