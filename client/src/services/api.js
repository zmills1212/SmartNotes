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
