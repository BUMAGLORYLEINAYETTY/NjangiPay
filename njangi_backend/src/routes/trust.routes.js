const router = require('express').Router();
const { getTrustScore, getNotifications, markNotificationsRead } = require('../controllers/trust.controller');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/score', getTrustScore);
router.get('/notifications', getNotifications);
router.post('/notifications/read', markNotificationsRead);

module.exports = router;
