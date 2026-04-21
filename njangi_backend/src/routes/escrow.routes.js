const router = require('express').Router();
const { body } = require('express-validator');
const { getEscrowBalance, requestEarlyRelease } = require('../controllers/escrow.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

router.get('/balance', getEscrowBalance);

router.post(
  '/release-request',
  [body('escrowId').notEmpty().withMessage('Escrow ID required')],
  validate,
  requestEarlyRelease
);

module.exports = router;
