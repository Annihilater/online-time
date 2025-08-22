import React, { useEffect, useRef, useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface AudioVisualizerProps {
  isPlaying: boolean;
  barCount?: number;
  height?: number;
  color?: string;
  className?: string;
}

export const AudioVisualizer: React.FC<AudioVisualizerProps> = ({
  isPlaying,
  barCount = 6,
  height = 40,
  color,
  className = ''
}) => {
  const { theme } = useAlarmStore();
  const isAnimationDisabled = false;
  const [animationHeights, setAnimationHeights] = useState<number[]>([]);
  const animationFrameRef = useRef<number | null>(null);

  // Generate random heights for bars when playing
  useEffect(() => {
    if (isPlaying && !isAnimationDisabled) {
      const animate = () => {
        setAnimationHeights(
          Array.from({ length: barCount }, () => Math.random() * 0.8 + 0.2)
        );
        animationFrameRef.current = requestAnimationFrame(animate);
      };
      animate();
    } else {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
      // Set bars to minimum height when not playing
      setAnimationHeights(Array.from({ length: barCount }, () => 0.2));
    }

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [isPlaying, barCount, isAnimationDisabled]);

  const getBarColor = () => {
    if (color) return color;
    return theme === 'dark' 
      ? 'linear-gradient(to top, #3b82f6, #60a5fa)' 
      : 'linear-gradient(to top, #2563eb, #3b82f6)';
  };

  return (
    <div 
      className={`flex items-end justify-center gap-1 ${className}`}
      style={{ height: `${height}px` }}
    >
      {Array.from({ length: barCount }).map((_, index) => (
        <div
          key={index}
          className={`w-1 rounded-t-sm transition-all duration-150 ${
            isAnimationDisabled ? '' : 'ease-out'
          }`}
          style={{
            height: `${(animationHeights[index] || 0.2) * height}px`,
            background: getBarColor(),
            minHeight: '4px',
            animationDelay: `${index * 0.1}s`
          }}
        />
      ))}
    </div>
  );
};

// Compact version for small spaces
export const MiniAudioVisualizer: React.FC<{ isPlaying: boolean }> = ({ 
  isPlaying 
}) => {
  return (
    <AudioVisualizer
      isPlaying={isPlaying}
      barCount={3}
      height={16}
      className="scale-75"
    />
  );
};

// Enhanced version with more visual effects
export const EnhancedAudioVisualizer: React.FC<AudioVisualizerProps & {
  showWaveform?: boolean;
  glowEffect?: boolean;
}> = ({
  isPlaying,
  barCount = 12,
  height = 60,
  showWaveform = false,
  glowEffect = false,
  className = '',
  ...props
}) => {
  const { theme } = useAlarmStore();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isAnimationDisabled = false;

  useEffect(() => {
    if (!showWaveform || !canvasRef.current || isAnimationDisabled) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      if (isPlaying) {
        // Draw waveform
        const centerY = canvas.height / 2;
        const frequency = Date.now() * 0.005;
        
        ctx.beginPath();
        ctx.strokeStyle = theme === 'dark' ? '#60a5fa' : '#3b82f6';
        ctx.lineWidth = 2;
        
        for (let x = 0; x < canvas.width; x += 2) {
          const y = centerY + Math.sin((x + frequency) * 0.02) * 20 * Math.random();
          if (x === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }
        ctx.stroke();
        
        if (glowEffect) {
          ctx.shadowColor = theme === 'dark' ? '#60a5fa' : '#3b82f6';
          ctx.shadowBlur = 10;
          ctx.stroke();
          ctx.shadowBlur = 0;
        }
      }
      
      if (isPlaying) {
        requestAnimationFrame(animate);
      }
    };

    animate();
  }, [isPlaying, theme, showWaveform, glowEffect, isAnimationDisabled]);

  if (showWaveform) {
    return (
      <div className={`relative ${className}`}>
        <canvas
          ref={canvasRef}
          width={200}
          height={height}
          className="w-full h-full"
        />
        {!isAnimationDisabled && (
          <div className="absolute inset-0 flex items-center justify-center">
            <AudioVisualizer
              isPlaying={isPlaying}
              barCount={barCount}
              height={height * 0.6}
              className="opacity-50"
              {...props}
            />
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={`relative ${className}`}>
      <AudioVisualizer
        isPlaying={isPlaying}
        barCount={barCount}
        height={height}
        {...props}
      />
      {glowEffect && !isAnimationDisabled && (
        <div 
          className="absolute inset-0 blur-sm opacity-50 pointer-events-none"
          style={{ filter: 'blur(2px)' }}
        >
          <AudioVisualizer
            isPlaying={isPlaying}
            barCount={barCount}
            height={height}
            {...props}
          />
        </div>
      )}
    </div>
  );
};