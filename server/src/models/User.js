const db = require('../config/database');

class User {
  static async create(userData) {
    const [user] = await db('users').insert(userData).returning('*');
    return user;
  }
  static async findById(id) {
    return db('users').where({ id }).first();
  }
  static async findByEmail(email) {
    return db('users').where({ email }).first();
  }
  static async update(id, updates) {
    const [user] = await db('users').where({ id }).update({ ...updates, updated_at: db.fn.now() }).returning('*');
    return user;
  }
}

module.exports = User;
