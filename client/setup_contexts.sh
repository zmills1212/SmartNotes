#!/bin/bash

mkdir -p src/contexts

cat > src/contexts/AuthContext.jsx << 'EOF'
import React, { createContext, useState, useContext, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import * as api from '../services/api';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  
  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      loadUser();
    } else {
      setLoading(false);
    }
  }, []);
  
  async function loadUser() {
    try {
      const userData = await api.getMe();
      setUser(userData);
    } catch (error) {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
    } finally {
      setLoading(false);
    }
  }
  
  async function login(email, password) {
    const data = await api.login(email, password);
    localStorage.setItem('accessToken', data.accessToken);
    localStorage.setItem('refreshToken', data.refreshToken);
    setUser(data.user);
    navigate('/notes');
  }
  
  async function signup(email, password, hasPassphrase, passphraseHint) {
    const data = await api.register(email, password, hasPassphrase, passphraseHint);
    localStorage.setItem('accessToken', data.accessToken);
    localStorage.setItem('refreshToken', data.refreshToken);
    setUser(data.user);
    navigate('/notes');
  }
  
  function logout() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    setUser(null);
    navigate('/login');
  }
const value = {
    user,
    loading,
    login,
    signup,
    logout,
    isAuthenticated: !!user
  };
  
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
EOF

cat > src/contexts/EncryptionContext.jsx << 'EOF'
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
EOF

echo "Contexts created!"
