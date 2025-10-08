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
