import React, { useState } from 'react';
import { Clock, Calculator, Plus, X } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface TimeEntry {
  id: string;
  startTime: string;
  endTime: string;
  breakMinutes: number;
  description: string;
}

export const HoursCalculatorPage: React.FC = () => {
  const { theme } = useAlarmStore();
  const [entries, setEntries] = useState<TimeEntry[]>([
    {
      id: '1',
      startTime: '09:00',
      endTime: '17:00',
      breakMinutes: 60,
      description: '工作日'
    }
  ]);
  const [hourlyRate, setHourlyRate] = useState('');

  const generateId = () => Math.random().toString(36).substr(2, 9);

  const addEntry = () => {
    const newEntry: TimeEntry = {
      id: generateId(),
      startTime: '09:00',
      endTime: '17:00',
      breakMinutes: 0,
      description: ''
    };
    setEntries([...entries, newEntry]);
  };

  const removeEntry = (id: string) => {
    setEntries(entries.filter(entry => entry.id !== id));
  };

  const updateEntry = (id: string, field: keyof TimeEntry, value: string | number) => {
    setEntries(entries.map(entry => 
      entry.id === id ? { ...entry, [field]: value } : entry
    ));
  };

  const calculateHoursForEntry = (entry: TimeEntry): number => {
    if (!entry.startTime || !entry.endTime) return 0;
    
    const [startHour, startMinute] = entry.startTime.split(':').map(Number);
    const [endHour, endMinute] = entry.endTime.split(':').map(Number);
    
    const startTotalMinutes = startHour * 60 + startMinute;
    let endTotalMinutes = endHour * 60 + endMinute;
    
    // Handle overnight shifts
    if (endTotalMinutes <= startTotalMinutes) {
      endTotalMinutes += 24 * 60;
    }
    
    const workMinutes = endTotalMinutes - startTotalMinutes - (entry.breakMinutes || 0);
    return Math.max(0, workMinutes / 60);
  };

  const totalHours = entries.reduce((sum, entry) => sum + calculateHoursForEntry(entry), 0);
  const totalMinutes = Math.round((totalHours % 1) * 60);
  const totalWholeHours = Math.floor(totalHours);
  const totalPay = hourlyRate ? totalHours * parseFloat(hourlyRate) : 0;

  const formatTime = (hours: number): string => {
    const wholeHours = Math.floor(hours);
    const minutes = Math.round((hours % 1) * 60);
    return `${wholeHours}小时 ${minutes}分钟`;
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          小时数计算器
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          计算工作时间、加班时间和总薪资
        </p>
      </div>

      {/* Time Entries */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <div className="flex items-center justify-between mb-6">
          <h2 className={`text-xl font-semibold flex items-center ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            <Clock className="w-5 h-5 mr-2" />
            时间记录
          </h2>
          <button
            onClick={addEntry}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors duration-200 transform hover:scale-105"
          >
            <Plus className="w-4 h-4" />
            <span>添加记录</span>
          </button>
        </div>

        <div className="space-y-4">
          {entries.map((entry, index) => (
            <div key={entry.id} className={`p-4 rounded-lg border ${
              theme === 'dark'
                ? 'bg-gray-700 border-gray-600'
                : 'bg-gray-50 border-gray-200'
            }`}>
              <div className="flex items-center justify-between mb-3">
                <span className={`font-medium ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
                  记录 #{index + 1}
                </span>
                {entries.length > 1 && (
                  <button
                    onClick={() => removeEntry(entry.id)}
                    className={`p-1 rounded-full transition-colors duration-200 ${
                      theme === 'dark'
                        ? 'text-gray-400 hover:text-red-400 hover:bg-gray-600'
                        : 'text-gray-400 hover:text-red-500 hover:bg-gray-200'
                    }`}
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>
              
              <div className="grid md:grid-cols-5 gap-4">
                <div>
                  <label className={`block text-sm font-medium mb-1 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    开始时间
                  </label>
                  <input
                    type="time"
                    value={entry.startTime}
                    onChange={(e) => updateEntry(entry.id, 'startTime', e.target.value)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-600 border-gray-500 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                
                <div>
                  <label className={`block text-sm font-medium mb-1 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    结束时间
                  </label>
                  <input
                    type="time"
                    value={entry.endTime}
                    onChange={(e) => updateEntry(entry.id, 'endTime', e.target.value)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-600 border-gray-500 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                
                <div>
                  <label className={`block text-sm font-medium mb-1 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    休息时间 (分钟)
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={entry.breakMinutes}
                    onChange={(e) => updateEntry(entry.id, 'breakMinutes', parseInt(e.target.value) || 0)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-600 border-gray-500 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                
                <div>
                  <label className={`block text-sm font-medium mb-1 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    描述
                  </label>
                  <input
                    type="text"
                    value={entry.description}
                    onChange={(e) => updateEntry(entry.id, 'description', e.target.value)}
                    placeholder="可选"
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-600 border-gray-500 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                
                <div className="flex items-end">
                  <div className={`px-3 py-2 rounded-lg ${
                    theme === 'dark' ? 'bg-blue-900 text-blue-200' : 'bg-blue-100 text-blue-800'
                  } text-sm font-medium`}>
                    {formatTime(calculateHoursForEntry(entry))}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Hourly Rate */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <h3 className={`text-lg font-semibold mb-4 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          薪资计算 (可选)
        </h3>
        <div className="max-w-sm">
          <label className={`block text-sm font-medium mb-2 ${
            theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
          }`}>
            每小时薪资 (¥)
          </label>
          <input
            type="number"
            min="0"
            step="0.01"
            value={hourlyRate}
            onChange={(e) => setHourlyRate(e.target.value)}
            placeholder="输入每小时薪资..."
            className={`w-full px-3 py-3 rounded-lg border transition-colors duration-300 ${
              theme === 'dark'
                ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
            } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
          />
        </div>
      </div>

      {/* Results */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <h3 className={`text-lg font-semibold mb-6 flex items-center ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          <Calculator className="w-5 h-5 mr-2" />
          计算结果
        </h3>

        <div className="grid md:grid-cols-3 gap-6">
          <div className={`p-6 rounded-lg text-center ${
            theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
          }`}>
            <div className={`text-3xl font-bold mb-2 ${
              theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
            }`}>
              {totalWholeHours}
            </div>
            <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
              总小时数
            </div>
            <div className={`text-xs mt-1 ${theme === 'dark' ? 'text-gray-500' : 'text-gray-500'}`}>
              (含 {totalMinutes} 分钟)
            </div>
          </div>

          <div className={`p-6 rounded-lg text-center ${
            theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
          }`}>
            <div className={`text-3xl font-bold mb-2 ${
              theme === 'dark' ? 'text-green-400' : 'text-green-600'
            }`}>
              {totalHours.toFixed(2)}
            </div>
            <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
              小时数 (小数)
            </div>
            <div className={`text-xs mt-1 ${theme === 'dark' ? 'text-gray-500' : 'text-gray-500'}`}>
              精确计算
            </div>
          </div>

          <div className={`p-6 rounded-lg text-center ${
            theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
          }`}>
            <div className={`text-3xl font-bold mb-2 ${
              hourlyRate 
                ? theme === 'dark' ? 'text-yellow-400' : 'text-yellow-600'
                : theme === 'dark' ? 'text-gray-500' : 'text-gray-400'
            }`}>
              {hourlyRate ? `¥${totalPay.toFixed(2)}` : '¥--'}
            </div>
            <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
              总薪资
            </div>
            <div className={`text-xs mt-1 ${theme === 'dark' ? 'text-gray-500' : 'text-gray-500'}`}>
              {hourlyRate ? `¥${hourlyRate}/小时` : '设置时薪'}
            </div>
          </div>
        </div>

        {/* Detailed Breakdown */}
        {entries.length > 1 && (
          <div className="mt-6">
            <h4 className={`text-md font-semibold mb-3 ${
              theme === 'dark' ? 'text-white' : 'text-gray-900'
            }`}>
              详细分解
            </h4>
            <div className={`overflow-hidden rounded-lg border ${
              theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
            }`}>
              <table className="w-full">
                <thead className={theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'}>
                  <tr>
                    <th className={`px-4 py-3 text-left text-sm font-medium ${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>
                      记录
                    </th>
                    <th className={`px-4 py-3 text-center text-sm font-medium ${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>
                      时间段
                    </th>
                    <th className={`px-4 py-3 text-center text-sm font-medium ${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>
                      休息
                    </th>
                    <th className={`px-4 py-3 text-right text-sm font-medium ${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>
                      工作时长
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {entries.map((entry, index) => (
                    <tr key={entry.id} className={`border-t ${
                      theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
                    }`}>
                      <td className={`px-4 py-3 text-sm ${
                        theme === 'dark' ? 'text-white' : 'text-gray-900'
                      }`}>
                        {entry.description || `记录 #${index + 1}`}
                      </td>
                      <td className={`px-4 py-3 text-sm text-center ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>
                        {entry.startTime} - {entry.endTime}
                      </td>
                      <td className={`px-4 py-3 text-sm text-center ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>
                        {entry.breakMinutes}分钟
                      </td>
                      <td className={`px-4 py-3 text-sm text-right font-medium ${
                        theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
                      }`}>
                        {formatTime(calculateHoursForEntry(entry))}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};