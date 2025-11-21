import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Dashboard } from './pages/Dashboard';
import { ChatsPage } from './pages/ChatsPage';
import { PromptsPage } from './pages/PromptsPage';
import { AudioPage } from './pages/AudioPage';
import { SettingsPage } from './pages/SettingsPage';
import { ToastContainer } from './components/common/Toast';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/chats" element={<ChatsPage />} />
        <Route path="/prompts" element={<PromptsPage />} />
        <Route path="/audio" element={<AudioPage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Routes>
      <ToastContainer />
    </BrowserRouter>
  );
}

export default App;
