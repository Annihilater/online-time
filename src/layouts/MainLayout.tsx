import React, { useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '@/shared/components/Header';
import { Footer } from '@/shared/components/Footer';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { useTimer } from '@/shared/hooks/useTimer';
import { AlarmRinging } from '@/shared/components/AlarmRinging';
import { SettingsModal } from '@/shared/components/SettingsModal';
import { useState } from 'react';

export const MainLayout: React.FC = () => {
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const { theme } = useAlarmStore();
  
  // Initialize global timer
  useTimer();
  
  // Set initial theme
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  return (
    <div className={`min-h-screen transition-colors duration-300 ${
      theme === 'dark' 
        ? 'bg-gray-900' 
        : 'bg-gray-50'
    }`}>
      <Header onOpenSettings={() => setIsSettingsOpen(true)} />
      
      <main className="container mx-auto px-4 py-8">
        <div className={`max-w-4xl mx-auto rounded-lg shadow-sm border p-6 transition-all duration-300 fade-in-up ${
          theme === 'dark'
            ? 'bg-gray-800 border-gray-700 shadow-gray-900/20'
            : 'bg-white border-gray-200 shadow-gray-300/20'
        } hover:shadow-lg transform-gpu will-change-transform`}>
          <Outlet />
        </div>
      </main>

      <Footer />

      {/* Global Modals */}
      <SettingsModal 
        isOpen={isSettingsOpen} 
        onClose={() => setIsSettingsOpen(false)} 
      />
      
      {/* Global Alarm Ringing Overlay */}
      <AlarmRinging />
    </div>
  );
};