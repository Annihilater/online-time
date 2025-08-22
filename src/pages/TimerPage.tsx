import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, RotateCcw } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

export const TimerPage: React.FC = () => {
  const { theme, selectedSound, volume } = useAlarmStore();
  const [time, setTime] = useState(0); // in seconds
  const [initialTime, setInitialTime] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [inputMinutes, setInputMinutes] = useState('');
  const [inputSeconds, setInputSeconds] = useState('');
  const [timerName, setTimerName] = useState('');
  const [timerHistory, setTimerHistory] = useState<{id: string, name: string, duration: number, completedAt: Date}[]>([]);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (isRunning && time > 0) {
      intervalRef.current = setInterval(() => {
        setTime((prevTime) => {
          if (prevTime <= 1) {
            setIsRunning(false);
            // Add to history
            setTimerHistory(prev => [{
              id: Date.now().toString(),
              name: timerName || '未命名定时器',
              duration: initialTime,
              completedAt: new Date()
            }, ...prev.slice(0, 9)]);
            // Play alarm sound when timer reaches zero
            const audio = new Audio(`/sounds/${selectedSound}.mp3`);
            audio.volume = volume;
            audio.play().catch(() => {});
            return 0;
          }
          return prevTime - 1;
        });
      }, 1000);
    } else {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isRunning, time, selectedSound, volume]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const handleStart = () => {
    if (time === 0) {
      const totalSeconds = (parseInt(inputMinutes || '0') * 60) + parseInt(inputSeconds || '0');
      if (totalSeconds > 0) {
        setTime(totalSeconds);
        setInitialTime(totalSeconds);
        setIsRunning(true);
      }
    } else {
      setIsRunning(!isRunning);
    }
  };

  const handleReset = () => {
    setIsRunning(false);
    setTime(0);
    setInitialTime(0);
    setInputMinutes('');
    setInputSeconds('');
    setTimerName('');
  };

  const progress = initialTime > 0 ? ((initialTime - time) / initialTime) * 100 : 0;

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          在线定时器
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          设置倒计时定时器，高效管理您的时间
        </p>
      </div>

      {/* Timer Display */}
      <div className="text-center">
        <div className={`text-6xl md:text-8xl font-mono font-bold mb-6 transition-colors duration-300 ${
          time > 0 && time <= 10 ? 'text-red-500' : theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          {formatTime(time)}
        </div>

        {/* Progress Ring */}
        {initialTime > 0 && (
          <div className="relative w-32 h-32 mx-auto mb-6">
            <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 120 120">
              <circle
                cx="60"
                cy="60"
                r="54"
                fill="none"
                stroke={theme === 'dark' ? '#374151' : '#e5e7eb'}
                strokeWidth="12"
              />
              <circle
                cx="60"
                cy="60"
                r="54"
                fill="none"
                stroke="#3b82f6"
                strokeWidth="12"
                strokeDasharray="339.292"
                strokeDashoffset={339.292 - (339.292 * progress) / 100}
                strokeLinecap="round"
                className="transition-all duration-1000 ease-linear"
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className={`text-sm font-semibold ${theme === 'dark' ? 'text-gray-300' : 'text-gray-600'}`}>
                {Math.round(progress)}%
              </span>
            </div>
          </div>
        )}
      </div>

      {/* Timer Input */}
      {time === 0 && (
        <div className="space-y-4 mb-6">
          {/* Timer Name */}
          <div className="flex justify-center">
            <div className="flex flex-col items-center">
              <label className={`text-sm font-medium mb-2 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                定时器名称（可选）
              </label>
              <input
                type="text"
                value={timerName}
                onChange={(e) => setTimerName(e.target.value)}
                placeholder="为这个定时器命名..."
                className={`w-64 px-3 py-2 text-center rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
              />
            </div>
          </div>
          
          {/* Time Input */}
          <div className="flex justify-center space-x-4">
            <div className="flex flex-col items-center">
              <label className={`text-sm font-medium mb-2 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                分钟
              </label>
              <input
                type="number"
                min="0"
                max="99"
                value={inputMinutes}
                onChange={(e) => setInputMinutes(e.target.value)}
                className={`w-20 px-3 py-2 text-center text-lg font-mono rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                placeholder="00"
              />
            </div>
            <div className="flex flex-col items-center">
              <label className={`text-sm font-medium mb-2 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                秒钟
              </label>
              <input
                type="number"
                min="0"
                max="59"
                value={inputSeconds}
                onChange={(e) => setInputSeconds(e.target.value)}
                className={`w-20 px-3 py-2 text-center text-lg font-mono rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                placeholder="00"
              />
            </div>
          </div>
        </div>
      )}

      {/* Control Buttons */}
      <div className="flex justify-center space-x-4">
        <button
          onClick={handleStart}
          className={`flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all duration-300 transform hover:scale-105 ${
            isRunning
              ? 'bg-yellow-500 hover:bg-yellow-600 text-white'
              : 'bg-blue-500 hover:bg-blue-600 text-white'
          }`}
        >
          {isRunning ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5" />}
          <span>{isRunning ? '暂停' : '开始'}</span>
        </button>

        <button
          onClick={handleReset}
          className={`flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all duration-300 transform hover:scale-105 ${
            theme === 'dark'
              ? 'bg-gray-700 hover:bg-gray-600 text-gray-300'
              : 'bg-gray-200 hover:bg-gray-300 text-gray-700'
          }`}
        >
          <RotateCcw className="w-5 h-5" />
          <span>重置</span>
        </button>
      </div>

      {/* Quick Timer Presets */}
      <div className="mb-6">
        <h3 className={`text-lg font-medium mb-3 transition-colors duration-300 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>快速设置</h3>
        <div className="grid grid-cols-4 md:grid-cols-8 gap-2">
          {[
            { label: '15秒', seconds: 15 },
            { label: '30秒', seconds: 30 },
            { label: '1分钟', minutes: 1 },
            { label: '5分钟', minutes: 5 },
            { label: '15分钟', minutes: 15 },
            { label: '30分钟', minutes: 30 },
            { label: '45分钟', minutes: 45 },
            { label: '1小时', minutes: 60 },
          ].map((preset) => (
          <button
            key={preset.minutes}
            onClick={() => {
              if (!isRunning) {
                if (preset.seconds) {
                  setInputMinutes('0');
                  setInputSeconds(preset.seconds.toString());
                } else {
                  setInputMinutes(preset.minutes.toString());
                  setInputSeconds('0');
                }
              }
            }}
            disabled={isRunning}
            className={`px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 ${
              isRunning
                ? theme === 'dark' 
                  ? 'bg-gray-800 text-gray-600 cursor-not-allowed'
                  : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                : theme === 'dark'
                  ? 'bg-gray-700 hover:bg-gray-600 text-gray-300 hover:border-blue-400'
                  : 'bg-white border border-gray-200 hover:bg-blue-50 hover:border-blue-300 text-gray-700'
            } hover:scale-105 transform`}
          >
            {preset.label}
          </button>
        ))}
        </div>
      </div>
      
      {/* Timer History */}
      {time === 0 && (
        <div className="mt-8">
          <h3 className={`text-lg font-medium mb-3 transition-colors duration-300 ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>定时器历史</h3>
          <div className={`rounded-lg border ${
            theme === 'dark' ? 'bg-gray-700 border-gray-600' : 'bg-gray-50 border-gray-200'
          }`}>
            {timerHistory.length === 0 ? (
              <p className={`text-sm text-center p-4 ${
                theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
              }`}>暂无历史记录</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className={`border-b ${
                      theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
                    }`}>
                      <th className={`text-left p-3 font-medium ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>名称</th>
                      <th className={`text-center p-3 font-medium ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>时长</th>
                      <th className={`text-center p-3 font-medium ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>完成时间</th>
                    </tr>
                  </thead>
                  <tbody>
                    {timerHistory.map((record) => (
                      <tr key={record.id} className={`border-b last:border-b-0 ${
                        theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
                      }`}>
                        <td className={`p-3 ${
                          theme === 'dark' ? 'text-white' : 'text-gray-900'
                        }`}>{record.name}</td>
                        <td className={`p-3 text-center font-mono ${
                          theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
                        }`}>{formatTime(record.duration * 1000, false)}</td>
                        <td className={`p-3 text-center text-sm ${
                          theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
                        }`}>{record.completedAt.toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      )}
      </div>
    </div>
  );
};