import React, { useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { format } from 'date-fns';

export const ClockPage: React.FC = () => {
  const { theme, currentTime, is24HourFormat } = useAlarmStore();
  const [showAnalog, setShowAnalog] = useState(true);

  const formatDisplayTime = (time: Date) => {
    if (is24HourFormat) {
      return format(time, 'HH:mm:ss');
    } else {
      return format(time, 'hh:mm:ss a');
    }
  };

  const getAnalogClockStyles = (time: Date) => {
    const seconds = time.getSeconds();
    const minutes = time.getMinutes();
    const hours = time.getHours() % 12;

    const secondAngle = (seconds * 6) - 90; // 6 degrees per second
    const minuteAngle = (minutes * 6 + seconds * 0.1) - 90; // 6 degrees per minute + smooth seconds
    const hourAngle = (hours * 30 + minutes * 0.5) - 90; // 30 degrees per hour + smooth minutes

    return {
      second: `rotate(${secondAngle}deg)`,
      minute: `rotate(${minuteAngle}deg)`,
      hour: `rotate(${hourAngle}deg)`,
    };
  };

  const clockStyles = getAnalogClockStyles(currentTime);

  const AnalogClock = () => (
    <div className="relative w-80 h-80 mx-auto mb-8">
      <div className={`w-full h-full rounded-full border-8 relative ${
        theme === 'dark' 
          ? 'border-gray-600 bg-gray-800' 
          : 'border-gray-300 bg-white'
      } shadow-xl`}>
        
        {/* Hour markers */}
        {Array.from({ length: 12 }, (_, i) => (
          <div
            key={i}
            className={`absolute w-1 h-8 ${theme === 'dark' ? 'bg-gray-400' : 'bg-gray-600'}`}
            style={{
              top: '8px',
              left: 'calc(50% - 2px)',
              transformOrigin: '50% 152px',
              transform: `rotate(${i * 30}deg)`,
            }}
          />
        ))}

        {/* Hour numbers */}
        {Array.from({ length: 12 }, (_, i) => {
          const hour = i === 0 ? 12 : i;
          const angle = (i * 30 - 90) * (Math.PI / 180);
          const x = Math.cos(angle) * 120;
          const y = Math.sin(angle) * 120;
          
          return (
            <div
              key={i}
              className={`absolute w-8 h-8 flex items-center justify-center text-xl font-bold ${
                theme === 'dark' ? 'text-white' : 'text-gray-900'
              }`}
              style={{
                left: `calc(50% + ${x}px - 16px)`,
                top: `calc(50% + ${y}px - 16px)`,
              }}
            >
              {hour}
            </div>
          );
        })}

        {/* Clock center */}
        <div className={`absolute w-4 h-4 rounded-full top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-30 ${
          theme === 'dark' ? 'bg-white' : 'bg-gray-900'
        }`} />

        {/* Hour hand */}
        <div
          className={`absolute w-2 h-20 rounded-full top-1/2 left-1/2 origin-bottom z-20 ${
            theme === 'dark' ? 'bg-white' : 'bg-gray-900'
          }`}
          style={{
            transform: `translate(-50%, -100%) ${clockStyles.hour}`,
            transformOrigin: '50% 100%',
          }}
        />

        {/* Minute hand */}
        <div
          className={`absolute w-1 h-28 rounded-full top-1/2 left-1/2 origin-bottom z-20 ${
            theme === 'dark' ? 'bg-gray-300' : 'bg-gray-700'
          }`}
          style={{
            transform: `translate(-50%, -100%) ${clockStyles.minute}`,
            transformOrigin: '50% 100%',
          }}
        />

        {/* Second hand */}
        <div
          className="absolute w-0.5 h-32 rounded-full top-1/2 left-1/2 origin-bottom z-20 bg-red-500 transition-transform duration-75"
          style={{
            transform: `translate(-50%, -100%) ${clockStyles.second}`,
            transformOrigin: '50% 100%',
          }}
        />
      </div>
    </div>
  );

  const DigitalClock = () => (
    <div className="text-center mb-8">
      <div className={`text-8xl md:text-9xl font-mono font-bold mb-4 ${
        theme === 'dark' ? 'text-white' : 'text-gray-900'
      }`}>
        {formatDisplayTime(currentTime)}
      </div>
      <div className={`text-2xl font-semibold ${
        theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
      }`}>
        {format(currentTime, 'yyyy年MM月dd日 EEEE', { locale: undefined })}
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          在线时钟
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          实时显示当前时间，支持模拟和数字两种显示模式
        </p>
      </div>

      {/* Clock Mode Toggle */}
      <div className="flex justify-center mb-8">
        <div className={`flex rounded-lg p-1 ${
          theme === 'dark' ? 'bg-gray-700' : 'bg-gray-100'
        }`}>
          <button
            onClick={() => setShowAnalog(true)}
            className={`px-6 py-2 rounded-md font-medium transition-all duration-200 ${
              showAnalog
                ? 'bg-blue-500 text-white'
                : theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            模拟时钟
          </button>
          <button
            onClick={() => setShowAnalog(false)}
            className={`px-6 py-2 rounded-md font-medium transition-all duration-200 ${
              !showAnalog
                ? 'bg-blue-500 text-white'
                : theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            数字时钟
          </button>
        </div>
      </div>

      {/* Clock Display */}
      {showAnalog ? <AnalogClock /> : <DigitalClock />}

      {/* Time Information */}
      <div className={`grid md:grid-cols-3 gap-4 mt-8`}>
        <div className={`p-4 rounded-lg text-center ${
          theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
        }`}>
          <div className={`text-sm font-medium mb-1 ${
            theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
          }`}>
            当前时区
          </div>
          <div className={`text-lg font-semibold ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            {Intl.DateTimeFormat().resolvedOptions().timeZone}
          </div>
        </div>

        <div className={`p-4 rounded-lg text-center ${
          theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
        }`}>
          <div className={`text-sm font-medium mb-1 ${
            theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
          }`}>
            UTC时间
          </div>
          <div className={`text-lg font-semibold ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            {format(currentTime, 'HH:mm:ss')} UTC
          </div>
        </div>

        <div className={`p-4 rounded-lg text-center ${
          theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
        }`}>
          <div className={`text-sm font-medium mb-1 ${
            theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
          }`}>
            一年中的第
          </div>
          <div className={`text-lg font-semibold ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            {Math.floor((currentTime.getTime() - new Date(currentTime.getFullYear(), 0, 0).getTime()) / 86400000)} 天
          </div>
        </div>
      </div>

      {/* Clock Styles */}
      {showAnalog && (
        <div className={`mt-8 p-6 rounded-lg ${
          theme === 'dark' ? 'bg-gray-800' : 'bg-gray-50'
        }`}>
          <h3 className={`text-lg font-semibold mb-4 ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            时钟说明
          </h3>
          <div className="grid md:grid-cols-3 gap-4 text-sm">
            <div className="flex items-center space-x-2">
              <div className={`w-6 h-1 rounded ${theme === 'dark' ? 'bg-white' : 'bg-gray-900'}`} />
              <span className={theme === 'dark' ? 'text-gray-300' : 'text-gray-600'}>
                时针 (短粗)
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <div className={`w-8 h-0.5 rounded ${theme === 'dark' ? 'bg-gray-300' : 'bg-gray-700'}`} />
              <span className={theme === 'dark' ? 'text-gray-300' : 'text-gray-600'}>
                分针 (中等)
              </span>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-10 h-px rounded bg-red-500" />
              <span className={theme === 'dark' ? 'text-gray-300' : 'text-gray-600'}>
                秒针 (红色细)
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};