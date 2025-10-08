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
