import React, { useState } from 'react';
import { useEncryption } from '../contexts/EncryptionContext';
import { useAuth } from '../contexts/AuthContext';
import { isWebAuthnAvailable } from '../services/webauthn';

export default function UnlockModal({ onUnlock, onCancel }) {
  const [passphrase, setPassphrase] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { unlockWithPassphrase, unlockWithBiometric } = useEncryption();
  const { user } = useAuth();
  
  async function handlePassphraseUnlock(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await unlockWithPassphrase(passphrase);
      onUnlock();
    } catch (err) {
      setError('Invalid passphrase');
    } finally {
      setLoading(false);
    }
  }
  
  async function handleBiometricUnlock() {
    setError('');
    setLoading(true);
    try {
      await unlockWithBiometric();
      onUnlock();
    } catch (err) {
      setError('Biometric unlock failed');
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
        <h2 className="text-2xl font-bold mb-4">Unlock Notes</h2>
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}
        {user?.passphraseHint && (
          <div className="bg-blue-50 border border-blue-200 rounded p-3 mb-4">
            <p className="text-sm text-blue-800"><strong>Hint:</strong> {user.passphraseHint}</p>
          </div>
        )}
        <form onSubmit={handlePassphraseUnlock} className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">Encryption Passphrase</label>
          <input
            type="password"
            value={passphrase}
            onChange={(e) => setPassphrase(e.target.value)}
            placeholder="Enter your passphrase"
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"
            required
/>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Unlocking...' : 'Unlock with Passphrase'}
          </button>
        </form>
        {isWebAuthnAvailable() && (
          <>
            <div className="relative my-4">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-gray-500">or</span>
              </div>
            </div>
            <button
              onClick={handleBiometricUnlock}
              disabled={loading}
              className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50"
            >
              🔐 Unlock with Biometric
            </button>
          </>
        )}
        <button
          onClick={onCancel}
          className="w-full mt-4 border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50"
        >
          Cancel
        </button>
      </div>
    </div>
  );
}
