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
