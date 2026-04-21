// Send notification to all group members when payment is made
const notifyPaymentMade = async (groupId, memberName, amount, method) => {
  // This will be implemented with actual SMS/WhatsApp/FCM
  console.log(`[NOTIFICATION] ${memberName} paid ${amount} via ${method} to group ${groupId}`);
  return true;
};

// Send notification when winner is selected
const notifyWinner = async (groupId, winnerName, amount, nowAmount, heldAmount) => {
  console.log(`[NOTIFICATION] ${winnerName} won ${amount} in group ${groupId}. Now: ${nowAmount}, Held: ${heldAmount}`);
  return true;
};

// Generic notification sender
const sendNotification = async (userId, type, data) => {
  console.log(`[NOTIFICATION] To user ${userId}: ${type}`, data);
  return true;
};

module.exports = {
  notifyPaymentMade,
  notifyWinner,
  sendNotification,
};
