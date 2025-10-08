import React, { createContext, useState, useContext, useEffect } from 'react';
import * as keyManager from '../services/keyManager';
import * as encryption from '../services/encryption';

const EncryptionContext = createContext();

export function EncryptionProvider({ children }) {
  const [masterKey, setMasterKey] = useState(null);
  const [isUnlocked, setIsUnlocked] = useState(false);
  
  useEffect(() => {
    checkUnlockStatus();
  }, []);
  
  async function checkUnlockStatus() {
    const key = await keyManager.getMasterKey();
    if (key) {
      setMasterKey(key);
      setIsUnlocked(true);
    }
  }
  
  async function unlockWithPassphrase(passphrase) {
    const key = await keyManager.deriveMasterKeyFromPassphrase(passphrase);
    await keyManager.storeMasterKey(key);
    setMasterKey(key);
    setIsUnlocked(true);
  }
  
  async function unlockWithBiometric() {
    throw new Error('WebAuthn authentication not fully implemented in this demo');
  }
  
  async function encryptNote(content) {
    if (!masterKey) {
      throw new Error('Master key not available');
    }
    return encryption.encryptContent(content, masterKey);
  }
  
  async function decryptNote(encryptedData, encryptionMeta) {
    if (!masterKey) {
      throw new Error('Master key not available');
    }
    return encryption.decryptContent(encryptedData, encryptionMeta, masterKey);
  }
  
  function lock() {
    keyManager.clearMasterKey();
    setMasterKey(null);
    setIsUnlocked(false);
  }
  
  const value = {
    isUnlocked,
    unlockWithPassphrase,
    unlockWithBiometric,
    encryptNote,
    decryptNote,
    lock
  };
  
  return <EncryptionContext.Provider value={value}>{children}</EncryptionContext.Provider>;
}

export function useEncryption() {
  return useContext(EncryptionContext);
}
