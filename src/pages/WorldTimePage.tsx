import React, { useState } from 'react';
import { Globe, Plus, X } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { format } from 'date-fns';

interface TimeZoneInfo {
  id: string;
  name: string;
  timezone: string;
  country: string;
  time?: Date;
}

const POPULAR_TIMEZONES: TimeZoneInfo[] = [
  { id: '1', name: '北京', timezone: 'Asia/Shanghai', country: '中国' },
  { id: '2', name: '东京', timezone: 'Asia/Tokyo', country: '日本' },
  { id: '3', name: '纽约', timezone: 'America/New_York', country: '美国' },
  { id: '4', name: '伦敦', timezone: 'Europe/London', country: '英国' },
  { id: '5', name: '巴黎', timezone: 'Europe/Paris', country: '法国' },
  { id: '6', name: '悉尼', timezone: 'Australia/Sydney', country: '澳大利亚' },
  { id: '7', name: '洛杉矶', timezone: 'America/Los_Angeles', country: '美国' },
  { id: '8', name: '迪拜', timezone: 'Asia/Dubai', country: '阿联酋' },
  { id: '9', name: '新加坡', timezone: 'Asia/Singapore', country: '新加坡' },
  { id: '10', name: '莫斯科', timezone: 'Europe/Moscow', country: '俄罗斯' },
  { id: '11', name: '孟买', timezone: 'Asia/Kolkata', country: '印度' },
  { id: '12', name: '开罗', timezone: 'Africa/Cairo', country: '埃及' },
];

export const WorldTimePage: React.FC = () => {
  const { theme, currentTime } = useAlarmStore();
  const [selectedTimezones, setSelectedTimezones] = useState<TimeZoneInfo[]>([
    POPULAR_TIMEZONES[0], // Beijing
    POPULAR_TIMEZONES[2], // New York
    POPULAR_TIMEZONES[3], // London
    POPULAR_TIMEZONES[1], // Tokyo
  ]);
  const [showAddModal, setShowAddModal] = useState(false);

  const getTimeInTimezone = (timezone: string): Date => {
    return new Date(currentTime.toLocaleString("en-US", {timeZone: timezone}));
  };

  const getTimezoneOffset = (timezone: string): string => {
    const timeInTimezone = getTimeInTimezone(timezone);
    const offset = timeInTimezone.getTimezoneOffset();
    const hours = Math.floor(Math.abs(offset) / 60);
    const minutes = Math.abs(offset) % 60;
    const sign = offset <= 0 ? '+' : '-';
    return `UTC${sign}${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
  };

  const addTimezone = (timezone: TimeZoneInfo) => {
    if (!selectedTimezones.find(tz => tz.timezone === timezone.timezone)) {
      setSelectedTimezones(prev => [...prev, timezone]);
    }
    setShowAddModal(false);
  };

  const removeTimezone = (timezoneId: string) => {
    setSelectedTimezones(prev => prev.filter(tz => tz.id !== timezoneId));
  };

  const TimeZoneCard: React.FC<{ timezone: TimeZoneInfo }> = ({ timezone }) => {
    const timeInZone = getTimeInTimezone(timezone.timezone);
    const offset = getTimezoneOffset(timezone.timezone);
    const isToday = timeInZone.getDate() === currentTime.getDate();

    return (
      <div className={`relative p-6 rounded-lg border transition-all duration-200 hover:shadow-md ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700 hover:bg-gray-750'
          : 'bg-white border-gray-200 hover:bg-gray-50'
      }`}>
        <button
          onClick={() => removeTimezone(timezone.id)}
          className={`absolute top-2 right-2 p-1 rounded-full transition-colors duration-200 ${
            theme === 'dark'
              ? 'text-gray-400 hover:text-red-400 hover:bg-gray-700'
              : 'text-gray-400 hover:text-red-500 hover:bg-gray-100'
          }`}
        >
          <X className="w-4 h-4" />
        </button>

        <div className="mb-3">
          <h3 className={`text-xl font-bold ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
            {timezone.name}
          </h3>
          <p className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
            {timezone.country} • {offset}
          </p>
        </div>

        <div className={`text-4xl font-mono font-bold mb-2 ${
          theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
        }`}>
          {format(timeInZone, 'HH:mm:ss')}
        </div>

        <div className={`text-sm flex items-center justify-between ${
          theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
        }`}>
          <span>{format(timeInZone, 'yyyy-MM-dd EEEE')}</span>
          {!isToday && (
            <span className={`px-2 py-1 rounded-full text-xs ${
              timeInZone.getDate() > currentTime.getDate()
                ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                : 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
            }`}>
              {timeInZone.getDate() > currentTime.getDate() ? '明天' : '昨天'}
            </span>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          世界时间
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          查看全球不同城市的当前时间
        </p>
      </div>

      {/* Add Timezone Button */}
      <div className="flex justify-between items-center">
        <h2 className={`text-xl font-semibold ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
          已选择的时区 ({selectedTimezones.length})
        </h2>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors duration-200 transform hover:scale-105"
        >
          <Plus className="w-5 h-5" />
          <span>添加时区</span>
        </button>
      </div>

      {/* Timezone Grid */}
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {selectedTimezones.map(timezone => (
          <TimeZoneCard key={timezone.id} timezone={timezone} />
        ))}
      </div>

      {/* Add Timezone Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className={`max-w-2xl w-full max-h-[80vh] rounded-lg overflow-hidden ${
            theme === 'dark' ? 'bg-gray-800' : 'bg-white'
          }`}>
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <div className="flex items-center justify-between">
                <h3 className={`text-xl font-bold ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
                  选择时区
                </h3>
                <button
                  onClick={() => setShowAddModal(false)}
                  className={`p-2 rounded-full transition-colors duration-200 ${
                    theme === 'dark'
                      ? 'text-gray-400 hover:text-white hover:bg-gray-700'
                      : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
                  }`}
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            <div className="p-6 overflow-y-auto max-h-96">
              <div className="grid gap-3">
                {POPULAR_TIMEZONES.filter(tz => !selectedTimezones.find(selected => selected.timezone === tz.timezone)).map(timezone => (
                  <button
                    key={timezone.id}
                    onClick={() => addTimezone(timezone)}
                    className={`flex items-center justify-between p-4 rounded-lg border transition-all duration-200 hover:shadow-md ${
                      theme === 'dark'
                        ? 'bg-gray-700 border-gray-600 hover:bg-gray-600 text-white'
                        : 'bg-gray-50 border-gray-200 hover:bg-gray-100 text-gray-900'
                    }`}
                  >
                    <div className="text-left">
                      <div className="font-semibold">{timezone.name}</div>
                      <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                        {timezone.country} • {getTimezoneOffset(timezone.timezone)}
                      </div>
                    </div>
                    <div className={`text-right font-mono ${theme === 'dark' ? 'text-blue-400' : 'text-blue-600'}`}>
                      {format(getTimeInTimezone(timezone.timezone), 'HH:mm')}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Time Comparison */}
      {selectedTimezones.length > 1 && (
        <div className={`mt-8 p-6 rounded-lg ${
          theme === 'dark' ? 'bg-gray-800' : 'bg-gray-50'
        }`}>
          <h3 className={`text-lg font-semibold mb-4 flex items-center ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            <Globe className="w-5 h-5 mr-2" />
            时区对比
          </h3>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className={`border-b ${theme === 'dark' ? 'border-gray-700' : 'border-gray-200'}`}>
                  <th className={`text-left py-2 px-4 font-medium ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    城市
                  </th>
                  <th className={`text-center py-2 px-4 font-medium ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    当前时间
                  </th>
                  <th className={`text-center py-2 px-4 font-medium ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    时差
                  </th>
                </tr>
              </thead>
              <tbody>
                {selectedTimezones.map(timezone => {
                  const timeInZone = getTimeInTimezone(timezone.timezone);
                  const localTime = currentTime;
                  const diffHours = Math.round((timeInZone.getTime() - localTime.getTime()) / (1000 * 60 * 60));
                  
                  return (
                    <tr key={timezone.id} className={`border-b ${
                      theme === 'dark' ? 'border-gray-700' : 'border-gray-200'
                    }`}>
                      <td className={`py-3 px-4 ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
                        <div>
                          <div className="font-semibold">{timezone.name}</div>
                          <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                            {timezone.country}
                          </div>
                        </div>
                      </td>
                      <td className={`py-3 px-4 text-center font-mono text-lg font-bold ${
                        theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
                      }`}>
                        {format(timeInZone, 'HH:mm')}
                      </td>
                      <td className={`py-3 px-4 text-center ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>
                        {diffHours === 0 ? '本地时间' : `${diffHours > 0 ? '+' : ''}${diffHours}小时`}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};