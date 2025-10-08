#!/bin/bash

mkdir -p src/pages

cat > src/pages/Login.jsx << 'EOF'
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  
  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8">
        <h1 className="text-3xl font-bold text-center mb-8">Smart Notes</h1>
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Logging in...' : 'Log In'}
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-gray-600">
          Don't have an account?{' '}
          <Link to="/signup" className="text-blue-600 hover:underline">Sign up</Link>
        </p>
      </div>
    </div>
  );
}
EOF

cat > src/pages/Signup.jsx << 'EOF'
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function Signup() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [hasPassphrase, setHasPassphrase] = useState(false);
  const [passphraseHint, setPassphraseHint] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { signup } = useAuth();
  
  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    if (password !== confirmPassword) {
      return setError('Passwords do not match');
    }
    if (password.length < 8) {
      return setError('Password must be at least 8 characters');
    }
    setLoading(true);
    try {
      await signup(email, password, hasPassphrase, passphraseHint);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8">
        <h1 className="text-3xl font-bold text-center mb-8">Create Account</h1>
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Confirm Password</label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
            <label className="flex items-center space-x-2">
              <input
                type="checkbox"
                checked={hasPassphrase}
                onChange={(e) => setHasPassphrase(e.target.checked)}
                className="rounded"
              />
              <span className="text-sm text-gray-700">
                Enable encryption passphrase (for sensitive notes)
              </span>
            </label>
            {hasPassphrase && (
              <div className="mt-3">
                <input
                  type="text"
                  placeholder="Passphrase hint (optional)"
                  value={passphraseHint}
                  onChange={(e) => setPassphraseHint(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
                />
              </div>
            )}
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Creating account...' : 'Sign Up'}
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-gray-600">
          Already have an account?{' '}
          <Link to="/login" className="text-blue-600 hover:underline">Log in</Link>
        </p>
      </div>
    </div>
  );
}
EOF

cat > src/pages/Notes.jsx << 'EOF'
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
EOF

cat > src/pages/Digests.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import DigestView from '../components/DigestView';
import * as api from '../services/api';

export default function Digests() {
  const [digests, setDigests] = useState([]);
  const [range, setRange] = useState('daily');
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  
  useEffect(() => {
    loadDigests();
  }, [range]);
  
  async function loadDigests() {
    try {
      setLoading(true);
      const data = await api.getDigests(range);
      setDigests(data);
    } catch (error) {
      console.error('Failed to load digests:', error);
    } finally {
      setLoading(false);
    }
  }
  
  async function handleGenerate() {
    try {
      setGenerating(true);
      await api.generateDigest(range);
      await loadDigests();
    } catch (error) {
      console.error('Failed to generate digest:', error);
      alert('Failed to generate digest');
    } finally {
      setGenerating(false);
    }
  }
  
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <Link to="/notes" className="text-blue-600 hover:text-blue-700">← Back to Notes</Link>
        </div>
      </nav>
      <div className="max-w-4xl mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold">Smart Digests</h1>
          <button
            onClick={handleGenerate}
            disabled={generating}
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {generating ? 'Generating...' : 'Generate Now'}
          </button>
        </div>
        <div className="mb-6 flex space-x-2">
          <button
            onClick={() => setRange('daily')}
            className={`px-4 py-2 rounded-md ${range === 'daily' ? 'bg-blue-600 text-white' : 'bg-white text-gray-700 border border-gray-300'}`}
          >
            Daily
          </button>
          <button
            onClick={() => setRange('weekly')}
            className={`px-4 py-2 rounded-md ${range === 'weekly' ? 'bg-blue-600 text-white' : 'bg-white text-gray-700 border border-gray-300'}`}
          >
            Weekly
          </button>
        </div>
        {loading ? (
          <div className="text-center py-8">Loading digests...</div>
        ) : digests.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
            No digests yet. Click "Generate Now" to create one!
          </div>
        ) : (
          <div className="space-y-4">
            {digests.map(digest => (
              <DigestView key={digest.id} digest={digest} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
EOF

cat > src/pages/Settings.jsx << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import PrivacySettings from '../components/PrivacySettings';

export default function Settings() {
  const { user } = useAuth();
  
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <Link to="/notes" className="text-blue-600 hover:text-blue-700">← Back to Notes</Link>
        </div>
      </nav>
      <div className="max-w-4xl mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Settings</h1>
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Account</h2>
          <p className="text-gray-600">Email: {user?.email}</p>
        </div>
        <PrivacySettings />
      </div>
    </div>
  );
}
EOF

echo "Pages created!"
