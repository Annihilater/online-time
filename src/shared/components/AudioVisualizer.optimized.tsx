import React, { useMemo } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';

interface AudioVisualizerProps {
  isPlaying: boolean;
  barCount?: number;
  height?: number;
  color?: string;
  className?: string;
}

// CSS动画版本的AudioVisualizer - 避免60fps的React状态更新
export const AudioVisualizer: React.FC<AudioVisualizerProps> = ({
  isPlaying,
  barCount = 6,
  height = 40,
  color,
  className = ''
}) => {
  const { theme } = useAlarmStore();

  const getBarColor = useMemo(() => {
    if (color) return color;
    return theme === 'dark' 
      ? 'linear-gradient(to top, #3b82f6, #60a5fa)' 
      : 'linear-gradient(to top, #2563eb, #3b82f6)';
  }, [color, theme]);

  // 生成随机动画延迟，但在组件生命周期内保持不变
  const barDelays = useMemo(() => 
    Array.from({ length: barCount }, (_, i) => Math.random() * 0.5 + i * 0.1),
    [barCount]
  );

  return (
    <>
      <style>{`
        @keyframes audioBar {
          0%, 100% { 
            transform: scaleY(0.3);
            opacity: 0.7;
          }
          50% { 
            transform: scaleY(1);
            opacity: 1;
          }
        }
        
        .audio-bar {
          transform-origin: bottom;
          will-change: transform;
        }
        
        .audio-bar.playing {
          animation: audioBar 0.6s ease-in-out infinite;
        }
        
        .audio-bar:nth-child(2) { animation-delay: 0.1s; }
        .audio-bar:nth-child(3) { animation-delay: 0.2s; }
        .audio-bar:nth-child(4) { animation-delay: 0.3s; }
        .audio-bar:nth-child(5) { animation-delay: 0.4s; }
        .audio-bar:nth-child(6) { animation-delay: 0.5s; }
        .audio-bar:nth-child(7) { animation-delay: 0.1s; }
        .audio-bar:nth-child(8) { animation-delay: 0.2s; }
        .audio-bar:nth-child(9) { animation-delay: 0.3s; }
        .audio-bar:nth-child(10) { animation-delay: 0.4s; }
        .audio-bar:nth-child(11) { animation-delay: 0.5s; }
        .audio-bar:nth-child(12) { animation-delay: 0.6s; }
      `}</style>
      
      <div 
        className={`flex items-end justify-center gap-1 ${className}`}
        style={{ height: `${height}px` }}
        role="img" 
        aria-label={isPlaying ? "音频播放中" : "音频已停止"}
      >
        {Array.from({ length: barCount }).map((_, index) => (
          <div
            key={index}
            className={`audio-bar w-1 rounded-t-sm ${isPlaying ? 'playing' : ''}`}
            style={{
              height: `${height}px`,
              background: getBarColor,
              minHeight: '4px',
              animationDelay: `${barDelays[index]}s`,
              transform: isPlaying ? undefined : 'scaleY(0.3)'
            }}
          />
        ))}
      </div>
    </>
  );
};

// 紧凑版本 - 用于小空间
export const MiniAudioVisualizer: React.FC<{ isPlaying: boolean; className?: string }> = ({ 
  isPlaying,
  className = ''
}) => {
  return (
    <AudioVisualizer
      isPlaying={isPlaying}
      barCount={3}
      height={16}
      className={`scale-75 ${className}`}
    />
  );
};

// 高性能条形音频可视化器
export const PerformantAudioVisualizer: React.FC<AudioVisualizerProps & {
  variant?: 'bars' | 'pulse' | 'wave'
}> = ({
  isPlaying,
  barCount = 6,
  height = 40,
  color,
  className = '',
  variant = 'bars'
}) => {
  const { theme } = useAlarmStore();

  const getColor = useMemo(() => {
    if (color) return color;
    return theme === 'dark' ? '#60a5fa' : '#3b82f6';
  }, [color, theme]);

  if (variant === 'pulse') {
    return (
      <>
        <style>{`
          @keyframes audioPulse {
            0%, 100% { 
              transform: scale(1);
              opacity: 0.6;
            }
            50% { 
              transform: scale(1.2);
              opacity: 1;
            }
          }
          
          .audio-pulse {
            will-change: transform;
          }
          
          .audio-pulse.playing {
            animation: audioPulse 1s ease-in-out infinite;
          }
        `}</style>
        
        <div className={`flex items-center justify-center ${className}`}>
          <div
            className={`audio-pulse w-6 h-6 rounded-full ${isPlaying ? 'playing' : ''}`}
            style={{
              backgroundColor: getColor,
              opacity: isPlaying ? 1 : 0.3
            }}
          />
        </div>
      </>
    );
  }

  if (variant === 'wave') {
    return (
      <>
        <style>{`
          @keyframes audioWave {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(100%); }
          }
          
          .audio-wave {
            will-change: transform;
          }
          
          .audio-wave.playing {
            animation: audioWave 2s linear infinite;
          }
        `}</style>
        
        <div 
          className={`relative overflow-hidden rounded ${className}`}
          style={{ height: `${height}px`, width: '60px' }}
        >
          <div
            className={`audio-wave absolute inset-y-0 w-4 ${isPlaying ? 'playing' : ''}`}
            style={{
              background: `linear-gradient(90deg, transparent, ${getColor}, transparent)`,
              left: '-16px'
            }}
          />
        </div>
      </>
    );
  }

  // 默认条形版本 - 使用transform而不是height变化以获得更好的性能
  return (
    <>
      <style>{`
        @keyframes audioBarOptimized {
          0%, 100% { 
            transform: scaleY(0.2);
          }
          25% { 
            transform: scaleY(${0.4 + Math.random() * 0.6});
          }
          50% { 
            transform: scaleY(${0.6 + Math.random() * 0.4});
          }
          75% { 
            transform: scaleY(${0.3 + Math.random() * 0.7});
          }
        }
        
        .audio-bar-optimized {
          transform-origin: bottom;
          will-change: transform;
        }
        
        .audio-bar-optimized.playing {
          animation: audioBarOptimized 0.8s ease-in-out infinite;
        }
      `}</style>
      
      <div 
        className={`flex items-end justify-center gap-1 ${className}`}
        style={{ height: `${height}px` }}
      >
        {Array.from({ length: barCount }).map((_, index) => (
          <div
            key={index}
            className={`audio-bar-optimized w-1 rounded-t-sm ${isPlaying ? 'playing' : ''}`}
            style={{
              height: `${height}px`,
              backgroundColor: getColor,
              animationDelay: `${index * 0.1 + Math.random() * 0.2}s`,
              transform: isPlaying ? undefined : 'scaleY(0.2)'
            }}
          />
        ))}
      </div>
    </>
  );
};

// 导出优化版本作为默认版本
export default AudioVisualizer;