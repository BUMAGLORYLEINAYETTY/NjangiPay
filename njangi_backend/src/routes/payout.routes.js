const router = require('express').Router();
const {
  schedulePayouts,
  getGroupPayouts,
  markPayoutPaid,
  getMyPayouts,
} = require('../controllers/payout.controller');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/mine', getMyPayouts);
router.get('/group/:groupId', getGroupPayouts);
router.post('/group/:groupId/schedule', schedulePayouts);
router.patch('/:payoutId/paid', markPayoutPaid);

module.exports = router;
