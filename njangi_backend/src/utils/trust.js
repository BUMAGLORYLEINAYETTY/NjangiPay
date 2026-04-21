// Trust score changes
const TRUST_CHANGES = {
  ON_TIME_PAYMENT: 2,
  LATE_PAYMENT_1_3_DAYS: -10,
  LATE_PAYMENT_4_7_DAYS: -20,
  MISSED_PAYMENT: -30,
  COMPLETE_CYCLE: 5,
  REFER_RELIABLE_MEMBER: 10,
  DEFAULT: -50,
  REPORTED_BY_GROUP: -25,
  BONUS_5_ON_TIME: 15,
  REFERRAL_JOIN: 3,
};

// Clamp value between min and max
const clamp = (value, min, max) => {
  return Math.min(Math.max(value, min), max);
};

// Get payout breakdown based on trust score
const getPayoutBreakdown = (trustScore, totalPot) => {
  let nowPercentage, heldPercentage, releaseCycles;
  
  if (trustScore >= 100) {
    nowPercentage = 100;
    heldPercentage = 0;
    releaseCycles = 0;
  } else if (trustScore >= 90) {
    nowPercentage = 90;
    heldPercentage = 10;
    releaseCycles = 1;
  } else if (trustScore >= 80) {
    nowPercentage = 80;
    heldPercentage = 20;
    releaseCycles = 1;
  } else if (trustScore >= 70) {
    nowPercentage = 70;
    heldPercentage = 30;
    releaseCycles = 2;
  } else if (trustScore >= 60) {
    nowPercentage = 60;
    heldPercentage = 40;
    releaseCycles = 2;
  } else {
    nowPercentage = 50;
    heldPercentage = 50;
    releaseCycles = 3;
  }
  
  return {
    now: (totalPot * nowPercentage) / 100,
    held: (totalPot * heldPercentage) / 100,
    nowPercentage,
    heldPercentage,
    releaseCycles,
  };
};

// Build release schedule for held money
const buildReleaseSchedule = (heldAmount, releaseCycles, currentCycle) => {
  const schedule = [];
  const perRelease = heldAmount / releaseCycles;
  
  for (let i = 1; i <= releaseCycles; i++) {
    schedule.push({
      cycleNumber: currentCycle + i,
      amount: perRelease,
      releaseDate: null, // Will be set when cycle completes
    });
  }
  
  return schedule;
};

module.exports = {
  TRUST_CHANGES,
  clamp,
  getPayoutBreakdown,
  buildReleaseSchedule,
};
