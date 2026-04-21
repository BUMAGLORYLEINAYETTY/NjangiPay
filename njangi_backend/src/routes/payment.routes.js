const router = require('express').Router();
const { body } = require('express-validator');
const {
  initiatePayment, confirmPayment, getPaymentStatus,
  getPaymentHistory, savePaymentMethod, getPaymentMethods,
  enableAutoPay, disableAutoPay, generateQRCode, getQRCode,
} = require('../controllers/payment.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

router.post(
  '/initiate',
  [
    body('groupId').notEmpty().withMessage('Group ID required'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be positive'),
    body('method').isIn(['MTN_MOMO', 'ORANGE_MONEY']).withMessage('Invalid payment method'),
    body('phone').notEmpty().withMessage('Phone number required'),
  ],
  validate,
  initiatePayment
);

router.post(
  '/confirm',
  [body('reference').notEmpty().withMessage('Reference required')],
  validate,
  confirmPayment
);

router.get('/status/:reference', getPaymentStatus);
router.get('/history', getPaymentHistory);
router.get('/methods', getPaymentMethods);

router.post(
  '/methods',
  [
    body('method').isIn(['MTN_MOMO', 'ORANGE_MONEY']).withMessage('Invalid method'),
    body('phone').notEmpty().withMessage('Phone required'),
  ],
  validate,
  savePaymentMethod
);

router.post(
  '/auto-pay/enable',
  [
    body('groupId').notEmpty(),
    body('dayOfMonth').isInt({ min: 1, max: 31 }),
    body('method').isIn(['MTN_MOMO', 'ORANGE_MONEY']),
    body('phone').notEmpty(),
  ],
  validate,
  enableAutoPay
);

router.post('/auto-pay/disable', [body('groupId').notEmpty()], validate, disableAutoPay);

router.post('/qr/generate', [body('groupId').notEmpty()], validate, generateQRCode);
router.get('/qr/:groupId', getQRCode);

module.exports = router;
