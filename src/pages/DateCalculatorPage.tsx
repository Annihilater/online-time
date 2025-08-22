import React, { useState } from 'react';
import { Calculator, Calendar, ArrowRight } from 'lucide-react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { 
  format, 
  differenceInDays, 
  differenceInMonths, 
  differenceInYears,
  addDays,
  addMonths,
  addYears,
  isValid,
  parseISO
} from 'date-fns';

export const DateCalculatorPage: React.FC = () => {
  const { theme } = useAlarmStore();
  const [calculatorType, setCalculatorType] = useState<'difference' | 'add' | 'subtract'>('difference');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [baseDate, setBaseDate] = useState('');
  const [yearsToAdd, setYearsToAdd] = useState('0');
  const [monthsToAdd, setMonthsToAdd] = useState('0');
  const [daysToAdd, setDaysToAdd] = useState('0');

  const calculateDateDifference = () => {
    if (!startDate || !endDate) return null;
    
    const start = parseISO(startDate);
    const end = parseISO(endDate);
    
    if (!isValid(start) || !isValid(end)) return null;

    const days = Math.abs(differenceInDays(end, start));
    const months = Math.abs(differenceInMonths(end, start));
    const years = Math.abs(differenceInYears(end, start));
    
    return {
      days,
      months,
      years,
      weeks: Math.floor(days / 7),
      hours: days * 24,
      minutes: days * 24 * 60,
    };
  };

  const calculateAddSubtract = () => {
    if (!baseDate) return null;
    
    const base = parseISO(baseDate);
    if (!isValid(base)) return null;

    const years = parseInt(yearsToAdd) || 0;
    const months = parseInt(monthsToAdd) || 0;
    const days = parseInt(daysToAdd) || 0;

    let result = base;
    
    if (calculatorType === 'add') {
      if (years !== 0) result = addYears(result, years);
      if (months !== 0) result = addMonths(result, months);
      if (days !== 0) result = addDays(result, days);
    } else {
      if (years !== 0) result = addYears(result, -years);
      if (months !== 0) result = addMonths(result, -months);
      if (days !== 0) result = addDays(result, -days);
    }

    return result;
  };

  const difference = calculateDateDifference();
  const addSubtractResult = calculateAddSubtract();

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          日期计算器
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          计算日期间隔、添加或减去时间
        </p>
      </div>

      {/* Calculator Type Selector */}
      <div className="flex justify-center mb-8">
        <div className={`flex rounded-lg p-1 ${
          theme === 'dark' ? 'bg-gray-700' : 'bg-gray-100'
        }`}>
          <button
            onClick={() => setCalculatorType('difference')}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
              calculatorType === 'difference'
                ? 'bg-blue-500 text-white'
                : theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            日期差异
          </button>
          <button
            onClick={() => setCalculatorType('add')}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
              calculatorType === 'add'
                ? 'bg-blue-500 text-white'
                : theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            添加时间
          </button>
          <button
            onClick={() => setCalculatorType('subtract')}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
              calculatorType === 'subtract'
                ? 'bg-blue-500 text-white'
                : theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            减去时间
          </button>
        </div>
      </div>

      {/* Date Difference Calculator */}
      {calculatorType === 'difference' && (
        <div className={`p-6 rounded-lg border ${
          theme === 'dark'
            ? 'bg-gray-800 border-gray-700'
            : 'bg-white border-gray-200'
        }`}>
          <h2 className={`text-xl font-semibold mb-6 flex items-center ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            <Calculator className="w-5 h-5 mr-2" />
            计算两个日期之间的差异
          </h2>

          <div className="grid md:grid-cols-2 gap-6 mb-6">
            <div>
              <label className={`block text-sm font-medium mb-2 ${
                theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
              }`}>
                开始日期
              </label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
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
                结束日期
              </label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                    theme === 'dark'
                      ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                      : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                  } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                />
              </div>
            </div>
          </div>

          {difference && (
            <div className={`p-6 rounded-lg ${
              theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
            }`}>
              <h3 className={`text-lg font-semibold mb-4 ${
                theme === 'dark' ? 'text-white' : 'text-gray-900'
              }`}>
                计算结果
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-blue-400' : 'text-blue-600'}`}>
                    {difference.days.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    天
                  </div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-green-400' : 'text-green-600'}`}>
                    {difference.weeks.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    周
                  </div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-purple-400' : 'text-purple-600'}`}>
                    {difference.months.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    月
                  </div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-orange-400' : 'text-orange-600'}`}>
                    {difference.years.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    年
                  </div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-red-400' : 'text-red-600'}`}>
                    {difference.hours.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    小时
                  </div>
                </div>
                <div className="text-center">
                  <div className={`text-2xl font-bold ${theme === 'dark' ? 'text-pink-400' : 'text-pink-600'}`}>
                    {difference.minutes.toLocaleString()}
                  </div>
                  <div className={`text-sm ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    分钟
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Add/Subtract Calculator */}
      {(calculatorType === 'add' || calculatorType === 'subtract') && (
        <div className={`p-6 rounded-lg border ${
          theme === 'dark'
            ? 'bg-gray-800 border-gray-700'
            : 'bg-white border-gray-200'
        }`}>
          <h2 className={`text-xl font-semibold mb-6 flex items-center ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>
            <Calculator className="w-5 h-5 mr-2" />
            {calculatorType === 'add' ? '日期添加时间' : '日期减去时间'}
          </h2>

          <div className="grid md:grid-cols-2 gap-6 mb-6">
            <div>
              <label className={`block text-sm font-medium mb-2 ${
                theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
              }`}>
                基础日期
              </label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="date"
                  value={baseDate}
                  onChange={(e) => setBaseDate(e.target.value)}
                  className={`w-full pl-10 pr-4 py-3 rounded-lg border transition-colors duration-300 ${
                    theme === 'dark'
                      ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                      : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                  } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className={`block text-sm font-medium mb-2 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    年
                  </label>
                  <input
                    type="number"
                    value={yearsToAdd}
                    onChange={(e) => setYearsToAdd(e.target.value)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                <div>
                  <label className={`block text-sm font-medium mb-2 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    月
                  </label>
                  <input
                    type="number"
                    value={monthsToAdd}
                    onChange={(e) => setMonthsToAdd(e.target.value)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
                <div>
                  <label className={`block text-sm font-medium mb-2 ${
                    theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    天
                  </label>
                  <input
                    type="number"
                    value={daysToAdd}
                    onChange={(e) => setDaysToAdd(e.target.value)}
                    className={`w-full px-3 py-2 rounded-lg border transition-colors duration-300 ${
                      theme === 'dark'
                        ? 'bg-gray-700 border-gray-600 text-white focus:border-blue-500'
                        : 'bg-white border-gray-300 text-gray-900 focus:border-blue-500'
                    } focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50`}
                  />
                </div>
              </div>
            </div>
          </div>

          {addSubtractResult && baseDate && (
            <div className={`p-6 rounded-lg ${
              theme === 'dark' ? 'bg-gray-700' : 'bg-gray-50'
            }`}>
              <h3 className={`text-lg font-semibold mb-4 ${
                theme === 'dark' ? 'text-white' : 'text-gray-900'
              }`}>
                计算结果
              </h3>
              <div className="flex items-center justify-center space-x-4">
                <div className="text-center">
                  <div className={`text-sm mb-1 ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    基础日期
                  </div>
                  <div className={`text-xl font-bold ${theme === 'dark' ? 'text-white' : 'text-gray-900'}`}>
                    {format(parseISO(baseDate), 'yyyy-MM-dd')}
                  </div>
                </div>
                <ArrowRight className={`w-8 h-8 ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`} />
                <div className="text-center">
                  <div className={`text-sm mb-1 ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    结果日期
                  </div>
                  <div className={`text-xl font-bold ${
                    calculatorType === 'add' 
                      ? theme === 'dark' ? 'text-green-400' : 'text-green-600'
                      : theme === 'dark' ? 'text-red-400' : 'text-red-600'
                  }`}>
                    {format(addSubtractResult, 'yyyy-MM-dd')}
                  </div>
                  <div className={`text-sm mt-1 ${theme === 'dark' ? 'text-gray-400' : 'text-gray-600'}`}>
                    {format(addSubtractResult, 'EEEE')}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};