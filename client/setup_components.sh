#!/bin/bash

mkdir -p src/components

cat > src/components/NoteEditor.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import { useEncryption } from '../contexts/EncryptionContext';
import { detectSensitiveContent } from '../services/keywordDetector';
import * as api from '../services/api';
import UnlockModal from './UnlockModal';

export default function NoteEditor({ note, onSave, onCancel }) {
  const [title, setTitle] = useState(note?.title || '');
  const [content, setContent] = useState(note?.content || '');
  const [isSensitive, setIsSensitive] = useState(false);
  const [keywords, setKeywords] = useState([]);
  const [saving, setSaving] = useState(false);
  const [showUnlock, setShowUnlock] = useState(false);
  const { isUnlocked, encryptNote } = useEncryption();
  
  useEffect(() => {
    const detection = detectSensitiveContent(content);
    setIsSensitive(detection.isSensitive);
    setKeywords(detection.matches);
  }, [content]);
  
  async function handleSave() {
    if (!content.trim()) {
      alert('Content cannot be empty');
      return;
    }
    if (isSensitive && !isUnlocked) {
      setShowUnlock(true);
      return;
    }
    setSaving(true);
    try {
      let noteData = {
        title: title.trim() || null,
        content: content.trim(),
        is_sensitive: isSensitive,
        content_encrypted: false,
        encryption_meta: null,
        sensitive_keywords: keywords
      };
      if (isSensitive && isUnlocked) {
        const { ciphertext, encryptionMeta } = await encryptNote(content);
        noteData = {
          ...noteData,
          content: ciphertext,
          content_encrypted: true,
          encryption_meta: encryptionMeta
        };
      }
      if (note) {
        await api.updateNote(note.id, noteData);
      } else {
        await api.createNote(noteData);
      }
      onSave();
    } catch (error) {
      console.error('Save failed:', error);
      alert(error.message);
    } finally {
      setSaving(false);
    }
  }
  
  function handleUnlocked() {
    setShowUnlock(false);
    handleSave();
  }
  
  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      {isSensitive && (
        <div className="mb-4 bg-yellow-50 border border-yellow-200 rounded-md p-3">
          <div className="flex items-center">
            <span className="text-yellow-800 font-medium">🔒 Sensitive content detected</span>
          </div>
          <p className="text-sm text-yellow-700 mt-1">Keywords: {keywords.join(', ')}</p>
          <p className="text-xs text-yellow-600 mt-1">This note will be encrypted before saving.</p>
        </div>
      )}
      <input
        type="text"
        placeholder="Note title (optional)"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md mb-4 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <textarea
        placeholder="Write your note here..."
        value={content}
        onChange={(e) => setContent(e.target.value)}
        rows={10}
        className="w-full px-3 py-2 border border-gray-300 rounded-md mb-4 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <div className="flex justify-end space-x-3">
        <button
          onClick={onCancel}
          className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save Note'}
        </button>
      </div>
      {showUnlock && (
        <UnlockModal onUnlock={handleUnlocked} onCancel={() => setShowUnlock(false)} />
      )}
    </div>
  );
}
EOF

cat > src/components/NoteList.jsx << 'EOF'
import React from 'react';
import LockedNote from './LockedNote';
import * as api from '../services/api';

export default function NoteList({ notes, onUpdate }) {
  async function handleDelete(id) {
    if (!confirm('Delete this note?')) return;
    try {
      await api.deleteNote(id);
      onUpdate();
    } catch (error) {
      alert('Failed to delete note');
    }
  }
  
  if (notes.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
        No notes yet. Create your first note!
      </div>
    );
  }
  
  return (
    <div className="space-y-4">
      {notes.map(note => (
        <div key={note.id}>
          {note.is_sensitive && note.content === '[LOCKED]' ? (
            <LockedNote note={note} onUpdate={onUpdate} />
          ) : (
            <div className="bg-white rounded-lg shadow-md p-6">
              {note.title && <h3 className="text-lg font-semibold mb-2">{note.title}</h3>}
              <p className="text-gray-700 whitespace-pre-wrap mb-4">{note.content}</p>
              <div className="flex justify-between items-center text-sm text-gray-500">
                <span>{new Date(note.created_at).toLocaleDateString()}</span>
                <button onClick={() => handleDelete(note.id)} className="text-red-600 hover:text-red-700">
                  Delete
                </button>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
EOF

cat > src/components/LockedNote.jsx << 'EOF'
import React, { useState } from 'react';
import { useEncryption } from '../contexts/EncryptionContext';
import UnlockModal from './UnlockModal';
import * as api from '../services/api';

export default function LockedNote({ note, onUpdate }) {
  const [showUnlock, setShowUnlock] = useState(false);
  const [unlocked, setUnlocked] = useState(false);
  const [decryptedContent, setDecryptedContent] = useState('');
  const { decryptNote } = useEncryption();
  
  async function handleUnlock() {
    try {
      const fullNote = await api.getNote(note.id);
      const content = await decryptNote(fullNote.content, fullNote.encryption_meta);
      setDecryptedContent(content);
      setUnlocked(true);
      setShowUnlock(false);
    } catch (error) {
      console.error('Unlock failed:', error);
      alert('Failed to unlock note. Check your passphrase.');
    }
  }
  
  if (unlocked) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 border-2 border-yellow-300">
        <div className="flex items-center justify-between mb-3">
          {note.title && <h3 className="text-lg font-semibold">{note.title}</h3>}
          <span className="text-yellow-700 text-sm">🔓 Unlocked</span>
        </div>
        <p className="text-gray-700 whitespace-pre-wrap mb-4">{decryptedContent}</p>
        <div className="flex justify-between items-center text-sm text-gray-500">
          <span>{new Date(note.created_at).toLocaleDateString()}</span>
          <button onClick={() => setUnlocked(false)} className="text-blue-600 hover:text-blue-700">
            Lock again
          </button>
        </div>
      </div>
    );
  }
  
  return (
    <>
      <div className="bg-gray-100 rounded-lg shadow-md p-6 border-2 border-gray-300">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-700">
              🔒 {note.title || 'Sensitive Note'}
            </h3>
            <p className="text-sm text-gray-500 mt-1">This note is encrypted. Unlock to view.</p>
          </div>
          <button
            onClick={() => setShowUnlock(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Unlock
          </button>
        </div>
        <div className="mt-3 text-xs text-gray-500">
          {new Date(note.created_at).toLocaleDateString()}
        </div>
      </div>
      {showUnlock && (
        <UnlockModal onUnlock={handleUnlock} onCancel={() => setShowUnlock(false)} />
      )}
    </>
  );
}
EOF

cat > src/components/UnlockModal.jsx << 'EOF'
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
EOF

cat > src/components/DigestView.jsx << 'EOF'
import React from 'react';

export default function DigestView({ digest }) {
  const themes = typeof digest.themes === 'string' ? JSON.parse(digest.themes) : digest.themes;
  
  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-semibold capitalize">{digest.range} Digest</h3>
          <p className="text-sm text-gray-500">
            {new Date(digest.period_start).toLocaleDateString()} - {new Date(digest.period_end).toLocaleDateString()}
          </p>
        </div>
        <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
          {JSON.parse(digest.source_note_ids).length} notes
        </span>
      </div>
      <div className="mb-4">
        <h4 className="font-medium text-gray-700 mb-2">Summary</h4>
        <div className="text-gray-600 whitespace-pre-line text-sm">{digest.summary}</div>
      </div>
      {themes && themes.length > 0 && (
        <div>
          <h4 className="font-medium text-gray-700 mb-2">Recurring Themes</h4>
          <div className="flex flex-wrap gap-2">
            {themes.map((theme, idx) => (
              <span key={idx} className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-xs">
                {theme.keyword} ({theme.count})
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
EOF

cat > src/components/PrivacySettings.jsx << 'EOF'
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
EOF

echo "Components created!"
