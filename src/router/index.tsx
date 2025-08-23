import { Routes, Route } from 'react-router-dom';
import { Suspense, lazy } from 'react';
import { MainLayout } from '@/layouts/MainLayout';
import { LoadingSpinner } from '@/shared/components/LoadingSpinner';

// 懒加载路由组件，实现代码分割
const AlarmPage = lazy(() => import('@/pages/AlarmPage').then(module => ({ default: module.AlarmPage })));
const TimerPage = lazy(() => import('@/pages/TimerPage').then(module => ({ default: module.TimerPage })));
const CountdownPage = lazy(() => import('@/pages/CountdownPage').then(module => ({ default: module.CountdownPage })));
const StopwatchPage = lazy(() => import('@/pages/StopwatchPage').then(module => ({ default: module.StopwatchPage })));
const ClockPage = lazy(() => import('@/pages/ClockPage').then(module => ({ default: module.ClockPage })));
const WorldTimePage = lazy(() => import('@/pages/WorldTimePage').then(module => ({ default: module.WorldTimePage })));
const DateCalculatorPage = lazy(() => import('@/pages/DateCalculatorPage').then(module => ({ default: module.DateCalculatorPage })));
const HoursCalculatorPage = lazy(() => import('@/pages/HoursCalculatorPage').then(module => ({ default: module.HoursCalculatorPage })));
const WeekNumbersPage = lazy(() => import('@/pages/WeekNumbersPage').then(module => ({ default: module.WeekNumbersPage })));

// 高阶组件包装Suspense
const SuspenseWrapper = ({ children }: { children: React.ReactNode }) => (
  <Suspense fallback={
    <div className="flex justify-center items-center min-h-[400px]">
      <LoadingSpinner />
    </div>
  }>
    {children}
  </Suspense>
);

export const AppRouter = () => {
  return (
    <Routes>
      <Route path="/" element={<MainLayout />}>
        <Route index element={
          <SuspenseWrapper>
            <AlarmPage />
          </SuspenseWrapper>
        } />
        <Route path="timer" element={
          <SuspenseWrapper>
            <TimerPage />
          </SuspenseWrapper>
        } />
        <Route path="countdown" element={
          <SuspenseWrapper>
            <CountdownPage />
          </SuspenseWrapper>
        } />
        <Route path="stopwatch" element={
          <SuspenseWrapper>
            <StopwatchPage />
          </SuspenseWrapper>
        } />
        <Route path="clock" element={
          <SuspenseWrapper>
            <ClockPage />
          </SuspenseWrapper>
        } />
        <Route path="world-time" element={
          <SuspenseWrapper>
            <WorldTimePage />
          </SuspenseWrapper>
        } />
        <Route path="date-calculator" element={
          <SuspenseWrapper>
            <DateCalculatorPage />
          </SuspenseWrapper>
        } />
        <Route path="hours-calculator" element={
          <SuspenseWrapper>
            <HoursCalculatorPage />
          </SuspenseWrapper>
        } />
        <Route path="week-numbers" element={
          <SuspenseWrapper>
            <WeekNumbersPage />
          </SuspenseWrapper>
        } />
      </Route>
    </Routes>
  );
};