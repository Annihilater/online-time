import React, { useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { createTimeFromInput, isAlarmTimeValid } from '@/shared/utils/timeUtils';
import { AnimatedButton } from './AnimatedButton';

export const TimePicker: React.FC = () => {
  const [hourInput, setHourInput] = useState('00');
  const [minuteInput, setMinuteInput] = useState('00');
  const [labelInput, setLabelInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { addAlarm, theme } = useAlarmStore();
  const containerRef = null;
  const particleRef = { current: null };

  const handleAddAlarm = async () => {
    const timeString = `${hourInput}:${minuteInput}`;
    if (!isAlarmTimeValid(timeString)) {
      // Shake animation for invalid input
      // Error animation removed for stability
      alert('请选择有效的时间');
      return;
    }

    setIsLoading(true);
    
    // Small delay to show loading state
    await new Promise(resolve => setTimeout(resolve, 500));
    
    try {
      const alarmTime = createTimeFromInput(timeString);
      addAlarm(alarmTime, labelInput.trim() || undefined);
      
      // Success animation
      // Celebration animation removed for stability
      
      // Reset inputs with animation
      // Animation removed for stability
      setHourInput('00');
      setMinuteInput('00');
      setLabelInput('');
      // Animation removed for stability
    } catch (error) {
      console.error('Failed to add alarm:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Generate hour options (00-23)
  const hourOptions = Array.from({ length: 24 }, (_, i) => 
    i.toString().padStart(2, '0')
  );
  
  // Generate minute options (00-59)
  const minuteOptions = Array.from({ length: 60 }, (_, i) => 
    i.toString().padStart(2, '0')
  );

  return (
    <div ref={containerRef} className="mb-6 relative">
      <div ref={particleRef} className="absolute inset-0 pointer-events-none z-10" />
      <div className="mb-4">
        <h3 className={`text-lg font-medium mb-3 transition-colors duration-300 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>设置闹钟时间</h3>
        
        <div className="flex gap-3 items-center mb-4 fade-in-up">
          {/* Hour selector */}
          <div>
            <label className={`block text-sm mb-1 transition-colors duration-300 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
            }`}>小时</label>
            <select
              value={hourInput}
              onChange={(e) => setHourInput(e.target.value)}
              disabled={isLoading}
              className={`select select-bordered w-20 focus:border-blue-500 transition-all duration-300 transform-gpu ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 text-white'
                  : 'bg-white border-gray-300 text-gray-900'
              } ${isLoading ? 'opacity-50 cursor-not-allowed' : 'hover:scale-105 focus:scale-105'}`}
            >
              {hourOptions.map(hour => (
                <option key={hour} value={hour}>{hour}</option>
              ))}
            </select>
          </div>
          
          <div className={`mt-6 text-xl font-bold digital-font transition-colors duration-300 ${
            theme === 'dark' ? 'text-gray-500' : 'text-gray-400'
          }`}>:</div>
          
          {/* Minute selector */}
          <div>
            <label className={`block text-sm mb-1 transition-colors duration-300 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
            }`}>分钟</label>
            <select
              value={minuteInput}
              onChange={(e) => setMinuteInput(e.target.value)}
              disabled={isLoading}
              className={`select select-bordered w-20 focus:border-blue-500 transition-all duration-300 transform-gpu ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 text-white'
                  : 'bg-white border-gray-300 text-gray-900'
              } ${isLoading ? 'opacity-50 cursor-not-allowed' : 'hover:scale-105 focus:scale-105'}`}
            >
              {minuteOptions.map(minute => (
                <option key={minute} value={minute}>{minute}</option>
              ))}
            </select>
          </div>
        </div>
        
        {/* Label input */}
        <div className="mb-4 fade-in-up stagger-1">
          <label className={`block text-sm mb-1 transition-colors duration-300 ${
            theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
          }`}>闹钟名称 (可选)</label>
          <input
            type="text"
            disabled={isLoading}
            className={`input input-bordered w-full focus:border-blue-500 transition-all duration-300 transform-gpu ${
              theme === 'dark'
                ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400'
                : 'bg-white border-gray-300 text-gray-900 placeholder-gray-500'
            } ${isLoading ? 'opacity-50 cursor-not-allowed' : 'hover:scale-[1.01] focus:scale-[1.01]'}`}
            value={labelInput}
            onChange={(e) => setLabelInput(e.target.value)}
            placeholder="输入闹钟名称"
            maxLength={30}
          />
        </div>
        
        {/* Add button */}
        <div className="fade-in-up stagger-2">
          <AnimatedButton
            onClick={handleAddAlarm}
            variant="primary"
            size="md"
            loading={isLoading}
            disabled={isLoading}
            className="w-full"
            glowEffect
          >
            {isLoading ? '设置中...' : '设置闹钟'}
          </AnimatedButton>
        </div>
      </div>
      
      {/* Animated divider */}
      <div className="relative mb-6">
        <hr className={`transition-colors duration-300 fade-in-up stagger-3 ${
          theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
        }`} />
      </div>
    </div>
  );
};