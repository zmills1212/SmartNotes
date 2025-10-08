#!/bin/bash

# Config files
mkdir -p src/config
cat > src/config/database.js << 'EOF'
const knex = require('knex');
const knexConfig = require('../../knexfile');
const environment = process.env.NODE_ENV || 'development';
const config = knexConfig[environment];
const db = knex(config);
module.exports = db;
EOF

cat > src/config/env.js << 'EOF'
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
EOF

# Utils
mkdir -p src/utils
cat > src/utils/jwt.js << 'EOF'
const jwt = require('jsonwebtoken');
const config = require('../config/env');

function generateAccessToken(payload) {
  return jwt.sign(payload, config.JWT_SECRET, { expiresIn: config.JWT_EXPIRATION });
}

function generateRefreshToken(payload) {
  return jwt.sign(payload, config.JWT_REFRESH_SECRET, { expiresIn: config.JWT_REFRESH_EXPIRATION });
}

function verifyAccessToken(token) {
  return jwt.verify(token, config.JWT_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, config.JWT_REFRESH_SECRET);
}

module.exports = { generateAccessToken, generateRefreshToken, verifyAccessToken, verifyRefreshToken };
EOF

# Middleware
mkdir -p src/middleware
cat > src/middleware/auth.js << 'EOF'
const { verifyAccessToken } = require('../utils/jwt');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const token = authHeader.substring(7);
    const decoded = verifyAccessToken(token);
    req.user = { userId: decoded.userId, email: decoded.email };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    return res.status(500).json({ error: 'Authentication failed' });
  }
}

module.exports = { authenticate };
EOF

cat > src/middleware/errorHandler.js << 'EOF'
function errorHandler(err, req, res, next) {
  console.error('Error:', err);
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

module.exports = { errorHandler };
EOF

# Models
mkdir -p src/models
cat > src/models/User.js << 'EOF'
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
EOF

cat > src/models/Note.js << 'EOF'
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
EOF

cat > src/models/Digest.js << 'EOF'
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
EOF

cat > src/models/WebAuthnCredential.js << 'EOF'
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
EOF

echo "Server files created successfully!"
