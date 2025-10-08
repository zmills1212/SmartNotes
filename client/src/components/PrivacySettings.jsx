import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { isWebAuthnAvailable, registerBiometric } from '../services/webauthn';

export default function PrivacySettings() {
  const { user } = useAuth();
  const [autoLock, setAutoLock] = useState(user?.autoLockEnabled ?? true);
  const [registering, setRegistering] = useState(false);
  
  async function handleRegisterBiometric() {
    if (!isWebAuthnAvailable()) {
      alert('WebAuthn is not available in this browser');
      return;
    }
    setRegistering(true);
    try {
      await registerBiometric();
      alert('Biometric authentication registered successfully!');
    } catch (error) {
      alert('Failed to register biometric: ' + error.message);
    } finally {
      setRegistering(false);
    }
  }
  
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-semibold mb-6">Privacy & Security</h2>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-medium text-gray-900">Auto-lock sensitive notes</h3>
            <p className="text-sm text-gray-500">Automatically lock notes containing sensitive keywords</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={autoLock}
              onChange={(e) => setAutoLock(e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
        <div className="border-t pt-6">
          <h3 className="font-medium text-gray-900 mb-2">Biometric Authentication</h3>
          <p className="text-sm text-gray-500 mb-4">Use fingerprint or face recognition to unlock encrypted notes</p>
          {isWebAuthnAvailable() ? (
            <button
              onClick={handleRegisterBiometric}
              disabled={registering}
              className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 disabled:opacity-50"
            >
              {registering ? 'Registering...' : '🔐 Register Biometric'}
            </button>
          ) : (
            <p className="text-sm text-gray-500">Biometric authentication is not available in this browser</p>
          )}
        </div>
        <div className="border-t pt-6">
          <h3 className="font-medium text-gray-900 mb-2">Encryption Status</h3>
          <div className="bg-blue-50 border border-blue-200 rounded p-4">
            <p className="text-sm text-blue-800">
              {user?.hasPassphrase ? '✓ Encryption passphrase is enabled' : '⚠️ No encryption passphrase set'}
            </p>
            {user?.passphraseHint && (
              <p className="text-sm text-blue-700 mt-1">Hint: {user.passphraseHint}</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
