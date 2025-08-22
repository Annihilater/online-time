import React, { useEffect, useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { useAlarmSound } from '@/shared/hooks/useAlarmSound';
import { formatTime } from '@/shared/utils/timeUtils';
import { AudioUtils } from '@/shared/utils/audioUtils';
import { AudioVisualizer } from './AudioVisualizer';
import { AnimatedButton } from './AnimatedButton';
import { StopCircle, Clock, Bell, Volume2, VolumeX } from 'lucide-react';

export const AlarmRinging: React.FC = () => {
  const { 
    alarms, 
    is24HourFormat, 
    snoozeMinutes,
    volume,
    setAlarmRinging, 
    stopAllAlarms 
  } = useAlarmStore();
  const { stopAlarm, snooze, isAudioPlaying } = useAlarmSound();
  const [isVisible, setIsVisible] = useState(false);
  const [showVolumeControl, setShowVolumeControl] = useState(false);
  const modalRef = null;
  // const animateWithSequence = () => Promise.resolve();

  const ringingAlarms = alarms.filter(alarm => alarm.isRinging);

  useEffect(() => {
    setIsVisible(ringingAlarms.length > 0);
  }, [ringingAlarms.length]);

  const handleStopAlarm = async (alarmId: string) => {
    // Success celebration
    // triggerCelebration(20, ['#10b981', '#34d399', '#6ee7b7']);
    
    stopAlarm(alarmId);
    
    // Animate button before stopping
    // await animateWithSequence(...);
    
    // Remove alarm after stopping (one-time alarm behavior)
    setTimeout(() => {
      setAlarmRinging(alarmId, false);
    }, 100);
  };

  const handleSnooze = async (alarmId: string) => {
    // Snooze animation
    // // await animateWithSequence(...);
    snooze(alarmId);
  };

  const handleStopAll = async () => {
    // Big celebration for stopping all alarms
    // triggerCelebration(50, ['#f59e0b', '#fbbf24', '#fcd34d']);
    
    // await animateWithSequence(...);
    stopAllAlarms();
  };

  if (!isVisible || ringingAlarms.length === 0) {
    return null;
  }

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 backdrop-blur-sm">
      {/* <div ref={particleRef} className="absolute inset-0 pointer-events-none" /> */}
      <div 
        ref={modalRef}
        className="glass p-8 mx-4 text-center max-w-md w-full shake modal-scale relative overflow-hidden"
      >
        {/* Animated background gradient */}
        <div className="absolute inset-0 bg-gradient-to-br from-red-500/20 via-orange-500/20 to-yellow-500/20 animate-pulse" />
        <div className="relative z-10">
        {/* 头部区域 */}
        <div className="mb-6">
          <div className="relative inline-block">
            <Bell className="w-16 h-16 text-red-400 mx-auto animate-bounce" />
            <div className="absolute -inset-2 rounded-full border-4 border-red-500 pulse-ring"></div>
            <div className="absolute -inset-4 rounded-full border-2 border-red-400 pulse-ring opacity-50" style={{ animationDelay: '0.3s' }}></div>
          </div>
          
          {/* Audio visualizer */}
          <div className="mt-4 flex justify-center">
            <AudioVisualizer isPlaying={isAudioPlaying()} barCount={8} height={30} />
          </div>
        </div>
        
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-white digital-font">闹钟响了!</h2>
          
          {/* 音量控制 */}
          <div className="relative">
            <AnimatedButton
              onClick={() => setShowVolumeControl(!showVolumeControl)}
              variant="ghost"
              size="sm"
              className="text-white hover:bg-white/20"
              icon={isAudioPlaying() ? <Volume2 className="w-5 h-5" /> : <VolumeX className="w-5 h-5" />}
              pulseOnHover
            >
              <span className="sr-only">音量控制</span>
            </AnimatedButton>
            
            {showVolumeControl && (
              <div className="absolute top-full right-0 mt-2 bg-black/80 p-3 rounded-lg backdrop-blur-sm modal-scale">
                <div className="text-white text-xs mb-2">
                  音量: {AudioUtils.formatVolumePercentage(volume)}
                </div>
                <div className="text-xs text-white/60">
                  点击设置调整音量
                </div>
              </div>
            )}
          </div>
        </div>
        
        <div className="space-y-3 mb-6">
          {ringingAlarms.map((alarm, index) => (
            <div key={alarm.id} className={`bg-white/10 rounded-lg p-3 backdrop-blur-sm border border-white/20 fade-in-up stagger-${index + 1}`}>
              <div className="text-3xl font-bold text-white digital-font mb-1 glow">
                {formatTime(alarm.time, is24HourFormat)}
              </div>
              {alarm.label && (
                <div className="text-white/80 text-sm mb-2">{alarm.label}</div>
              )}
              
              <div className="flex gap-2 mt-3 justify-center">
                <AnimatedButton
                  onClick={() => handleSnooze(alarm.id)}
                  variant="warning"
                  size="sm"
                  icon={<Clock className="w-4 h-4" />}
                  title={`贪睡${snoozeMinutes}分钟`}
                  className="text-white"
                >
                  贪睡{snoozeMinutes}分钟
                </AnimatedButton>
                <AnimatedButton
                  onClick={() => handleStopAlarm(alarm.id)}
                  variant="danger"
                  size="sm"
                  icon={<StopCircle className="w-4 h-4" />}
                  className="text-white"
                  glowEffect
                >
                  停止
                </AnimatedButton>
              </div>
            </div>
          ))}
        </div>
        
        {ringingAlarms.length > 1 && (
          <AnimatedButton
            onClick={handleStopAll}
            variant="danger"
            size="md"
            icon={<StopCircle className="w-5 h-5" />}
            className="w-full text-white"
            glowEffect
          >
            停止所有闹钟
          </AnimatedButton>
        )}
        
        {/* 底部信息 */}
        <div className="mt-6 space-y-2">
          <div className="text-xs text-white/60">
            点击停止或贪睡{snoozeMinutes}分钟来关闭闹钟
          </div>
          
          {ringingAlarms.length > 0 && (
            <div className="text-xs text-white/40">
              {ringingAlarms.map(alarm => (
                <div key={alarm.id}>
                  贪睡次数: {alarm.snoozeCount}
                  {alarm.snoozeCount > 0 && (
                    <span className="ml-2 text-yellow-400">
                      (已贪睡{alarm.snoozeCount}次)
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
          
          {/* 音频状态指示 */}
          <div className="flex items-center justify-center gap-2 text-xs text-white/40">
            <div className={`w-2 h-2 rounded-full transition-all duration-300 ${
              isAudioPlaying() ? 'bg-red-400 animate-pulse shadow-lg shadow-red-400/50' : 'bg-gray-500'
            }`}></div>
            {isAudioPlaying() ? '正在播放' : '音频已静音'}
          </div>
        </div>
        </div>
      </div>
    </div>
  );
};