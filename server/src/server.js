require('dotenv').config({ path: '../.env' });
const app = require('./app');
const config = require('./config/env');
const schedulerService = require('./services/schedulerService');

const PORT = config.PORT;

const server = app.listen(PORT, () => {
  console.log(`Smart Notes API running on port ${PORT}`);
  console.log(`Environment: ${config.NODE_ENV}`);
  if (config.NODE_ENV !== 'test') {
    schedulerService.start();
  }
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  schedulerService.stop();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

module.exports = server;
