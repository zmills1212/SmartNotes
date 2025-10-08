const cron = require('node-cron');
const config = require('../config/env');

class SchedulerService {
  constructor() {
    this.jobs = [];
  }
  start() {
    console.log('Scheduler service started (digest jobs would run here)');
  }
  stop() {
    this.jobs.forEach(job => job.stop());
  }
}

module.exports = new SchedulerService();
