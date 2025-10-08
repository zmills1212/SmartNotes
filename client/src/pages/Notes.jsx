import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import NoteEditor from '../components/NoteEditor';
import NoteList from '../components/NoteList';
import * as api from '../services/api';

export default function Notes() {
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showEditor, setShowEditor] = useState(false);
  const { user, logout, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }
    loadNotes();
  }, [isAuthenticated]);
  
  async function loadNotes() {
    try {
      const data = await api.getNotes();
      setNotes(data);
    } catch (error) {
      console.error('Failed to load notes:', error);
    } finally {
      setLoading(false);
    }
  }
  
  function handleNoteCreated() {
    setShowEditor(false);
    loadNotes();
  }
  
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-6xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-800">Smart Notes</h1>
          <div className="flex items-center space-x-4">
            <Link to="/digests" className="text-blue-600 hover:text-blue-700">Digests</Link>
            <Link to="/settings" className="text-blue-600 hover:text-blue-700">Settings</Link>
            <span className="text-gray-600">{user?.email}</span>
            <button onClick={logout} className="text-red-600 hover:text-red-700">Logout</button>
          </div>
        </div>
      </nav>
      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-semibold">My Notes</h2>
          <button
            onClick={() => setShowEditor(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
          >
            + New Note
          </button>
        </div>
        {showEditor && (
          <div className="mb-6">
            <NoteEditor onSave={handleNoteCreated} onCancel={() => setShowEditor(false)} />
          </div>
        )}
        {loading ? (
          <div className="text-center py-8">Loading notes...</div>
        ) : (
          <NoteList notes={notes} onUpdate={loadNotes} />
        )}
      </div>
    </div>
  );
}
