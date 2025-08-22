import React from 'react';
import { useAlarmStore, PRESET_TIMES } from '@/shared/stores/alarmStore';
import { AnimatedButton } from './AnimatedButton';
import { Clock } from 'lucide-react';

export const PresetTimes: React.FC = () => {
  const { addPresetAlarm, theme } = useAlarmStore();
  const containerRef = null; 
  const triggerCelebration = () => {};
  
  const handlePresetClick = (hour: number, minute: number, label: string) => {
    addPresetAlarm(hour, minute, label);
    // Trigger a small celebration effect
    triggerCelebration();
  };

  return (
    <div ref={containerRef} className="mb-6 relative">
      <h3 className={`text-lg font-medium mb-3 transition-colors duration-300 ${
        theme === 'dark' ? 'text-white' : 'text-gray-900'
      }`}>快捷时间</h3>
      
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {PRESET_TIMES.map(({ label, hour, minute }) => {
          const PresetButton: React.FC = () => {
            const ref = null;
            
            return (
              <AnimatedButton
                ref={ref}
                onClick={() => handlePresetClick(hour, minute, label)}
                variant="secondary"
                icon={<Clock className="w-4 h-4" />}
                pulseOnHover
                className={`flex items-center justify-center gap-2 py-3 px-4 border rounded-lg transition-all duration-200 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-gray-300 hover:bg-gray-600 hover:border-blue-400 hover:text-blue-400'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-700'
                } transform-gpu will-change-transform`}
              >
                {label}
              </AnimatedButton>
            );
          };
          
          return <PresetButton key={label} />;
        })}
      </div>
      
      {/* Animated divider */}
      <div className="relative mt-6 mb-6">
        <hr className={`transition-colors duration-300 fade-in-up stagger-4 ${
          theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
        }`} />
      </div>
    </div>
  );
};