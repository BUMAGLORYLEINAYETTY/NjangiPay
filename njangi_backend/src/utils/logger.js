const logPayment = (type, data) => {
  console.log(`[PAYMENT:${type}]`, JSON.stringify(data));
};

const logError = (type, error) => {
  console.error(`[ERROR:${type}]`, error.message || error);
};

module.exports = {
  logPayment,
  logError,
};
