import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { EncryptionProvider } from './contexts/EncryptionContext';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Notes from './pages/Notes';
import Digests from './pages/Digests';
import Settings from './pages/Settings';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <EncryptionProvider>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<Signup />} />
            <Route path="/notes" element={<Notes />} />
            <Route path="/digests" element={<Digests />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/" element={<Navigate to="/notes" replace />} />
          </Routes>
        </EncryptionProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
