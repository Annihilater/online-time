import React from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  color?: string;
  type?: 'spinner' | 'dots' | 'pulse' | 'wave' | 'clock';
  label?: string;
  className?: string;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  color,
  type = 'spinner',
  label,
  className = ''
}) => {
  const { theme } = useAlarmStore();

  const getSizeClass = () => {
    switch (size) {
      case 'sm': return 'w-4 h-4';
      case 'md': return 'w-6 h-6';
      case 'lg': return 'w-8 h-8';
      case 'xl': return 'w-12 h-12';
      default: return 'w-6 h-6';
    }
  };

  const getColorClass = () => {
    if (color) return color;
    return theme === 'dark' ? 'text-white' : 'text-gray-700';
  };

  const SpinnerComponent = () => {
    switch (type) {
      case 'dots':
        return (
          <div className={`flex space-x-1 ${getSizeClass()}`}>
            <div className={`w-1 h-1 ${getColorClass()} bg-current rounded-full animate-pulse`}></div>
            <div className={`w-1 h-1 ${getColorClass()} bg-current rounded-full animate-pulse`} style={{ animationDelay: '0.2s' }}></div>
            <div className={`w-1 h-1 ${getColorClass()} bg-current rounded-full animate-pulse`} style={{ animationDelay: '0.4s' }}></div>
          </div>
        );

      case 'pulse':
        return (
          <div className={`${getSizeClass()} ${getColorClass()} bg-current rounded-full animate-pulse`}></div>
        );

      case 'wave':
        return (
          <div className="flex items-end space-x-1">
            <div className={`w-1 ${getSizeClass().split(' ')[1]} ${getColorClass()} bg-current animate-bounce`}></div>
            <div className={`w-1 ${getSizeClass().split(' ')[1]} ${getColorClass()} bg-current animate-bounce`} style={{ animationDelay: '0.1s' }}></div>
            <div className={`w-1 ${getSizeClass().split(' ')[1]} ${getColorClass()} bg-current animate-bounce`} style={{ animationDelay: '0.2s' }}></div>
            <div className={`w-1 ${getSizeClass().split(' ')[1]} ${getColorClass()} bg-current animate-bounce`} style={{ animationDelay: '0.3s' }}></div>
          </div>
        );

      case 'clock':
        return (
          <div className={`${getSizeClass()} border-2 border-current ${getColorClass()} rounded-full relative`}>
            <div
              className="absolute top-1/2 left-1/2 w-1/3 h-0.5 bg-current transform -translate-x-1/2 -translate-y-1/2 origin-left animate-spin"
              style={{ animationDuration: '2s' }}
            ></div>
            <div
              className="absolute top-1/2 left-1/2 w-1/4 h-0.5 bg-current transform -translate-x-1/2 -translate-y-1/2 origin-left animate-spin"
              style={{ animationDuration: '12s' }}
            ></div>
          </div>
        );

      case 'spinner':
      default:
        return (
          <div className={`${getSizeClass()} border-2 border-current ${getColorClass()} border-t-transparent rounded-full animate-spin`}></div>
        );
    }
  };

  return (
    <div className={`inline-flex flex-col items-center justify-center ${className}`}>
      <SpinnerComponent />
      {label && (
        <span className={`mt-2 text-sm ${getColorClass()}`}>
          {label}
        </span>
      )}
    </div>
  );
};

// Custom CSS animations that can be added to index.css
export const loadingSpinnerStyles = `
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.animate-shimmer {
  animation: shimmer 1.5s infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-10px); }
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

@keyframes glow {
  0%, 100% { box-shadow: 0 0 5px rgba(59, 130, 246, 0.3); }
  50% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.6); }
}

.animate-glow {
  animation: glow 2s ease-in-out infinite;
}
`;