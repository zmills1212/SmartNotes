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
