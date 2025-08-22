import { useRef } from 'react';

export interface UseAnimationOptions {
  disabled?: boolean;
  onComplete?: () => void;
}

export const useAnimation = (options: UseAnimationOptions = {}) => {
  const ref = useRef<HTMLDivElement>(null);
  
  return {
    ref,
    animateWithSequence: () => {},
    animateWithPreset: () => {},
    addRipple: () => {},
    createParticles: () => {},
    stopAnimations: () => {},
    isDisabled: options.disabled || false
  };
};

export const useButtonAnimation = useAnimation;
export const useListItemAnimation = useAnimation;
export const useModalAnimation = useAnimation;
export const useClockAnimation = useAnimation;
export const useParticleAnimation = useAnimation;