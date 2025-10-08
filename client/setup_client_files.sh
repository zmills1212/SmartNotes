#!/bin/bash

# Main entry point
cat > src/main.jsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# App component
cat > src/App.jsx << 'EOF'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { EncryptionProvider } from './contexts/EncryptionContext';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Notes from './pages/Notes';
import Digests from './pages/Digests';
import Settings from './pages/Settings';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <EncryptionProvider>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<Signup />} />
            <Route path="/notes" element={<Notes />} />
            <Route path="/digests" element={<Digests />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/" element={<Navigate to="/notes" replace />} />
          </Routes>
        </EncryptionProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
EOF

# Services
mkdir -p src/services

cat > src/services/api.js << 'EOF'
const API_BASE = import.meta.env.VITE_API_URL || '/api';

async function fetchAPI(endpoint, options = {}) {
  const token = localStorage.getItem('accessToken');
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
    ...options.headers
  };
  const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(error.error || 'Request failed');
  }
  return response.json();
}

export async function register(email, password, hasPassphrase, passphraseHint) {
  return fetchAPI('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ email, password, hasPassphrase, passphraseHint })
  });
}

export async function login(email, password) {
  return fetchAPI('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password })
  });
}

export async function getMe() {
  return fetchAPI('/auth/me');
}

export async function getNotes() {
  return fetchAPI('/notes');
}

export async function getNote(id) {
  return fetchAPI(`/notes/${id}`);
}

export async function createNote(noteData) {
  return fetchAPI('/notes', {
    method: 'POST',
    body: JSON.stringify(noteData)
  });
}

export async function updateNote(id, noteData) {
  return fetchAPI(`/notes/${id}`, {
    method: 'PUT',
    body: JSON.stringify(noteData)
  });
}

export async function deleteNote(id) {
  return fetchAPI(`/notes/${id}`, { method: 'DELETE' });
}

export async function getDigests(range) {
  const query = range ? `?range=${range}` : '';
  return fetchAPI(`/digests${query}`);
}

export async function generateDigest(range) {
  return fetchAPI(`/digests/generate?range=${range}`, { method: 'POST' });
}

export async function getRegisterOptions() {
  return fetchAPI('/webauthn/register-options');
}

export async function verifyRegistration(credential, challenge) {
  return fetchAPI('/webauthn/register', {
    method: 'POST',
    body: JSON.stringify({ credential, challenge })
  });
}

export async function getAuthenticateOptions() {
  return fetchAPI('/webauthn/authenticate-options');
}

export async function verifyAuthentication(credential, challenge) {
  return fetchAPI('/webauthn/authenticate', {
    method: 'POST',
    body: JSON.stringify({ credential, challenge })
  });
}
EOF

cat > src/services/encryption.js << 'EOF'
export async function encryptContent(content, masterKey) {
  const noteKey = await crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, ['encrypt', 'decrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoder = new TextEncoder();
  const contentBytes = encoder.encode(content);
  const ciphertext = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, noteKey, contentBytes);
  const exportedNoteKey = await crypto.subtle.exportKey('raw', noteKey);
  const wrappedNoteKey = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: crypto.getRandomValues(new Uint8Array(12)) },
    masterKey,
    exportedNoteKey
  );
  return {
    ciphertext: arrayBufferToBase64(ciphertext),
    encryptionMeta: {
      iv: arrayBufferToBase64(iv),
      wrappedNoteKey: arrayBufferToBase64(wrappedNoteKey),
      algo: 'AES-GCM-256'
    }
  };
}

export async function decryptContent(ciphertextBase64, encryptionMeta, masterKey) {
  const ciphertext = base64ToArrayBuffer(ciphertextBase64);
  const iv = base64ToArrayBuffer(encryptionMeta.iv);
  const wrappedNoteKey = base64ToArrayBuffer(encryptionMeta.wrappedNoteKey);
  const noteKeyBytes = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: crypto.getRandomValues(new Uint8Array(12)) },
    masterKey,
    wrappedNoteKey
  );
  const noteKey = await crypto.subtle.importKey('raw', noteKeyBytes, { name: 'AES-GCM' }, false, ['decrypt']);
  const decrypted = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, noteKey, ciphertext);
  const decoder = new TextDecoder();
  return decoder.decode(decrypted);
}

function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function base64ToArrayBuffer(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}
EOF

cat > src/services/keyManager.js << 'EOF'
const SALT_LENGTH = 16;
const PBKDF2_ITERATIONS = 100000;

export async function deriveMasterKeyFromPassphrase(passphrase, salt = null) {
  if (!salt) {
    salt = crypto.getRandomValues(new Uint8Array(SALT_LENGTH));
    localStorage.setItem('encryption_salt', arrayBufferToBase64(salt));
  }
  const encoder = new TextEncoder();
  const passphraseKey = await crypto.subtle.importKey(
    'raw',
    encoder.encode(passphrase),
    'PBKDF2',
    false,
    ['deriveBits', 'deriveKey']
  );
  const masterKey = await crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt,
      iterations: PBKDF2_ITERATIONS,
      hash: 'SHA-256'
    },
    passphraseKey,
    { name: 'AES-GCM', length: 256 },
    true,
    ['encrypt', 'decrypt']
  );
  return masterKey;
}

let inMemoryMasterKey = null;

export async function storeMasterKey(key) {
  inMemoryMasterKey = key;
}

export async function getMasterKey() {
  return inMemoryMasterKey;
}

export function clearMasterKey() {
  inMemoryMasterKey = null;
}

function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}
EOF

cat > src/services/keywordDetector.js << 'EOF'
export const DEFAULT_KEYWORDS = ['password','passcode','pin','ssn','social security','credit card','debit card','bank account','account number','routing number','medical','diagnosis','hiv','cancer','salary','income','tax','bitcoin','private key','seed phrase','mnemonic','secret key','api key','access token'];

export function detectSensitiveContent(text, customKeywords = []) {
  if (!text) return { isSensitive: false, matches: [] };
  const keywords = [...DEFAULT_KEYWORDS, ...customKeywords];
  const lowerText = text.toLowerCase();
  const matches = [];
  for (const keyword of keywords) {
    if (lowerText.includes(keyword.toLowerCase())) {
      matches.push(keyword);
    }
  }
  return {
    isSensitive: matches.length > 0,
    matches: [...new Set(matches)]
  };
}
EOF

cat > src/services/webauthn.js << 'EOF'
import { startRegistration, startAuthentication } from '@simplewebauthn/browser';
import * as api from './api';

export async function registerBiometric() {
  try {
    const options = await api.getRegisterOptions();
    const credential = await startRegistration(options);
    await api.verifyRegistration(credential, options.challenge);
    return { success: true };
  } catch (error) {
    console.error('WebAuthn registration failed:', error);
    throw error;
  }
}

export async function authenticateBiometric() {
  try {
    const options = await api.getAuthenticateOptions();
    const credential = await startAuthentication(options);
    await api.verifyAuthentication(credential, options.challenge);
    return { success: true };
  } catch (error) {
    console.error('WebAuthn authentication failed:', error);
    throw error;
  }
}

export function isWebAuthnAvailable() {
  return window.PublicKeyCredential !== undefined && navigator.credentials !== undefined;
}
EOF

echo "Client services created!"
