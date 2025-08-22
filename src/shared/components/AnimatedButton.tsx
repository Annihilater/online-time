import React, { forwardRef } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface AnimatedButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'warning' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  icon?: React.ReactNode;
  children: React.ReactNode;
  disableAnimations?: boolean;
  pulseOnHover?: boolean;
  glowEffect?: boolean;
}

export const AnimatedButton = forwardRef<HTMLButtonElement, AnimatedButtonProps>(({
  variant = 'primary',
  size = 'md',
  loading = false,
  icon,
  children,
  disableAnimations = false,
  pulseOnHover = false,
  glowEffect = false,
  className = '',
  onClick,
  ...props
}, ref) => {
  const { theme } = useAlarmStore();
  // Animation functions placeholder
  // const addRipple = () => {};
  // const animateWithSequence = () => {};

  // Simplified ref handling
  const mergedRef = (el: HTMLButtonElement | null) => {
    if (typeof ref === 'function') {
      ref(el);
    } else if (ref) {
      ref.current = el;
    }
  };

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (!disableAnimations) {
      // addRipple(e);
      // animateWithSequence('buttonPress', 'quick');
    }
    onClick?.(e);
  };

  const getVariantClasses = () => {
    const baseClasses = 'relative overflow-hidden transition-all duration-200';
    
    switch (variant) {
      case 'primary':
        return `${baseClasses} bg-blue-600 hover:bg-blue-700 text-white border-blue-600 hover:border-blue-700`;
      case 'secondary':
        return `${baseClasses} ${
          theme === 'dark' 
            ? 'bg-gray-700 hover:bg-gray-600 text-gray-300 border-gray-600' 
            : 'bg-gray-100 hover:bg-gray-200 text-gray-700 border-gray-300'
        }`;
      case 'danger':
        return `${baseClasses} bg-red-600 hover:bg-red-700 text-white border-red-600 hover:border-red-700`;
      case 'warning':
        return `${baseClasses} bg-yellow-500 hover:bg-yellow-600 text-white border-yellow-500 hover:border-yellow-600`;
      case 'ghost':
        return `${baseClasses} ${
          theme === 'dark'
            ? 'text-gray-300 hover:text-white hover:bg-gray-800 border-transparent'
            : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50 border-transparent'
        }`;
      default:
        return baseClasses;
    }
  };

  const getSizeClasses = () => {
    switch (size) {
      case 'sm':
        return 'px-3 py-1.5 text-sm';
      case 'lg':
        return 'px-6 py-3 text-lg';
      case 'md':
      default:
        return 'px-4 py-2 text-base';
    }
  };

  const getAnimationClasses = () => {
    let animationClasses = '';
    
    if (!disableAnimations) {
      animationClasses += ' button-lift';
      
      if (pulseOnHover) {
        animationClasses += ' pulse-hover';
      }
      
      if (glowEffect) {
        animationClasses += ' glow';
      }
    }
    
    return animationClasses;
  };

  return (
    <button
      ref={mergedRef}
      onClick={handleClick}
      className={`
        btn
        ${getVariantClasses()}
        ${getSizeClasses()}
        ${getAnimationClasses()}
        ${loading ? 'opacity-70 cursor-not-allowed' : ''}
        ${className}
      `.trim()}
      disabled={loading || props.disabled}
      {...props}
    >
      <span className="flex items-center justify-center gap-2">
        {loading ? (
          <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
        ) : icon ? (
          <span className="inline-flex">{icon}</span>
        ) : null}
        <span>{children}</span>
      </span>
      
      {/* Glow effect overlay */}
      {glowEffect && !disableAnimations && (
        <div className="absolute inset-0 rounded-inherit bg-gradient-to-r from-transparent via-white/20 to-transparent transform translate-x-[-100%] group-hover:animate-shimmer" />
      )}
    </button>
  );
});

AnimatedButton.displayName = 'AnimatedButton';