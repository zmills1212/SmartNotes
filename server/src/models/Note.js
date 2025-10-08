const db = require('../config/database');

class Note {
  static async create(noteData) {
    const [note] = await db('notes').insert(noteData).returning('*');
    return note;
  }
  static async findById(id) {
    return db('notes').where({ id }).first();
  }
  static async findByUserId(userId) {
    return db('notes').where({ user_id: userId }).orderBy('created_at', 'desc');
  }
  static async update(id, updates) {
    const [note] = await db('notes').where({ id }).update({ ...updates, updated_at: db.fn.now() }).returning('*');
    return note;
  }
  static async delete(id) {
    return db('notes').where({ id }).del();
  }
  static async findForDigest(userId, startDate, endDate) {
    return db('notes').where({ user_id: userId, is_sensitive: false }).whereBetween('created_at', [startDate, endDate]).orderBy('created_at', 'desc');
  }
}

module.exports = Note;
