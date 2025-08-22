import React, { useState, useEffect } from 'react';
import { Calendar, Clock, Target } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { format, differenceInSeconds } from 'date-fns';

export const CountdownPage: React.FC = () => {
  const { theme } = useAlarmStore();
  const [targetDate, setTargetDate] = useState('');
  const [targetTime, setTargetTime] = useState('');
  const [eventTitle, setEventTitle] = useState('');
  const [timeRemaining, setTimeRemaining] = useState<{
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
    total: number;
  } | null>(null);

  useEffect(() => {
    if (!targetDate || !targetTime) return;

    const interval = setInterval(() => {
      const now = new Date();
      const target = new Date(`${targetDate}T${targetTime}`);
      
      if (target > now) {
        const totalSeconds = differenceInSeconds(target, now);
        const days = Math.floor(totalSeconds / (24 * 3600));
        const hours = Math.floor((totalSeconds % (24 * 3600)) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;

        setTimeRemaining({
          days,
          hours,
          minutes,
          seconds,
          total: totalSeconds
        });
      } else {
        setTimeRemaining({
          days: 0,
          hours: 0,
          minutes: 0,
          seconds: 0,
          total: 0
        });
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [targetDate, targetTime]);

  const presetEvents = [
    {
      title: '午夜',
      date: new Date().toISOString().split('T')[0],
      time: '23:59'
    },
    {
      title: '新年',
      date: `${new Date().getFullYear() + 1}-01-01`,
      time: '00:00'
    },
    {
      title: '春节',
      date: '2025-01-29',
      time: '00:00'
    },
    {
      title: '情人节',
      date: '2025-02-14',
      time: '00:00'
    },
    {
      title: '劳动节',
      date: '2025-05-01',
      time: '00:00'
    },
    {
      title: '儿童节',
      date: '2025-06-01',
      time: '00:00'
    },
    {
      title: '中秋节',
      date: '2025-10-06',
      time: '00:00'
    },
    {
      title: '国庆节',
      date: '2025-10-01',
      time: '00:00'
    }
  ];

  const handlePresetClick = (preset: typeof presetEvents[0]) => {
    setTargetDate(preset.date);
    setTargetTime(preset.time);
    setEventTitle(preset.title);
  };

  const TimeUnit: React.FC<{ value: number; label: string; color: string }> = ({ value, label, color }) => (
    <div className={`flex flex-col items-center p-4 rounded-lg ${
      theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
    } min-w-[80px]`}>
      <div className={`text-3xl md:text-4xl font-bold ${color} font-mono`}>
        {value.toString().padStart(2, '0')}
      </div>
      <div className={`text-sm font-medium mt-1 ${
        theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
      }`}>
        {label}
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          在线倒数计时器
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          设置倒数计时器，让您不错过任何重要时刻。支持自定义日期和快速选择节日。
        </p>
      </div>

      {/* Event Setup */}
      <div className="grid md:grid-cols-2 gap-6 mb-8">
        <div>
          <label className={`block text-sm font-medium mb-2 ${
            theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
          }`}>
            事件标题
          </label>
          <div className="relative">
            <Target className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={eventTitle}
              onChange={(e) => setEventTitle(e.target.value)}
              placeholder="输入事件名称..."
              className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 text-white focus:border-purple-500'
                  : 'bg-white border-gray-300 text-gray-900 focus:border-purple-500'
              } focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-opacity-50`}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className={`block text-sm font-medium mb-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              目标日期
            </label>
            <div className="relative">
              <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="date"
                value={targetDate}
                onChange={(e) => setTargetDate(e.target.value)}
                className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-purple-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-purple-500'
                } focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-opacity-50`}
              />
            </div>
          </div>

          <div>
            <label className={`block text-sm font-medium mb-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              目标时间
            </label>
            <div className="relative">
              <Clock className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="time"
                value={targetTime}
                onChange={(e) => setTargetTime(e.target.value)}
                className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-purple-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-purple-500'
                } focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-opacity-50`}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Countdown Display */}
      {timeRemaining && eventTitle && (
        <div className={`text-center p-8 rounded-lg border-2 ${
          timeRemaining.total <= 0 
            ? 'border-red-500 bg-red-50 dark:bg-red-900/20'
            : 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
        }`}>
          <h2 className={`text-2xl font-bold mb-6 ${
            timeRemaining.total <= 0 ? 'text-red-600 dark:text-red-400' : 'text-purple-600 dark:text-purple-400'
          }`}>
            {timeRemaining.total <= 0 ? '🎉 时间到！' : `倒计时: ${eventTitle}`}
          </h2>

          {timeRemaining.total > 0 && (
            <div className="flex justify-center space-x-4 flex-wrap gap-4">
              <TimeUnit value={timeRemaining.days} label="天" color="text-purple-600 dark:text-purple-400" />
              <TimeUnit value={timeRemaining.hours} label="小时" color="text-blue-600 dark:text-blue-400" />
              <TimeUnit value={timeRemaining.minutes} label="分钟" color="text-green-600 dark:text-green-400" />
              <TimeUnit value={timeRemaining.seconds} label="秒" color="text-orange-600 dark:text-orange-400" />
            </div>
          )}
        </div>
      )}

      {/* Preset Events */}
      <div>
        <h3 className={`text-lg font-semibold mb-4 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          快速选择节日
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {presetEvents.map((preset) => (
            <button
              key={preset.title}
              onClick={() => handlePresetClick(preset)}
              className={`p-3 text-left rounded-lg border transition-all duration-200 hover:scale-105 ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 hover:bg-gray-600 text-gray-300 hover:border-purple-400'
                  : 'bg-white border-gray-200 hover:bg-purple-50 hover:border-purple-300 text-gray-700'
              }`}
            >
              <div className="font-medium text-sm">{preset.title}</div>
              <div className={`text-xs mt-1 ${
                theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
              }`}>
                {format(new Date(preset.date), 'MM月dd日')}
              </div>
            </button>
          ))}
        </div>
      </div>
      
      {/* 2025 Public Holidays */}
      <div className="mt-8">
        <h3 className={`text-lg font-semibold mb-4 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          2025年公共假期
        </h3>
        <div className={`grid grid-cols-1 md:grid-cols-2 gap-4 p-4 rounded-lg border ${
          theme === 'dark' ? 'bg-gray-700 border-gray-600' : 'bg-gray-50 border-gray-200'
        }`}>
          {[
            { name: '元旦', date: '2025-01-01' },
            { name: '春节', date: '2025-01-29 - 2025-02-04' },
            { name: '清明节', date: '2025-04-05 - 2025-04-07' },
            { name: '劳动节', date: '2025-05-01 - 2025-05-05' },
            { name: '端午节', date: '2025-05-31 - 2025-06-02' },
            { name: '中秋节', date: '2025-10-06 - 2025-10-08' },
            { name: '国庆节', date: '2025-10-01 - 2025-10-07' },
          ].map((holiday) => (
            <div key={holiday.name} className="flex justify-between items-center">
              <span className={`font-medium ${
                theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
              }`}>{holiday.name}</span>
              <span className={`text-sm ${
                theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
              }`}>{holiday.date}</span>
            </div>
          ))}
        </div>
      </div>
      
      {/* Share Function */}
      {timeRemaining && timeRemaining.total > 0 && (
        <div className="mt-6 text-center">
          <button
            onClick={() => {
              const shareText = `我正在倒计时到"${eventTitle}"，还有${timeRemaining.days}天${timeRemaining.hours}小时${timeRemaining.minutes}分钟！`;
              if (navigator.share) {
                navigator.share({ text: shareText });
              } else {
                navigator.clipboard.writeText(shareText).then(() => {
                  alert('已复制到剪贴板！');
                });
              }
            }}
            className={`px-6 py-2 rounded-lg font-medium transition-all duration-200 hover:scale-105 ${
              theme === 'dark'
                ? 'bg-purple-600 hover:bg-purple-700 text-white'
                : 'bg-purple-500 hover:bg-purple-600 text-white'
            }`}
          >
            分享倒计时
          </button>
        </div>
      )}
    </div>
  );
};