/**
 * Cameroon phone number validation and operator detection
 * Format: 6XXXXXXXX (9 digits starting with 6)
 */

// Validate and clean Cameroon phone number
const validateCameroonPhone = (phone) => {
  if (!phone) return null;
  let cleaned = phone.toString().replace(/\D/g, '');
  
  // Remove country code if present
  if (cleaned.startsWith('237')) {
    cleaned = cleaned.substring(3);
  }
  
  // Check if it's a valid Cameroon number (9 digits starting with 6)
  const regex = /^[6][0-9]{8}$/;
  if (regex.test(cleaned)) {
    return cleaned;
  }
  return null;
};

// Detect mobile money operator from phone number
const detectOperator = (phone) => {
  if (!phone) return 'UNKNOWN';
  const cleaned = phone.toString().replace(/\D/g, '');
  
  // Get first 3 digits (prefix)
  const prefix = parseInt(cleaned.substring(0, 3));
  
  // MTN Cameroon prefixes
  const mtnPrefixes = [
    650, 651, 652, 653, 654, 655, 656, 657, 658, 659,  // 65x range (mostly MTN)
    670, 671, 672, 673, 674, 675, 676, 677, 678, 679,  // 67x range (MTN)
    680, 681, 682, 683, 684, 685, 686, 687, 688, 689,  // 68x range (MTN)
  ];
  
  // Orange Cameroon prefixes
  const orangePrefixes = [
    660, 661, 662, 663, 664, 665, 666, 667, 668, 669,  // 66x range (Orange)
    690, 691, 692, 693, 694, 695, 696, 697, 698, 699,  // 69x range (Orange)
  ];
  
  if (mtnPrefixes.includes(prefix)) {
    return 'MTN_MOMO';
  }
  if (orangePrefixes.includes(prefix)) {
    return 'ORANGE_MONEY';
  }
  
  // Fallback: check second digit
  const secondDigit = cleaned.substring(1, 2);
  if (secondDigit === '7') return 'MTN_MOMO';  // 67x, 68x are MTN
  if (secondDigit === '6' || secondDigit === '9') return 'ORANGE_MONEY';  // 66x, 69x are Orange
  
  return 'UNKNOWN';
};

// Format phone for display
const formatPhoneForDisplay = (phone) => {
  const cleaned = validateCameroonPhone(phone);
  if (cleaned) {
    return `${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)}`;
  }
  return phone;
};

// Format phone for API calls (adds country code)
const formatPhoneForAPI = (phone) => {
  const cleaned = validateCameroonPhone(phone);
  if (cleaned) {
    return '237' + cleaned;
  }
  return null;
};

module.exports = {
  validateCameroonPhone,
  detectOperator,
  formatPhoneForDisplay,
  formatPhoneForAPI,
};
