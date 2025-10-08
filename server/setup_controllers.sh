#!/bin/bash

mkdir -p src/controllers

cat > src/controllers/authController.js << 'EOF'
const bcrypt = require('bcrypt');
const User = require('../models/User');
const { generateAccessToken, generateRefreshToken } = require('../utils/jwt');
const db = require('../config/database');

async function register(req, res) {
  try {
    const { email, password, hasPassphrase, passphraseHint } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const existing = await User.findByEmail(email);
    if (existing) return res.status(409).json({ error: 'Email already registered' });
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      email,
      password_hash: passwordHash,
      has_passphrase: hasPassphrase || false,
      passphrase_hint: passphraseHint || null
    });
    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken({ userId: user.id });
    await db('refresh_tokens').insert({
      user_id: user.id,
      token: refreshToken,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });
    res.status(201).json({
      user: { id: user.id, email: user.email, hasPassphrase: user.has_passphrase, passphraseHint: user.passphrase_hint },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const user = await User.findByEmail(email);
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Invalid credentials' });
    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken({ userId: user.id });
    await db('refresh_tokens').insert({
      user_id: user.id,
      token: refreshToken,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });
    res.json({
      user: { id: user.id, email: user.email, hasPassphrase: user.has_passphrase, passphraseHint: user.passphrase_hint, autoLockEnabled: user.auto_lock_enabled },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
}

async function getMe(req, res) {
  try {
    const user = await User.findById(


const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({
      id: user.id,
      email: user.email,
      hasPassphrase: user.has_passphrase,
      passphraseHint: user.passphrase_hint,
      autoLockEnabled: user.auto_lock_enabled
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch user' });
  }
}

module.exports = { register, login, getMe };
EOF

cat > src/controllers/notesController.js << 'EOF'
const Note = require('../models/Note');
const { validateSensitiveNote } = require('../services/keywordDetector');

async function createNote(req, res) {
  try {
    const { title, content, is_sensitive, content_encrypted, encryption_meta, sensitive_keywords } = req.body;
    const validation = validateSensitiveNote(req.body);
    if (!validation.valid) return res.status(400).json({ error: validation.error, matches: validation.matches });
    const note = await Note.create({
      user_id: req.user.userId,
      title: title || null,
      content: content || null,
      content_encrypted: content_encrypted || false,
      encryption_meta: encryption_meta ? JSON.stringify(encryption_meta) : null,
      sensitive_keywords: sensitive_keywords ? JSON.stringify(sensitive_keywords) : '[]',
      is_sensitive: is_sensitive || false
    });
    res.status(201).json(note);
  } catch (error) {
    console.error('Create note error:', error);
    res.status(500).json({ error: 'Failed to create note' });
  }
}

async function getNotes(req, res) {
  try {
    const notes = await Note.findByUserId(req.user.userId);
    const sanitizedNotes = notes.map(note => {
      if (note.content_encrypted && note.is_sensitive) {
        return { ...note, content: '[LOCKED]', encryption_meta: note.encryption_meta };
      }
      return note;
    });
    res.json(sanitizedNotes);
  } catch (error) {
    console.error('Get notes error:', error);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
}

async function getNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    res.json(note);
  } catch (error) {
    console.error('Get note error:', error);
    res.status(500).json({ error: 'Failed to fetch note' });
  }
}

async function updateNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    if (req.body.content !== undefined) {
      const validation = validateSensitiveNote(req.body);
      if (!validation.valid) return res.status(400).json({ error: validation.error, matches: validation.matches });
    }
    const updates = {};
    if (req.body.title !== undefined) updates.title = req.body.title;
    if (req.body.content !== undefined) updates.content = req.body.content;
    if (req.body.content_encrypted !== undefined) updates.content_encrypted = req.body.content_encrypted;
    if (req.body.encryption_meta !== undefined) updates.encryption_meta = JSON.stringify(req.body.encryption_meta);
    if (req.body.is_sensitive !== undefined) updates.is_sensitive = req.body.is_sensitive;
    if (req.body.sensitive_keywords !== undefined) updates.sensitive_keywords = JSON.stringify(req.body.sensitive_keywords);
    const updatedNote = await Note.update(req.params.id, updates);
    res.json(updatedNote);
  } catch (error) {
    console.error('Update note error:', error);
    res.status(500).json({ error: 'Failed to update note' });
  }
}

async function deleteNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    await Note.delete(req.params.id);
    res.status(204).send();
  } catch (error) {
    console.error('Delete note error:', error);
    res.status(500).json({ error: 'Failed to delete note' });
  }
}

module.exports = { createNote, getNotes, getNote, updateNote, deleteNote };
EOF

cat > src/controllers/digestsController.js << 'EOF'
const Digest = require('../models/Digest');
const digestService = require('../services/digestService');

async function getDigests(req, res) {
  try {
    const { range } = req.query;
    const digests = await Digest.findByUserId(req.user.userId, range || null);
    res.json(digests);
  } catch (error) {
    console.error('Get digests error:', error);
    res.status(500).json({ error: 'Failed to fetch digests' });
  }
}

async function generateDigest(req, res) {
  try {
    const { range } = req.query;
    if (!range || !['daily', 'weekly'].includes(range)) {
      return res.status(400).json({ error: 'Range must be "daily" or "weekly"' });
    }
    const digest = await digestService.generateDigest(req.user.userId, range);
    res.status(201).json(digest);
  } catch (error) {
    console.error('Generate digest error:', error);
    res.status(500).json({ error: 'Failed to generate digest' });
  }
}

module.exports = { getDigests, generateDigest };
EOF

cat > src/controllers/webauthnController.js << 'EOF'
const {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse
} = require('@simplewebauthn/server');
const WebAuthnCredential = require('../models/WebAuthnCredential');
const User = require('../models/User');
const config = require('../config/env');

async function getRegisterOptions(req, res) {
  try {
    const user = await User.findById(req.user.userId);
    const options = await generateRegistrationOptions({
      rpName: config.RP_NAME,
      rpID: config.RP_ID,
      userID: user.id.toString(),
      userName: user.email,
      attestationType: 'none',
      authenticatorSelection: {
        authenticatorAttachment: 'platform',
        requireResidentKey: false,
        userVerification: 'preferred'
      }
    });
    res.json(options);
  } catch (error) {
    console.error('WebAuthn register options error:', error);
    res.status(500).json({ error: 'Failed to generate registration options' });
  }
}

async function verifyRegistration(req, res) {
  try {
    const { credential, challenge } = req.body;
    const verification = await verifyRegistrationResponse({
      response: credential,
      expectedChallenge: challenge,
      expectedOrigin: config.ORIGIN,
      expectedRPID: config.RP_ID
    });
    if (!verification.verified) return res.status(400).json({ error: 'Verification failed' });
    const { credentialPublicKey, credentialID, counter } = verification.registrationInfo;
    await WebAuthnCredential.create({
      user_id: req.user.userId,
      credential_id: Buffer.from(credentialID).toString('base64'),
      public_key: Buffer.from(credentialPublicKey).toString('base64'),
      counter,
      transports: credential.response.transports || []
    });
    res.json({ verified: true });
  } catch (error) {
    console.error('WebAuthn verification error:', error);
    res.status(500).json({ error: 'Registration verification failed' });
  }
}

async function getAuthenticateOptions(req, res) {
  try {
    const credentials = await WebAuthnCredential.findByUserId(req.user.userId);
    if (credentials.length === 0) return res.status(404).json({ error: 'No credentials registered' });
    const options = await generateAuthenticationOptions({
      rpID: config.RP_ID,
      allowCredentials: credentials.map(cred => ({
        id: Buffer.from(cred.credential_id, 'base64'),
        type: 'public-key',
        transports: cred.transports || []
      })),
      userVerification: 'preferred'
    });
    res.json(options);
  } catch (error) {
    console.error('WebAuthn auth options error:', error);
    res.status(500).json({ error: 'Failed to generate authentication options' });
  }
}

async function verifyAuthentication(req, res) {
  try {
    const { credential, challenge } = req.body;
    const credentialId = Buffer.from(credential.id, 'base64').toString('base64');
    const storedCredential = await WebAuthnCredential.findByCredentialId(credentialId);
    if (!storedCredential) return res.status(404).json({ error: 'Credential not found' });
    const verification = await verifyAuthenticationResponse({
      response: credential,
      expectedChallenge: challenge,
      expectedOrigin: config.ORIGIN,
      expectedRPID: config.RP_ID,
      authenticator: {
        credentialID: Buffer.from(storedCredential.credential_id, 'base64'),
        credentialPublicKey: Buffer.from(storedCredential.public_key, 'base64'),
        counter: storedCredential.counter
      }
    });
    if (!verification.verified) return res.status(400).json({ error: 'Authentication failed' });
    await WebAuthnCredential.updateCounter(storedCredential.credential_id, verification.authenticationInfo.newCounter);
    res.json({ verified: true });
  } catch (error) {
    console.error('WebAuthn auth verification error:', error);
    res.status(500).json({ error: 'Authentication verification failed' });
  }
}

module.exports = { getRegisterOptions, verifyRegistration, getAuthenticateOptions, verifyAuthentication };
EOF

echo "Controllers created!"
