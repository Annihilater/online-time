import React, { useEffect, useState } from 'react';
import { useAlarmStore, ALARM_SOUNDS } from '@/shared/stores/alarmStore';
import { useAlarmSound } from '@/shared/hooks/useAlarmSound';
import { AudioVisualizer } from './AudioVisualizer';
import { LoadingSpinner } from './LoadingSpinner';
import { AnimatedButton } from './AnimatedButton';
import { X, Volume2, Play, Pause, Moon, Sun, Clock, Settings } from 'lucide-react';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({ isOpen, onClose }) => {
  const {
    selectedSound,
    volume,
    theme,
    is24HourFormat,
    setSound,
    setVolume,
    setTheme,
    setTimeFormat,
  } = useAlarmStore();
  
  const { testSound } = useAlarmSound();
  const modalRef = { current: null }; // useModalAnimation();
  const [playingSound, setPlayingSound] = useState<string | null>(null);
  const [isLoadingSound, setIsLoadingSound] = useState<string | null>(null);
  const [showVolumeAnimation, setShowVolumeAnimation] = useState(false);

  const soundNames: Record<string, string> = {
    clock: '时钟',
    beep: '蜂鸣声',
    rooster: '公鸡声',
    siren: '警笛声',
    nuclear: '核弹',
    alien: '外星人',
    rain: '雨声',
    bomb: '炸弹',
    mystery: '神秘之声',
    bell: '钟声',
    whitenoise: '白噪音',
  };

  const handleTestSound = async (soundName: string) => {
    if (playingSound === soundName) {
      setPlayingSound(null);
      return;
    }

    setIsLoadingSound(soundName);
    try {
      await testSound(soundName);
      setPlayingSound(soundName);
      
      // Auto stop after 3 seconds
      setTimeout(() => {
        setPlayingSound(null);
      }, 3000);
    } catch (error) {
      console.error('Failed to play sound:', error);
    } finally {
      setIsLoadingSound(null);
    }
  };
  
  const handleVolumeChange = (newVolume: number) => {
    setVolume(newVolume);
    setShowVolumeAnimation(true);
    setTimeout(() => setShowVolumeAnimation(false), 300);
  };
  
  const handleCloseModal = () => {
    setPlayingSound(null);
    onClose();
  };
  
  // Stop playing sound when modal closes
  useEffect(() => {
    if (!isOpen) {
      setPlayingSound(null);
      setIsLoadingSound(null);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 backdrop-blur-sm">
      <div 
        ref={modalRef}
        className={`rounded-lg shadow-xl p-6 w-full max-w-md mx-4 max-h-[80vh] overflow-y-auto modal-scale transition-colors duration-300 ${
          theme === 'dark' 
            ? 'bg-gray-800 text-white' 
            : 'bg-white text-gray-900'
        }`}
      >
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <Settings className={`w-6 h-6 ${
              theme === 'dark' ? 'text-blue-400' : 'text-blue-600'
            }`} />
            <h2 className={`text-xl font-semibold ${
              theme === 'dark' ? 'text-white' : 'text-gray-900'
            }`}>设置</h2>
          </div>
          <AnimatedButton
            onClick={handleCloseModal}
            variant="ghost"
            size="sm"
            icon={<X className="w-5 h-5" />}
            className={`rounded-full ${
              theme === 'dark'
                ? 'text-gray-400 hover:text-gray-300 hover:bg-gray-700'
                : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
            }`}
          >
            <span className="sr-only">关闭</span>
          </AnimatedButton>
        </div>
        
        <div className="space-y-6">
          {/* Sound Selection */}
          <div className="fade-in-up">
            <label className={`block font-medium mb-3 flex items-center gap-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              <Volume2 className="w-4 h-4" />
              闹钟铃声
            </label>
            <div className="space-y-2">
              {ALARM_SOUNDS.map((sound, index) => (
                <div key={sound} className={`flex items-center justify-between p-2 rounded-lg transition-all duration-200 fade-in-up stagger-${index % 4 + 1} ${
                  selectedSound === sound
                    ? theme === 'dark'
                      ? 'bg-blue-900/30 border border-blue-500/50'
                      : 'bg-blue-50 border border-blue-200'
                    : theme === 'dark'
                      ? 'hover:bg-gray-700'
                      : 'hover:bg-gray-50'
                }`}>
                  <label className="flex items-center gap-3 cursor-pointer flex-1">
                    <input
                      type="radio"
                      name="sound"
                      value={sound}
                      checked={selectedSound === sound}
                      onChange={() => setSound(sound)}
                      className="text-blue-600 focus:ring-blue-500"
                    />
                    <span className={`${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>{soundNames[sound]}</span>
                  </label>
                  
                  <div className="flex items-center gap-2">
                    {playingSound === sound && (
                      <AudioVisualizer isPlaying={true} barCount={4} height={16} className="scale-75" />
                    )}
                    
                    <AnimatedButton
                      onClick={() => handleTestSound(sound)}
                      variant="ghost"
                      size="sm"
                      loading={isLoadingSound === sound}
                      icon={
                        isLoadingSound === sound ? (
                          <LoadingSpinner type="spinner" size="sm" />
                        ) : playingSound === sound ? (
                          <Pause className="w-4 h-4" />
                        ) : (
                          <Play className="w-4 h-4" />
                        )
                      }
                      title={playingSound === sound ? '停止试听' : '试听'}
                      className={`rounded ${
                        theme === 'dark'
                          ? 'text-gray-400 hover:text-blue-400 hover:bg-blue-900/30'
                          : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50'
                      }`}
                      pulseOnHover
                    >
                      <span className="sr-only">{playingSound === sound ? '停止' : '试听'}</span>
                    </AnimatedButton>
                  </div>
                </div>
              ))}
            </div>
          </div>
          
          {/* Volume Control */}
          <div className="fade-in-up stagger-1">
            <label className={`block font-medium mb-3 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              音量: <span className={`font-bold ${
                showVolumeAnimation ? 'animate-bounce text-blue-500' : ''
              }`}>{Math.round(volume * 100)}%</span>
            </label>
            <div className="relative">
              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={volume}
                onChange={(e) => handleVolumeChange(parseFloat(e.target.value))}
                className={`w-full h-2 rounded-lg appearance-none cursor-pointer slider transition-all duration-200 ${
                  theme === 'dark'
                    ? 'bg-gray-600'
                    : 'bg-gray-200'
                } focus:scale-105`}
              />
              {/* Volume indicator */}
              <div 
                className={`absolute top-0 h-2 rounded-lg transition-all duration-200 ${
                  theme === 'dark' ? 'bg-blue-500' : 'bg-blue-600'
                }`}
                style={{ width: `${volume * 100}%` }}
              />
            </div>
            <div className={`flex justify-between text-xs mt-1 ${
              theme === 'dark' ? 'text-gray-400' : 'text-gray-400'
            }`}>
              <span>0%</span>
              <span>50%</span>
              <span>100%</span>
            </div>
          </div>
          
          {/* Time Format */}
          <div className="fade-in-up stagger-2">
            <label className={`block font-medium mb-3 flex items-center gap-2 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              <Clock className="w-4 h-4" />
              时间格式
            </label>
            <div className="grid grid-cols-2 gap-3">
              {[
                { value: false, label: '12小时制', example: '2:30 PM' },
                { value: true, label: '24小时制', example: '14:30' }
              ].map((format) => (
                <label key={String(format.value)} className={`flex flex-col gap-2 cursor-pointer p-3 rounded-lg border-2 transition-all duration-200 ${
                  is24HourFormat === format.value
                    ? theme === 'dark'
                      ? 'border-blue-500 bg-blue-900/30'
                      : 'border-blue-500 bg-blue-50'
                    : theme === 'dark'
                      ? 'border-gray-600 hover:border-gray-500'
                      : 'border-gray-300 hover:border-gray-400'
                }`}>
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      name="timeFormat"
                      checked={is24HourFormat === format.value}
                      onChange={() => setTimeFormat(format.value)}
                      className="text-blue-600 focus:ring-blue-500"
                    />
                    <span className={`font-medium ${
                      theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                    }`}>{format.label}</span>
                  </div>
                  <div className={`text-xs font-mono ${
                    theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
                  }`}>
                    示例: {format.example}
                  </div>
                </label>
              ))}
            </div>
          </div>
          
          {/* Theme */}
          <div className="fade-in-up stagger-3">
            <label className={`block font-medium mb-3 ${
              theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
            }`}>
              主题外观
            </label>
            <div className="grid grid-cols-2 gap-3">
              {[
                { value: 'light', label: '浅色', icon: Sun, desc: '适合日间使用' },
                { value: 'dark', label: '深色', icon: Moon, desc: '适合夜间使用' }
              ].map((themeOption) => {
                const Icon = themeOption.icon;
                return (
                  <label key={themeOption.value} className={`flex flex-col gap-2 cursor-pointer p-3 rounded-lg border-2 transition-all duration-200 ${
                    theme === themeOption.value
                      ? theme === 'dark'
                        ? 'border-blue-500 bg-blue-900/30'
                        : 'border-blue-500 bg-blue-50'
                      : theme === 'dark'
                        ? 'border-gray-600 hover:border-gray-500'
                        : 'border-gray-300 hover:border-gray-400'
                  }`}>
                    <div className="flex items-center gap-2">
                      <input
                        type="radio"
                        name="theme"
                        value={themeOption.value}
                        checked={theme === themeOption.value}
                        onChange={() => setTheme(themeOption.value as 'light' | 'dark')}
                        className="text-blue-600 focus:ring-blue-500"
                      />
                      <Icon className={`w-4 h-4 ${
                        themeOption.value === 'light' ? 'text-yellow-500' : 'text-blue-400'
                      }`} />
                      <span className={`font-medium ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-700'
                      }`}>{themeOption.label}</span>
                    </div>
                    <div className={`text-xs ${
                      theme === 'dark' ? 'text-gray-400' : 'text-gray-500'
                    }`}>
                      {themeOption.desc}
                    </div>
                  </label>
                );
              })}
            </div>
          </div>
        </div>
        
        <div className={`mt-6 pt-4 border-t fade-in-up stagger-4 ${
          theme === 'dark' ? 'border-gray-600' : 'border-gray-200'
        }`}>
          <div className={`p-3 rounded-lg ${
            theme === 'dark' ? 'bg-blue-900/20' : 'bg-blue-50'
          }`}>
            <p className={`text-sm flex items-start gap-2 ${
              theme === 'dark' ? 'text-blue-300' : 'text-blue-700'
            }`}>
              <span className="text-lg">💡</span>
              <span>
                <strong>提示：</strong>浏览器需要获得通知权限才能在闹钟响起时发送提醒。建议在设置中允许通知。
              </span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};