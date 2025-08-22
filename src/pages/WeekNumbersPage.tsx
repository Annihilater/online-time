import React, { useState } from 'react';
import { Calendar, Hash } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { 
  format, 
  getWeek, 
  getISOWeek,
  startOfWeek, 
  endOfWeek,
  startOfISOWeek,
  endOfISOWeek,
  isValid,
  parseISO,
  getYear,
  startOfYear,
  endOfYear,
  eachWeekOfInterval,
} from 'date-fns';

export const WeekNumbersPage: React.FC = () => {
  const { theme, currentTime } = useAlarmStore();
  const [selectedDate, setSelectedDate] = useState(format(currentTime, 'yyyy-MM-dd'));
  const [selectedYear, setSelectedYear] = useState(currentTime.getFullYear());
  const [weekStandard, setWeekStandard] = useState<'iso' | 'us'>('iso');

  const getCurrentWeekInfo = () => {
    const date = selectedDate ? parseISO(selectedDate) : currentTime;
    if (!isValid(date)) return null;

    const isoWeek = getISOWeek(date);
    const usWeek = getWeek(date);
    const year = getYear(date);
    
    const isoWeekStart = startOfISOWeek(date);
    const isoWeekEnd = endOfISOWeek(date);
    const usWeekStart = startOfWeek(date);
    const usWeekEnd = endOfWeek(date);

    return {
      date,
      year,
      isoWeek,
      usWeek,
      isoWeekStart,
      isoWeekEnd,
      usWeekStart,
      usWeekEnd
    };
  };

  const getYearWeeks = () => {
    const yearStart = startOfYear(new Date(selectedYear, 0, 1));
    const yearEnd = endOfYear(new Date(selectedYear, 0, 1));
    
    let weeks;
    if (weekStandard === 'iso') {
      weeks = eachWeekOfInterval(
        { start: yearStart, end: yearEnd },
        { weekStartsOn: 1 } // Monday
      );
    } else {
      weeks = eachWeekOfInterval(
        { start: yearStart, end: yearEnd },
        { weekStartsOn: 0 } // Sunday
      );
    }

    return weeks.map((weekStart) => {
      const weekNum = weekStandard === 'iso' ? getISOWeek(weekStart) : getWeek(weekStart);
      const weekEnd = weekStandard === 'iso' ? endOfISOWeek(weekStart) : endOfWeek(weekStart);
      
      return {
        weekNumber: weekNum,
        startDate: weekStart,
        endDate: weekEnd,
        isCurrentWeek: selectedDate && 
          parseISO(selectedDate) >= weekStart && 
          parseISO(selectedDate) <= weekEnd
      };
    }).filter((week, idx, array) => {
      // Remove duplicate week numbers that can occur at year boundaries
      return idx === 0 || week.weekNumber !== array[idx - 1]?.weekNumber;
    });
  };

  const currentWeek = getCurrentWeekInfo();
  const yearWeeks = getYearWeeks();


  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          周数计算器
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          查看任意日期的周数，支持ISO和美国标准
        </p>
      </div>

      {/* Date Input and Week Standard */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <div className="grid md:grid-cols-3 gap-6 mb-6">
          <div>
            <label className={`block text-sm font-medium mb-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              选择日期
            </label>
            <div className="relative">
              <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                  theme === 'dark'
                    ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                    : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
              />
            </div>
          </div>

          <div>
            <label className={`block text-sm font-medium mb-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              周数标准
            </label>
            <div className={`flex rounded-lg p-1 ${
              theme === 'dark' ? 'bg-gray-700' : 'bg-gray-100'
            }`}>
              <button
                onClick={() => setWeekStandard('iso')}
                className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
                  weekStandard === 'iso'
                    ? 'bg-blue-500 text-white'
                    : theme === 'dark' 
                      ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
                }`}
              >
                ISO标准
              </button>
              <button
                onClick={() => setWeekStandard('us')}
                className={`flex-1 px-3 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
                  weekStandard === 'us'
                    ? 'bg-blue-500 text-white'
                    : theme === 'dark' 
                      ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
                }`}
              >
                美国标准
              </button>
            </div>
          </div>

          <div>
            <label className={`block text-sm font-medium mb-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              查看年份
            </label>
            <input
              type="number"
              min="1900"
              max="2100"
              value={selectedYear}
              onChange={(e) => setSelectedYear(parseInt(e.target.value) || currentTime.getFullYear())}
              className={`w-full px-3 py-3 rounded-lg border transition-colors duration-300 ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                  : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
              } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
            />
          </div>
        </div>

        {/* Current Week Info */}
        {currentWeek && (
          <div className={`p-6 rounded-lg ${
            theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
          }`}>
            <h3 className={`text-lg font-semibold mb-4 flex items-center ${
              theme === 'dark' ? 'text-white' : 'text-gray-900'
            }`}>
              <Hash className="w-5 h-5 mr-2" />
              {selectedDate === format(currentTime, 'yyyy-MM-dd') ? '今天' : '选定日期'} 的周数信息
            </h3>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h4 className={`font-semibold mb-3 ${theme === 'dark' ? 'text-blue-400' : 'text-blue-600'}`}>
                  ISO 8601 标准 (周一开始)
                </h4>
                <div className="space-y-2 text-sm">
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周数:</span>
                    <span className="font-bold">第 {currentWeek.isoWeek} 周</span>
                  </div>
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周开始:</span>
                    <span>{format(currentWeek.isoWeekStart, 'yyyy-MM-dd (EEEE)')}</span>
                  </div>
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周结束:</span>
                    <span>{format(currentWeek.isoWeekEnd, 'yyyy-MM-dd (EEEE)')}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className={`font-semibold mb-3 ${theme === 'dark' ? 'text-green-400' : 'text-green-600'}`}>
                  美国标准 (周日开始)
                </h4>
                <div className="space-y-2 text-sm">
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周数:</span>
                    <span className="font-bold">第 {currentWeek.usWeek} 周</span>
                  </div>
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周开始:</span>
                    <span>{format(currentWeek.usWeekStart, 'yyyy-MM-dd (EEEE)')}</span>
                  </div>
                  <div className={`flex justify-between ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
                    <span>周结束:</span>
                    <span>{format(currentWeek.usWeekEnd, 'yyyy-MM-dd (EEEE)')}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Year Overview */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <h3 className={`text-lg font-semibold mb-4 flex items-center ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          <Calendar className="w-5 h-5 mr-2" />
          {selectedYear} 年周数一览 ({weekStandard === 'iso' ? 'ISO标准' : '美国标准'})
        </h3>
        
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3 max-h-96 overflow-y-auto">
          {yearWeeks.map((week) => (
            <div
              key={`${week.weekNumber}-${week.startDate.getTime()}`}
              className={`p-3 rounded-lg border text-center transition-all duration-200 ${
                week.isCurrentWeek
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : theme === 'dark'
                    ? 'border-gray-600 bg-gray-700 hover:bg-gray-600'
                    : 'border-gray-200 bg-gray-50 hover:bg-gray-100'
              }`}
            >
              <div className={`font-bold text-lg ${
                week.isCurrentWeek
                  ? 'text-blue-600 dark:text-blue-400'
                  : theme === 'dark' ? 'text-white' : 'text-gray-900'
              }`}>
                W{week.weekNumber}
              </div>
              <div className={`text-xs mt-1 ${
                week.isCurrentWeek
                  ? 'text-blue-600 dark:text-blue-400'
                  : theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
              }`}>
                {format(week.startDate, 'MM/dd')} - {format(week.endDate, 'MM/dd')}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Standards Explanation */}
      <div className={`p-6 rounded-lg border ${
        theme === 'dark'
          ? 'bg-gray-800 border-gray-700'
          : 'bg-white border-gray-200'
      }`}>
        <h3 className={`text-lg font-semibold mb-4 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          周数标准说明
        </h3>
        
        <div className="grid md:grid-cols-2 gap-6 text-sm">
          <div>
            <h4 className={`font-semibold mb-2 ${theme === 'dark' ? 'text-blue-400' : 'text-blue-600'}`}>
              ISO 8601 标准
            </h4>
            <ul className={`space-y-1 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
              <li>• 每周从周一开始，到周日结束</li>
              <li>• 第1周是包含1月4日的那一周</li>
              <li>• 第1周至少有4天在新年份内</li>
              <li>• 国际标准，被大多数国家采用</li>
            </ul>
          </div>
          
          <div>
            <h4 className={`font-semibold mb-2 ${theme === 'dark' ? 'text-green-400' : 'text-green-600'}`}>
              美国标准
            </h4>
            <ul className={`space-y-1 ${theme === 'dark' ? 'text-gray-300' : 'text-gray-700'}`}>
              <li>• 每周从周日开始，到周六结束</li>
              <li>• 第1周是包含1月1日的那一周</li>
              <li>• 即使1月1日只有1天也算第1周</li>
              <li>• 主要在美国和加拿大使用</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};