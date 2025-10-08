const db = require('../config/database');

class Digest {
  static async create(digestData) {
    const [digest] = await db('digests').insert(digestData).returning('*');
    return digest;
  }
  static async findByUserId(userId, range = null) {
    let query = db('digests').where({ user_id: userId });
    if (range) query = query.where({ range });
    return query.orderBy('created_at', 'desc');
  }
}

module.exports = Digest;
