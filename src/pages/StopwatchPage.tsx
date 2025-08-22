import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, RotateCcw, Flag } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface LapTime {
  id: number;
  time: number;
  lapTime: number;
}

export const StopwatchPage: React.FC = () => {
  const { theme } = useAlarmStore();
  const [time, setTime] = useState(0); // in milliseconds
  const [isRunning, setIsRunning] = useState(false);
  const [laps, setLaps] = useState<LapTime[]>([]);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const startTimeRef = useRef<number>(0);
  const lastLapTimeRef = useRef<number>(0);

  useEffect(() => {
    if (isRunning) {
      startTimeRef.current = Date.now() - time;
      intervalRef.current = setInterval(() => {
        setTime(Date.now() - startTimeRef.current);
      }, 10);
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
  }, [isRunning, time]);

  const formatTime = (milliseconds: number, showMilliseconds = true) => {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const ms = Math.floor((milliseconds % 1000) / 10);
    
    if (showMilliseconds) {
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${ms.toString().padStart(2, '0')}`;
    } else {
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
  };

  const handleStart = () => {
    setIsRunning(!isRunning);
  };

  const handleLap = () => {
    if (isRunning && time > 0) {
      const lapTime = time - lastLapTimeRef.current;
      const newLap: LapTime = {
        id: laps.length + 1,
        time: time,
        lapTime: lapTime
      };
      setLaps(prev => [newLap, ...prev]);
      lastLapTimeRef.current = time;
    }
  };

  const handleReset = () => {
    setIsRunning(false);
    setTime(0);
    setLaps([]);
    lastLapTimeRef.current = 0;
  };

  const getBestAndWorstLap = () => {
    if (laps.length < 2) return { best: null, worst: null };
    
    const lapTimes = laps.map(lap => lap.lapTime);
    const bestTime = Math.min(...lapTimes);
    const worstTime = Math.max(...lapTimes);
    
    return {
      best: laps.find(lap => lap.lapTime === bestTime)?.id || null,
      worst: laps.find(lap => lap.lapTime === worstTime)?.id || null
    };
  };

  const { best, worst } = getBestAndWorstLap();

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          在线秒表
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          精确计时，记录每一个重要时刻
        </p>
      </div>

      {/* Stopwatch Display */}
      <div className="text-center">
        <div className={`text-6xl md:text-8xl font-mono font-bold mb-8 transition-colors duration-300 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          {formatTime(time)}
        </div>

        {/* Control Buttons */}
        <div className="flex justify-center space-x-4 mb-8">
          <button
            onClick={handleStart}
            className={`flex items-center space-x-2 px-8 py-4 rounded-lg font-medium transition-all duration-300 transform hover:scale-105 ${
              isRunning
                ? 'bg-red-500 hover:bg-red-600 text-white'
                : 'bg-green-500 hover:bg-green-600 text-white'
            }`}
          >
            {isRunning ? <Pause className="w-6 h-6" /> : <Play className="w-6 h-6" />}
            <span className="text-lg">{isRunning ? '暂停' : '开始'}</span>
          </button>

          <button
            onClick={isRunning ? handleLap : handleReset}
            disabled={!isRunning && time === 0}
            className={`flex items-center space-x-2 px-8 py-4 rounded-lg font-medium transition-all duration-300 transform hover:scale-105 ${
              !isRunning && time === 0
                ? theme === 'dark' 
                  ? 'bg-gray-800 text-gray-600 cursor-not-allowed'
                  : 'bg-gray-200 text-gray-400 cursor-not-allowed'
                : isRunning
                  ? 'bg-blue-500 hover:bg-blue-600 text-white'
                  : 'bg-orange-500 hover:bg-orange-600 text-white'
            }`}
          >
            {isRunning ? <Flag className="w-6 h-6" /> : <RotateCcw className="w-6 h-6" />}
            <span className="text-lg">{isRunning ? '计次' : '重置'}</span>
          </button>
        </div>
      </div>

      {/* Lap Times */}
      {laps.length > 0 && (
        <div className={`rounded-lg border p-6 ${
          theme === 'dark'
            ? 'bg-gray-800 border-gray-700'
            : 'bg-white border-gray-200'
        }`}>
          <h3 className={`text-lg font-semibold mb-4 flex items-center ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            <Flag className="w-5 h-5 mr-2" />
            计次记录
          </h3>
          
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {laps.map((lap) => (
              <div
                key={lap.id}
                className={`flex justify-between items-center p-3 rounded-lg transition-colors duration-200 ${
                  lap.id === best
                    ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
                    : lap.id === worst
                      ? 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'
                      : theme === 'dark'
                        ? 'bg-gray-700 hover:bg-gray-600'
                        : 'bg-gray-50 hover:bg-gray-100'
                }`}
              >
                <div className="flex items-center space-x-4">
                  <span className={`w-12 text-center font-semibold ${
                    lap.id === best
                      ? 'text-green-600 dark:text-green-400'
                      : lap.id === worst
                        ? 'text-red-600 dark:text-red-400'
                        : theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
                  }`}>
                    #{lap.id}
                  </span>
                  <div className="flex space-x-6">
                    <div>
                      <span className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                        计次时间: 
                      </span>
                      <span className={`font-mono text-lg ml-2 ${
                        lap.id === best
                          ? 'text-green-600 dark:text-green-400 font-bold'
                          : lap.id === worst
                            ? 'text-red-600 dark:text-red-400 font-bold'
                            : theme === 'dark' ? 'text-white' : 'text-gray-900'
                      }`}>
                        {formatTime(lap.lapTime)}
                      </span>
                    </div>
                    <div>
                      <span className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                        总时间: 
                      </span>
                      <span className={`font-mono text-lg ml-2 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                        {formatTime(lap.time)}
                      </span>
                    </div>
                  </div>
                </div>
                
                {lap.id === best && (
                  <span className="text-xs px-2 py-1 rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                    最快
                  </span>
                )}
                {lap.id === worst && (
                  <span className="text-xs px-2 py-1 rounded-full bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200">
                    最慢
                  </span>
                )}
              </div>
            ))}
          </div>

          {/* Statistics */}
          {laps.length > 1 && (
            <div className={`mt-4 pt-4 border-t grid grid-cols-3 gap-4 text-center ${
              theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
            }`}>
              <div>
                <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                  平均计次
                </div>
                <div className={`font-mono text-lg font-bold ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
                  {formatTime(laps.reduce((sum, lap) => sum + lap.lapTime, 0) / laps.length, false)}
                </div>
              </div>
              <div>
                <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                  最快计次
                </div>
                <div className="font-mono text-lg font-bold text-green-600 dark:text-green-400">
                  {formatTime(Math.min(...laps.map(lap => lap.lapTime)), false)}
                </div>
              </div>
              <div>
                <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-500'}`}>
                  最慢计次
                </div>
                <div className="font-mono text-lg font-bold text-red-600 dark:text-red-400">
                  {formatTime(Math.max(...laps.map(lap => lap.lapTime)), false)}
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};