import React, { useEffect, useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { formatTimeWithSeconds, formatDate } from '@/shared/utils/timeUtils';
import { Settings, Sun, Moon } from 'lucide-react';

interface AlarmClockProps {
  onOpenSettings: () => void;
}

export const AlarmClock: React.FC<AlarmClockProps> = ({ onOpenSettings }) => {
  const { currentTime, isAlarmRinging, theme } = useAlarmStore();
  const [displayTime, setDisplayTime] = useState('');

  useEffect(() => {
    const timeString = formatTimeWithSeconds(currentTime, true);
    setDisplayTime(timeString);
  }, [currentTime]);

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 text-center">
      {/* Header with theme toggle and settings */}
      <div className="flex justify-between items-center mb-6">
        <button
          onClick={() => {
            const store = useAlarmStore.getState();
            store.updateSettings({ theme: theme === 'light' ? 'dark' : 'light' });
          }}
          className="p-2 rounded-lg bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 transition-colors"
        >
          {theme === 'light' ? (
            <Moon className="w-5 h-5" />
          ) : (
            <Sun className="w-5 h-5" />
          )}
        </button>
        
        <button
          onClick={onOpenSettings}
          className="p-2 rounded-lg bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 transition-colors"
        >
          <Settings className="w-5 h-5" />
        </button>
      </div>

      {/* Date display */}
      <div className="text-lg text-gray-600 dark:text-gray-400 mb-2">
        {formatDate(currentTime)}
      </div>

      {/* Time display */}
      <div className={`text-8xl font-mono font-bold mb-8 transition-all duration-200 ${
        isAlarmRinging ? 'text-red-500 animate-pulse' : 'text-gray-900 dark:text-white'
      }`}>
        {displayTime}
      </div>
    </div>
  );
};