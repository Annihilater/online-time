import React, { useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { audioEngine } from '@/shared/utils/audioUtils';
import { AudioVisualizer, MiniAudioVisualizer } from './AudioVisualizer';
import { LoadingSpinner } from './LoadingSpinner';
import { AnimatedButton } from './AnimatedButton';
import { Play, Pause, Volume2 } from 'lucide-react';

const SOUND_OPTIONS = [
  { value: 'clock', label: '时钟哔呶声' },
  { value: 'rooster', label: '公鸡声' },
  { value: 'siren', label: '警报声' },
  { value: 'rain', label: '雨声' },
  { value: 'whitenoise', label: '白噪音' },
];

export const SoundSelector: React.FC = () => {
  const { selectedSound, setSound, theme, volume } = useAlarmStore();
  const containerRef = null;
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleTestSound = async () => {
    if (isPlaying) {
      audioEngine.stop();
      setIsPlaying(false);
      return;
    }

    setIsLoading(true);
    
    try {
      console.log('Testing sound:', selectedSound);
      setIsPlaying(true);
      
      // Actually play the sound using audioEngine
      await audioEngine.testSound(selectedSound, 3000);
      
      // The testSound method automatically stops after duration
      setTimeout(() => {
        setIsPlaying(false);
      }, 3000);
      
    } catch (error) {
      console.error('Failed to play sound:', error);
      setIsPlaying(false);
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleSoundChange = (sound: string) => {
    // Stop any currently playing sound when changing selection
    if (isPlaying) {
      audioEngine.stop();
      setIsPlaying(false);
    }
    setSound(sound);
  };

  return (
    <div ref={containerRef} className="mb-6 fade-in-up stagger-2">
      <h3 className={`text-lg font-medium mb-3 transition-colors duration-300 ${
        theme === 'dark' ? 'text-white' : 'text-gray-900'
      }`}>选择声音</h3>
      
      <div className="space-y-4">
        <div className="flex gap-3 items-end">
          <div className="flex-1">
            <label className={`block text-sm mb-1 transition-colors duration-300 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
            }`}>闹钟声音</label>
            <select
              value={selectedSound}
              onChange={(e) => handleSoundChange(e.target.value)}
              disabled={isLoading || isPlaying}
              className={`select select-bordered w-full focus:border-blue-500 transition-all duration-300 transform-gpu ${
                theme === 'dark'
                  ? 'bg-gray-700 border-gray-600 text-white'
                  : 'bg-white border-gray-300 text-gray-900'
              } ${isLoading || isPlaying ? 'opacity-50 cursor-not-allowed' : 'hover:scale-[1.01] focus:scale-[1.01]'}`}
            >
              {SOUND_OPTIONS.map(sound => (
                <option key={sound.value} value={sound.value}>
                  {sound.label}
                </option>
              ))}
            </select>
          </div>
          
          <AnimatedButton
            onClick={handleTestSound}
            variant="secondary"
            size="md"
            loading={isLoading}
            disabled={isLoading}
            icon={
              isLoading ? 
                <LoadingSpinner type="spinner" size="sm" /> : 
                isPlaying ? 
                  <Pause className="w-4 h-4" /> : 
                  <Play className="w-4 h-4" />
            }
            title={isPlaying ? '停止测试' : '测试声音'}
            className="min-w-[80px]"
            pulseOnHover
          >
            {isPlaying ? '停止' : '测试'}
          </AnimatedButton>
        </div>
        
        {/* Audio visualization and volume info */}
        {(isPlaying || isLoading) && (
          <div className={`p-3 rounded-lg border backdrop-blur-sm transition-all duration-300 ${
            theme === 'dark' 
              ? 'bg-gray-800/50 border-gray-600' 
              : 'bg-gray-50/50 border-gray-200'
          }`}>
            <div className="flex items-center justify-between mb-2">
              <span className={`text-sm font-medium ${
                theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
              }`}>
                {isLoading ? '加载中...' : '正在播放'}
              </span>
              
              <div className="flex items-center gap-2">
                <Volume2 className="w-4 h-4 text-blue-500" />
                <span className={`text-xs ${
                  theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
                }`}>
                  {Math.round(volume * 100)}%
                </span>
              </div>
            </div>
            
            <div className="flex justify-center">
              {isLoading ? (
                <LoadingSpinner type="wave" size="sm" />
              ) : (
                <AudioVisualizer 
                  isPlaying={isPlaying} 
                  barCount={10} 
                  height={24}
                  className="opacity-80" 
                />
              )}
            </div>
          </div>
        )}
        
        {/* Sound description */}
        <div className={`text-xs transition-colors duration-300 ${
          theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
        }`}>
          当前选中: <span className="font-medium">{SOUND_OPTIONS.find(s => s.value === selectedSound)?.label}</span>
          {isPlaying && (
            <span className="ml-2 inline-flex items-center gap-1">
              <MiniAudioVisualizer isPlaying={true} />
              <span className="text-blue-500">播放中</span>
            </span>
          )}
        </div>
      </div>
      
      {/* Animated divider */}
      <div className="relative mt-6 mb-6">
        <hr className={`transition-colors duration-300 fade-in-up stagger-3 ${
          theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
        }`} />
      </div>
    </div>
  );
};