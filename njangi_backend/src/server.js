require('dotenv').config();
const app = require('./app');
const { PrismaClient } = require('@prisma/client');
const os = require('os');

const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

async function main() {
  try {
    await prisma.$connect();
    console.log('✅ Database connected');

    app.listen(PORT, '0.0.0.0', () => {
      const localIP = getLocalIP();
      console.log('');
      console.log('🚀 NjangiPay API is running!');
      console.log(`   Browser/Chrome:  http://localhost:${PORT}`);
      console.log(`   Android device:  http://${localIP}:${PORT}  ← put this in constants.dart`);
      console.log(`   Health check:    http://${localIP}:${PORT}/health`);
      console.log(`   Mode:            ${process.env.NODE_ENV}`);
      console.log('');
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err);
    process.exit(1);
  }
}

main();
