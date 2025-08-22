import React from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { Github, Heart } from 'lucide-react';

export const Footer: React.FC = () => {
  const { theme } = useAlarmStore();

  return (
    <footer className="container mx-auto px-4 py-6 mt-8">
      <div className={`text-center text-sm transition-colors duration-300 fade-in-up stagger-4 ${
        theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
      }`}>
        <div className="flex items-center justify-center gap-4 mb-2">
          <span className="flex items-center gap-1">
            Made with <Heart className="w-4 h-4 text-red-400 heartbeat" /> by Online Time
          </span>
          <a 
            href="https://github.com" 
            target="_blank" 
            rel="noopener noreferrer"
            className={`flex items-center gap-1 transition-all duration-200 ${
              theme === 'dark' 
                ? 'hover:text-gray-300' 
                : 'hover:text-gray-700'
            } hover:scale-105 transform-gpu`}
          >
            <Github className="w-4 h-4" />
            GitHub
          </a>
        </div>
        <p>© 2025 在线闹钟网站. 不需下载，免费使用</p>
      </div>
    </footer>
  );
};