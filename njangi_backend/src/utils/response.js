// Success response helper
const success = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

// Error response helper
const error = (res, message, statusCode = 400, details = null) => {
  const response = {
    success: false,
    message,
  };
  if (details) {
    response.details = details;
  }
  return res.status(statusCode).json(response);
};

module.exports = {
  success,
  error,
};
