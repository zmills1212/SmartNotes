const db = require('../config/database');

class WebAuthnCredential {
  static async create(credentialData) {
    const [credential] = await db('webauthn_credentials').insert(credentialData).returning('*');
    return credential;
  }
  static async findByCredentialId(credentialId) {
    return db('webauthn_credentials').where({ credential_id: credentialId }).first();
  }
  static async findByUserId(userId) {
    return db('webauthn_credentials').where({ user_id: userId }).orderBy('created_at', 'desc');
  }
  static async updateCounter(credentialId, counter) {
    const [credential] = await db('webauthn_credentials').where({ credential_id: credentialId }).update({ counter, last_used_at: db.fn.now() }).returning('*');
    return credential;
  }
}

module.exports = WebAuthnCredential;
