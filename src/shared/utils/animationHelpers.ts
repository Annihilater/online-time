// Animation helper utilities for enhanced user experience

export interface AnimationConfig {
  duration: number;
  easing: string;
  delay?: number;
  fillMode?: 'forwards' | 'backwards' | 'both' | 'none';
}

export const ANIMATION_PRESETS = {
  // Quick micro-interactions
  quick: { duration: 150, easing: 'cubic-bezier(0.4, 0, 0.2, 1)' },
  // Standard UI animations
  normal: { duration: 300, easing: 'cubic-bezier(0.4, 0, 0.2, 1)' },
  // Slow, emphasis animations
  slow: { duration: 500, easing: 'cubic-bezier(0.4, 0, 0.2, 1)' },
  // Bounce effect
  bounce: { duration: 600, easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)' },
  // Elastic effect
  elastic: { duration: 800, easing: 'cubic-bezier(0.175, 0.885, 0.32, 1.275)' }
} as const;

export class AnimationController {
  private static instance: AnimationController;
  private animationQueue: Map<string, Animation[]> = new Map();
  private prefersReducedMotion: boolean;

  constructor() {
    this.prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
    // Listen for changes in motion preferences
    window.matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', (e) => {
      this.prefersReducedMotion = e.matches;
    });
  }

  static getInstance(): AnimationController {
    if (!AnimationController.instance) {
      AnimationController.instance = new AnimationController();
    }
    return AnimationController.instance;
  }

  // Check if animations should be reduced
  shouldReduceMotion(): boolean {
    return this.prefersReducedMotion;
  }

  // Animate element with respect to user preferences
  animate(
    element: HTMLElement,
    keyframes: Keyframe[],
    options: AnimationConfig,
    id?: string
  ): Animation | null {
    if (this.prefersReducedMotion) {
      // Skip animation but still apply final state if needed
      const finalFrame = keyframes[keyframes.length - 1];
      if (finalFrame) {
        Object.assign(element.style, finalFrame);
      }
      return null;
    }

    const animation = element.animate(keyframes, {
      duration: options.duration,
      easing: options.easing,
      delay: options.delay || 0,
      fill: options.fillMode || 'forwards'
    });

    // Store animation for cleanup if ID provided
    if (id) {
      const animations = this.animationQueue.get(id) || [];
      animations.push(animation);
      this.animationQueue.set(id, animations);

      // Clean up completed animations
      animation.addEventListener('finish', () => {
        const currentAnimations = this.animationQueue.get(id) || [];
        const updatedAnimations = currentAnimations.filter(a => a !== animation);
        if (updatedAnimations.length === 0) {
          this.animationQueue.delete(id);
        } else {
          this.animationQueue.set(id, updatedAnimations);
        }
      });
    }

    return animation;
  }

  // Cancel animations by ID
  cancelAnimations(id: string): void {
    const animations = this.animationQueue.get(id);
    if (animations) {
      animations.forEach(animation => animation.cancel());
      this.animationQueue.delete(id);
    }
  }

  // Add CSS class with animation
  addAnimationClass(
    element: HTMLElement,
    className: string,
    duration?: number
  ): Promise<void> {
    return new Promise((resolve) => {
      if (this.prefersReducedMotion) {
        resolve();
        return;
      }

      element.classList.add(className);
      
      const cleanup = () => {
        element.classList.remove(className);
        resolve();
      };

      if (duration) {
        setTimeout(cleanup, duration);
      } else {
        element.addEventListener('animationend', cleanup, { once: true });
      }
    });
  }

  // Staggered animations for lists
  staggeredAnimation(
    elements: HTMLElement[],
    keyframes: Keyframe[],
    options: AnimationConfig,
    staggerDelay: number = 100
  ): Promise<void> {
    if (this.prefersReducedMotion) {
      return Promise.resolve();
    }

    const animations = elements.map((element, index) => {
      const animationOptions = {
        ...options,
        delay: (options.delay || 0) + (index * staggerDelay)
      };
      return this.animate(element, keyframes, animationOptions);
    }).filter(Boolean) as Animation[];

    return Promise.all(animations.map(animation => animation.finished)).then(() => {});
  }
}

// Convenience functions
export const animationController = AnimationController.getInstance();

export const animateElement = (
  element: HTMLElement,
  keyframes: Keyframe[],
  preset: keyof typeof ANIMATION_PRESETS = 'normal',
  options: Partial<AnimationConfig> = {}
) => {
  const presetConfig = ANIMATION_PRESETS[preset];
  const finalConfig = { ...presetConfig, ...options };
  return animationController.animate(element, keyframes, finalConfig);
};

// Pre-defined animation sequences
export const ANIMATION_SEQUENCES = {
  // Button click feedback
  buttonPress: [
    { transform: 'scale(1)' },
    { transform: 'scale(0.95)' },
    { transform: 'scale(1)' }
  ],
  
  // Fade in from bottom
  fadeInUp: [
    { opacity: 0, transform: 'translateY(20px)' },
    { opacity: 1, transform: 'translateY(0)' }
  ],
  
  // Fade out to top
  fadeOutUp: [
    { opacity: 1, transform: 'translateY(0)' },
    { opacity: 0, transform: 'translateY(-20px)' }
  ],
  
  // Scale in
  scaleIn: [
    { opacity: 0, transform: 'scale(0.8)' },
    { opacity: 1, transform: 'scale(1)' }
  ],
  
  // Scale out
  scaleOut: [
    { opacity: 1, transform: 'scale(1)' },
    { opacity: 0, transform: 'scale(0.8)' }
  ],
  
  // Slide in from right
  slideInRight: [
    { transform: 'translateX(100%)' },
    { transform: 'translateX(0)' }
  ],
  
  // Slide out to right
  slideOutRight: [
    { transform: 'translateX(0)' },
    { transform: 'translateX(100%)' }
  ],
  
  // Bounce entrance
  bounceIn: [
    { opacity: 0, transform: 'scale(0.3)' },
    { opacity: 1, transform: 'scale(1.05)' },
    { opacity: 1, transform: 'scale(0.9)' },
    { opacity: 1, transform: 'scale(1)' }
  ],
  
  // Gentle pulse
  pulse: [
    { transform: 'scale(1)' },
    { transform: 'scale(1.05)' },
    { transform: 'scale(1)' }
  ],
  
  // Number flip (for digital clock)
  numberFlip: [
    { transform: 'rotateX(0deg)' },
    { transform: 'rotateX(-90deg)' },
    { transform: 'rotateX(0deg)' }
  ]
};

// Helper for creating ripple effect
export const createRippleEffect = (element: HTMLElement, event: MouseEvent) => {
  if (animationController.shouldReduceMotion()) return;
  
  const rect = element.getBoundingClientRect();
  const ripple = document.createElement('span');
  const size = Math.max(rect.width, rect.height);
  const x = event.clientX - rect.left - size / 2;
  const y = event.clientY - rect.top - size / 2;
  
  ripple.style.cssText = `
    position: absolute;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.6);
    transform: scale(0);
    left: ${x}px;
    top: ${y}px;
    width: ${size}px;
    height: ${size}px;
    pointer-events: none;
  `;
  
  element.appendChild(ripple);
  
  ripple.animate([
    { transform: 'scale(0)', opacity: 0.6 },
    { transform: 'scale(1)', opacity: 0 }
  ], {
    duration: 600,
    easing: 'ease-out'
  }).addEventListener('finish', () => {
    ripple.remove();
  });
};

// Helper for particle effects
export const createParticleEffect = (
  container: HTMLElement,
  particleCount: number = 50,
  colors: string[] = ['#3b82f6', '#60a5fa', '#93c5fd']
) => {
  if (animationController.shouldReduceMotion()) return;
  
  for (let i = 0; i < particleCount; i++) {
    const particle = document.createElement('div');
    const color = colors[Math.floor(Math.random() * colors.length)];
    const size = Math.random() * 6 + 2;
    const x = Math.random() * 100;
    const duration = Math.random() * 2000 + 1000;
    
    particle.style.cssText = `
      position: absolute;
      width: ${size}px;
      height: ${size}px;
      background: ${color};
      border-radius: 50%;
      left: ${x}%;
      top: -10px;
      pointer-events: none;
    `;
    
    container.appendChild(particle);
    
    particle.animate([
      { 
        transform: 'translateY(-10px) rotate(0deg)',
        opacity: 1 
      },
      { 
        transform: `translateY(${container.clientHeight + 10}px) rotate(360deg)`,
        opacity: 0 
      }
    ], {
      duration,
      easing: 'linear'
    }).addEventListener('finish', () => {
      particle.remove();
    });
  }
};

// Theme transition helper
export const animateThemeTransition = (element: HTMLElement) => {
  if (animationController.shouldReduceMotion()) return;
  
  element.style.transition = 'none';
  void element.offsetHeight; // Trigger reflow - this is intentional
  element.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
};