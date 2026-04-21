const router = require('express').Router();
const { body } = require('express-validator');
const {
  makeContribution,
  getUserTransactions,
  getGroupTransactions,
  getSummary,
} = require('../controllers/transaction.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

router.get('/', getUserTransactions);
router.get('/summary', getSummary);
router.get('/group/:groupId', getGroupTransactions);

router.post(
  '/contribute',
  [
    body('groupId').notEmpty().withMessage('Group ID is required'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be positive'),
  ],
  validate,
  makeContribution
);

module.exports = router;
