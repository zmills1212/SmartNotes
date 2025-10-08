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
