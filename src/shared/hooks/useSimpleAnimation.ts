import { useRef } from 'react';

export interface UseSimpleAnimationReturn {
  ref: React.RefObject<HTMLDivElement | null>;
  animateWithSequence: () => void;
  animateWithPreset: () => void;
  addRipple: () => void;
  createParticles: () => void;
  stopAnimations: () => void;
  isDisabled: boolean;
}

export const useSimpleAnimation = (): UseSimpleAnimationReturn => {
  const ref = useRef<HTMLDivElement | null>(null);

  return {
    ref,
    animateWithSequence: () => {},
    animateWithPreset: () => {},
    addRipple: () => {},
    createParticles: () => {},
    stopAnimations: () => {},
    isDisabled: false
  };
};