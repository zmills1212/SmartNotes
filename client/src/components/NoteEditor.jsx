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
