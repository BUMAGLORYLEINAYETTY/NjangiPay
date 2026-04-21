const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

const authRoutes        = require('./routes/auth.routes');
const groupRoutes       = require('./routes/group.routes');
const transactionRoutes = require('./routes/transaction.routes');
const payoutRoutes      = require('./routes/payout.routes');
const paymentRoutes     = require('./routes/payment.routes');
const escrowRoutes      = require('./routes/escrow.routes');
const trustRoutes       = require('./routes/trust.routes');

const app = express();

// Allow Chrome on localhost AND Android on local network
app.use(cors({
  origin: (origin, callback) => {
    const allowed = [
      'http://localhost:3000',
      'http://localhost:63452',
      'http://localhost:63453',
      'http://localhost:63454',
      'http://localhost:63455',
      'http://127.0.0.1:3000',
    ];
    // Allow any localhost port (Flutter web uses random ports)
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    // Allow Android devices on local network (192.168.x.x, 10.x.x.x)
    if (origin.match(/^http:\/\/(192\.168\.|10\.|172\.)/)) {
      return callback(null, true);
    }
    callback(null, true); // allow all in development
  },
  credentials:    true,
  allowedHeaders: ['Content-Type', 'Authorization'],
  methods:        ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
}));

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status:    'OK',
    app:       'NjangiPay API',
    mode:      process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
  });
});

// Routes
app.use('/api/auth',         authRoutes);
app.use('/api/groups',       groupRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/payouts',      payoutRoutes);
app.use('/api/payments',     paymentRoutes);
app.use('/api/escrow',       escrowRoutes);
app.use('/api/trust',        trustRoutes);

// Test MTN credentials
app.get('/api/payments/test-mtn', async (req, res) => {
  const mtn = require('./services/mtn.service');
  const result = await mtn.testCredentials();
  res.json(result);
});

// 404
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

module.exports = app;
