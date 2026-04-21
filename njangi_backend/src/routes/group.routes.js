const router = require('express').Router();
const { body } = require('express-validator');
const {
  createGroup,
  getAllGroups,
  getGroupById,
  joinByInviteCode,
  joinGroup,
  activateGroup,
  deleteGroup,
} = require('../controllers/group.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

router.get('/', getAllGroups);

router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Group name is required'),
    body('contributionAmt').isFloat({ gt: 0 }).withMessage('Contribution amount must be positive'),
    body('frequency').isIn(['DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY']).withMessage('Invalid frequency'),
    body('maxMembers').isInt({ min: 2, max: 50 }).withMessage('Max members must be between 2 and 50'),
    body('startDate').isISO8601().withMessage('Valid start date required'),
  ],
  validate,
  createGroup
);

router.post(
  '/join-by-code',
  [body('inviteCode').trim().notEmpty().withMessage('Invite code is required')],
  validate,
  joinByInviteCode
);

router.get('/:id', getGroupById);
router.post('/:id/join', joinGroup);
router.patch('/:id/activate', activateGroup);
router.delete('/:id', deleteGroup);

module.exports = router;
