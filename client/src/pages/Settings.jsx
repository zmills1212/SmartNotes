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
