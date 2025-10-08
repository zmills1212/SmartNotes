require('dotenv').config({ path: '../../.env' });
module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT, 10) || 4000,
  DATABASE_URL: process.env.DATABASE_URL,
  JWT_SECRET: process.env.JWT_SECRET || 'dev-secret',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'dev-refresh',
  JWT_EXPIRATION: process.env.JWT_EXPIRATION || '1h',
  JWT_REFRESH_EXPIRATION: process.env.JWT_REFRESH_EXPIRATION || '7d',
  RP_NAME: process.env.RP_NAME || 'Smart Notes',
  RP_ID: process.env.RP_ID || 'localhost',
  ORIGIN: process.env.ORIGIN || 'http://localhost:4000',
  OPENAI_API_KEY: process.env.OPENAI_API_KEY,
  DAILY_DIGEST_CRON: process.env.DAILY_DIGEST_CRON || '0 8 * * *',
  WEEKLY_DIGEST_CRON: process.env.WEEKLY_DIGEST_CRON || '0 8 * * 1',
  CLIENT_URL: process.env.CLIENT_URL || 'http://localhost:4000'
};
