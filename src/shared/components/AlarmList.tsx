import React, { useState } from 'react';
import { useAlarmStore } from '@/shared/stores/alarmStore';
import { useAlarmSound } from '@/shared/hooks/useAlarmSound';
import { formatAlarmTime, getTimeUntilAlarm } from '@/shared/utils/timeUtils';
import { MiniAudioVisualizer } from './AudioVisualizer';
import { AnimatedButton } from './AnimatedButton';
import { Trash2, Power, PowerOff, Bell, StopCircle, Clock, Download, Trash } from 'lucide-react';

export const AlarmList: React.FC = () => {
  const { alarms, toggleAlarm, removeAlarm, theme, resetToDefaults } = useAlarmStore();
  const { stopAlarm } = useAlarmSound();
  // const particleRef = { current: null };
  const [removingId, setRemovingId] = useState<string | null>(null);
  
  const exportToCSV = () => {
    if (alarms.length === 0) {
      alert('没有闹钟数据可导出');
      return;
    }
    
    const headers = ['时间', '标签', '声音', '状态', '创建日期'];
    const csvData = alarms.map(alarm => [
      formatAlarmTime(alarm.time),
      alarm.label || '-',
      alarm.sound,
      alarm.isActive ? '已启用' : '已禁用',
      alarm.createdAt.toLocaleDateString()
    ]);
    
    const csvContent = [headers, ...csvData]
      .map(row => row.map(field => `"${field}"`).join(','))
      .join('\n');
    
    const blob = new Blob(['﻿' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `闹钟数据_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };
  
  const clearAllData = () => {
    if (window.confirm('确定要清除所有闹钟数据吗？此操作不可撤销。')) {
      resetToDefaults();
    }
  };
  
  const handleToggleAlarm = async (alarmId: string) => {
    const alarm = alarms.find(a => a.id === alarmId);
    if (alarm && !alarm.isActive) {
      // Celebration when enabling alarm (simplified)
      console.log('Alarm enabled!');
    }
    toggleAlarm(alarmId);
  };
  
  const handleRemoveAlarm = async (alarmId: string) => {
    setRemovingId(alarmId);
    
    // Small delay for animation
    await new Promise(resolve => setTimeout(resolve, 300));
    
    removeAlarm(alarmId);
    setRemovingId(null);
  };

  if (alarms.length === 0) {
    return (
      <div className="text-center py-8 fade-in-up">
        <div className={`mb-4 transition-colors duration-300 ${
          theme === 'dark' ? 'text-gray-500' : 'text-gray-400'
        }`}>
          <div className="relative inline-block">
            <Bell className="w-12 h-12 mx-auto mb-2 opacity-50" />
            <div className="absolute inset-0 flex items-center justify-center">
              <Clock className="w-6 h-6 text-blue-500 animate-bounce" style={{ animationDelay: '0.5s' }} />
            </div>
          </div>
        </div>
        <p className={`text-lg font-medium mb-2 transition-colors duration-300 ${
          theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
        }`}>还没有设置闹钟</p>
        <p className={`text-sm transition-colors duration-300 ${
          theme === 'dark' ? 'text-gray-500' : 'text-gray-400'
        }`}>使用上面的工具添加你的第一个闹钟</p>
      </div>
    );
  }

  return (
    <div className="relative">
      {/* <div ref={particleRef} className="absolute inset-0 pointer-events-none z-10" /> */}
      <div className="flex items-center justify-between mb-4 fade-in-up">
        <div className="flex items-center gap-2">
          <Bell className={`w-5 h-5 transition-colors duration-300 ${
            theme === 'dark' ? 'text-gray-400' : 'text-gray-600'
          }`} />
          <h3 className={`text-lg font-medium transition-colors duration-300 ${
            theme === 'dark' ? 'text-white' : 'text-gray-900'
          }`}>我的闹钟</h3>
          <span className={`text-sm font-medium px-2.5 py-0.5 rounded-full transition-all duration-300 transform-gpu ${
            theme === 'dark' 
              ? 'bg-blue-900 text-blue-300'
              : 'bg-blue-100 text-blue-800'
          } hover:scale-110`}>
            {alarms.length}
          </span>
        </div>
        
        <div className="flex items-center gap-2">
          <AnimatedButton
            onClick={exportToCSV}
            variant="ghost"
            size="sm"
            icon={<Download className="w-4 h-4" />}
            title="导出为CSV"
            className={`${
              theme === 'dark'
                ? 'text-gray-400 hover:text-blue-400 hover:bg-blue-900/30'
                : 'text-gray-600 hover:text-blue-600 hover:bg-blue-50'
            }`}
          >
            导出
          </AnimatedButton>
          
          <AnimatedButton
            onClick={clearAllData}
            variant="ghost"
            size="sm"
            icon={<Trash className="w-4 h-4" />}
            title="清除数据"
            className={`${
              theme === 'dark'
                ? 'text-gray-400 hover:text-red-400 hover:bg-red-900/30'
                : 'text-gray-600 hover:text-red-600 hover:bg-red-50'
            }`}
          >
            清除
          </AnimatedButton>
        </div>
      </div>
      
      <div className="space-y-3">
        {alarms.map((alarm) => {
          const AlarmItem: React.FC = () => {
            const ref = null;
            
            return (
              <div
                ref={ref}
                className={`
                  p-4 rounded-lg border transition-all duration-300 transform-gpu
                  ${removingId === alarm.id ? 'slide-out-right opacity-0' : ''}
                  ${alarm.isRinging 
                    ? theme === 'dark' 
                      ? 'bg-red-900/30 border-red-500 shake shadow-lg shadow-red-500/20' 
                      : 'bg-red-50 border-red-300 shake shadow-lg shadow-red-300/20'
                    : alarm.isActive 
                      ? theme === 'dark'
                        ? 'bg-gray-700 border-gray-600 hover:border-blue-400 hover:bg-gray-600 hover:shadow-lg hover:shadow-blue-500/10'
                        : 'bg-white border-gray-300 hover:border-blue-300 hover:bg-blue-50 hover:shadow-lg hover:shadow-blue-300/10'
                      : theme === 'dark'
                        ? 'bg-gray-800 border-gray-700 opacity-60'
                        : 'bg-gray-50 border-gray-200 opacity-60'
                  }
                  hover:scale-[1.02] will-change-transform
                `}
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className={`text-2xl font-bold digital-font transition-colors duration-300 ${
                        alarm.isRinging 
                          ? 'text-red-500 glow' 
                          : theme === 'dark' 
                            ? 'text-white' 
                            : 'text-gray-900'
                      }`}>
                        {formatAlarmTime(alarm.time)}
                      </span>
                      {alarm.isRinging && (
                        <div className="flex items-center gap-2">
                          <span className="bg-red-100 text-red-800 text-sm font-medium px-2.5 py-0.5 rounded-full animate-pulse">
                            响铃中
                          </span>
                          <MiniAudioVisualizer isPlaying={true} />
                        </div>
                      )}
                    </div>
                    
                    {alarm.label && (
                      <p className={`text-sm mt-1 transition-colors duration-300 ${
                        theme === 'dark' ? 'text-gray-300' : 'text-gray-600'
                      }`}>{alarm.label}</p>
                    )}
                    
                    {alarm.isActive && !alarm.isRinging && (
                      <p className={`text-xs mt-1 transition-colors duration-300 ${
                        theme === 'dark' ? 'text-gray-500' : 'text-gray-400'
                      }`}>
                        {getTimeUntilAlarm(alarm.time)}
                      </p>
                    )}
                  </div>
                  
                  <div className="flex items-center gap-2">
                    {alarm.isRinging && (
                      <AnimatedButton
                        onClick={() => stopAlarm(alarm.id)}
                        variant="danger"
                        size="sm"
                        icon={<StopCircle className="w-4 h-4" />}
                        title="停止闹钟"
                        className="text-white"
                        glowEffect
                      >
                        停止
                      </AnimatedButton>
                    )}
                    
                    <AnimatedButton
                      onClick={() => handleToggleAlarm(alarm.id)}
                      variant="ghost"
                      size="sm"
                      icon={alarm.isActive ? <Power className="w-4 h-4" /> : <PowerOff className="w-4 h-4" />}
                      title={alarm.isActive ? '禁用闹钟' : '启用闹钟'}
                      className={`
                        ${alarm.isActive 
                          ? theme === 'dark'
                            ? 'text-green-400 hover:bg-green-900/30'
                            : 'text-green-600 hover:bg-green-50'
                          : theme === 'dark'
                            ? 'text-gray-500 hover:bg-gray-700'
                            : 'text-gray-400 hover:bg-gray-50'
                        }
                      `}
                      pulseOnHover
                    >
                      <span className="sr-only">{alarm.isActive ? '禁用' : '启用'}</span>
                    </AnimatedButton>
                    
                    <AnimatedButton
                      onClick={() => handleRemoveAlarm(alarm.id)}
                      variant="ghost"
                      size="sm"
                      icon={<Trash2 className="w-4 h-4" />}
                      title="删除闹钟"
                      loading={removingId === alarm.id}
                      className={`
                        ${theme === 'dark'
                          ? 'text-gray-500 hover:text-red-400 hover:bg-red-900/30'
                          : 'text-gray-400 hover:text-red-600 hover:bg-red-50'
                        }
                      `}
                    >
                      <span className="sr-only">删除</span>
                    </AnimatedButton>
                  </div>
                </div>
              </div>
            );
          };
          
          return <AlarmItem key={alarm.id} />;
        })}
      </div>
    </div>
  );
};