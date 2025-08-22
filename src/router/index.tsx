import { Routes, Route } from 'react-router-dom';
import { MainLayout } from '@/layouts/MainLayout';
import { AlarmPage } from '@/pages/AlarmPage';
import { TimerPage } from '@/pages/TimerPage';
import { CountdownPage } from '@/pages/CountdownPage';
import { StopwatchPage } from '@/pages/StopwatchPage';
import { ClockPage } from '@/pages/ClockPage';
import { WorldTimePage } from '@/pages/WorldTimePage';
import { DateCalculatorPage } from '@/pages/DateCalculatorPage';
import { HoursCalculatorPage } from '@/pages/HoursCalculatorPage';
import { WeekNumbersPage } from '@/pages/WeekNumbersPage';

export const AppRouter = () => {
  return (
    <Routes>
      <Route path="/" element={<MainLayout />}>
        <Route index element={<AlarmPage />} />
        <Route path="timer" element={<TimerPage />} />
        <Route path="countdown" element={<CountdownPage />} />
        <Route path="stopwatch" element={<StopwatchPage />} />
        <Route path="clock" element={<ClockPage />} />
        <Route path="world-time" element={<WorldTimePage />} />
        <Route path="date-calculator" element={<DateCalculatorPage />} />
        <Route path="hours-calculator" element={<HoursCalculatorPage />} />
        <Route path="week-numbers" element={<WeekNumbersPage />} />
      </Route>
    </Routes>
  );
};