import React from 'react';
import { AlarmClock } from '@/shared/components/AlarmClock';
import { TimePicker } from '@/shared/components/TimePicker';
import { PresetTimes } from '@/shared/components/PresetTimes';
import { SoundSelector } from '@/shared/components/SoundSelector';
import { AlarmList } from '@/shared/components/AlarmList';
import { useAlarmSound } from '@/shared/hooks/useAlarmSound';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { useEffect } from 'react';

interface AlarmPageProps {
  onOpenSettings?: () => void;
}

export const AlarmPage: React.FC<AlarmPageProps> = ({ onOpenSettings }) => {
  const { isRinging } = useAlarmSound();
  const theme = useAlarmStore((state) => state.theme);
  
  // Prevent page reload when alarm is ringing
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (isRinging) {
        e.preventDefault();
        e.returnValue = '闹钟正在响铃，确定要离开页面吗？';
      }
    };
    
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [isRinging]);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          在线闹钟
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          免费的在线闹钟，无需下载软件，只需打开浏览器即可使用。支持多种声音选择和闹钟标签。
        </p>
      </div>

      {/* Current Time Display */}
      <AlarmClock onOpenSettings={onOpenSettings || (() => {})} />
      
      {/* Time Picker */}
      <TimePicker />
      
      {/* Preset Times */}
      <PresetTimes />
      
      {/* Sound Selector */}
      <SoundSelector />
      
      {/* Alarm List */}
      <AlarmList />
      
      {/* Instructions */}
      <div className={`mt-8 p-6 rounded-lg border ${
        theme === 'dark' ? 'bg-gray-800 border-gray-700' : 'bg-gray-50 border-gray-200'
      }`}>
        <h3 className={`text-lg font-semibold mb-4 ${
          theme === 'dark' ? 'text-white' : 'text-gray-900'
        }`}>
          使用说明
        </h3>
        <div className={`space-y-2 text-sm ${
          theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
        }`}>
          <p>• 请保持浏览器标签页激活状态，闹钟才能正常工作</p>
          <p>• 电脑休眠或关机时闹钟无法正常工作</p>
          <p>• 不能使用自定义音乐文件，仅支持内置声音</p>
          <p>• 可以同时设置多个闹钟，支持数据导出和清理功能</p>
        </div>
      </div>
    </div>
  );
};