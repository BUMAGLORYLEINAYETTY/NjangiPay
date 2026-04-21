const isValidAmount = (amount) => {
  const num = parseFloat(amount);
  return !isNaN(num) && num >= 100 && num <= 1000000;
};

const isValidGroupCode = (code) => {
  const regex = /^[A-Z0-9]{6}$/;
  return regex.test(code);
};

module.exports = {
  isValidAmount,
  isValidGroupCode,
};
