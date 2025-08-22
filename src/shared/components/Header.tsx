import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { 
  Clock, 
  Timer, 
  Calendar,
  StopCircle,
  Globe,
  Calculator,
  CalendarClock,
  Hash,
  Settings,
  Menu,
  X
} from 'lucide-react';
import { useState } from 'react';

interface HeaderProps {
  onOpenSettings: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenSettings }) => {
  const { theme, currentTime } = useAlarmStore();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navigationItems = [
    { path: '/', label: '在线闹钟', icon: Clock, color: 'text-blue-500' },
    { path: '/timer', label: '在线定时器', icon: Timer, color: 'text-green-500' },
    { path: '/countdown', label: '在线倒数', icon: Calendar, color: 'text-purple-500' },
    { path: '/stopwatch', label: '在线秒表', icon: StopCircle, color: 'text-orange-500' },
    { path: '/clock', label: '在线时钟', icon: Clock, color: 'text-red-500' },
    { path: '/world-time', label: '世界时间', icon: Globe, color: 'text-cyan-500' },
    { path: '/date-calculator', label: '日期计算器', icon: Calculator, color: 'text-indigo-500' },
    { path: '/hours-calculator', label: '小时数计算器', icon: CalendarClock, color: 'text-pink-500' },
    { path: '/week-numbers', label: '周数', icon: Hash, color: 'text-yellow-600' },
  ];

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  return (
    <header className={`border-b transition-colors duration-300 sticky top-0 z-40 backdrop-blur-sm ${
      theme === 'dark'
        ? 'bg-gray-800/80 border-gray-700'
        : 'bg-white/80 border-gray-200'
    }`}>
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Current Time */}
          <div className="flex items-center space-x-4">
            <div className={`font-bold text-xl transition-colors duration-300 ${
              theme === 'dark' ? 'text-white' : 'text-gray-900'
            }`}>
              Online Time
            </div>
            <div className={`hidden md:block text-sm font-mono px-3 py-1 rounded-full transition-colors duration-300 ${
              theme === 'dark' 
                ? 'bg-gray-700 text-gray-300' 
                : 'bg-gray-100 text-gray-700'
            }`}>
              {currentTime.toLocaleTimeString()}
            </div>
          </div>

          {/* Desktop Navigation */}
          <nav className="hidden lg:flex items-center space-x-1">
            {navigationItems.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) => `
                  flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200
                  ${isActive 
                    ? `${item.color} bg-opacity-10 ${item.color.replace('text-', 'bg-')}`
                    : theme === 'dark' 
                      ? 'text-gray-300 hover:text-white hover:bg-gray-700'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                  }
                `}
              >
                <item.icon className="w-4 h-4" />
                <span className="hidden xl:inline">{item.label}</span>
              </NavLink>
            ))}
          </nav>

          {/* Mobile Menu Button & Settings */}
          <div className="flex items-center space-x-2">
            <button
              onClick={onOpenSettings}
              className={`p-2 rounded-lg transition-colors duration-200 ${
                theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-700'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
              aria-label="Settings"
            >
              <Settings className="w-5 h-5" />
            </button>
            
            <button
              onClick={toggleMobileMenu}
              className={`lg:hidden p-2 rounded-lg transition-colors duration-200 ${
                theme === 'dark' 
                  ? 'text-gray-300 hover:text-white hover:bg-gray-700'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
              aria-label="Toggle menu"
            >
              {isMobileMenuOpen ? (
                <X className="w-5 h-5" />
              ) : (
                <Menu className="w-5 h-5" />
              )}
            </button>
          </div>
        </div>

        {/* Mobile Navigation */}
        {isMobileMenuOpen && (
          <div className={`lg:hidden py-4 border-t transition-colors duration-300 ${
            theme === 'dark' ? 'border-gray-700' : 'border-gray-200'
          }`}>
            <nav className="grid grid-cols-2 gap-2">
              {navigationItems.map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  onClick={() => setIsMobileMenuOpen(false)}
                  className={({ isActive }) => `
                    flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200
                    ${isActive 
                      ? `${item.color} bg-opacity-10 ${item.color.replace('text-', 'bg-')}`
                      : theme === 'dark' 
                        ? 'text-gray-300 hover:text-white hover:bg-gray-700'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                    }
                  `}
                >
                  <item.icon className="w-5 h-5 flex-shrink-0" />
                  <span>{item.label}</span>
                </NavLink>
              ))}
            </nav>
          </div>
        )}
      </div>
    </header>
  );
};