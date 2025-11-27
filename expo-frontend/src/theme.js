import { DefaultTheme } from 'react-native-paper';

export const basketballTheme = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...DefaultTheme.colors,
    primary: '#FF6B35', // Basketball orange
    secondary: '#004225', // Court green
    accent: '#FFD700', // Gold accent
    background: '#111827', // Dark gray-900
    surface: '#000000', // Black for cards
    text: '#FFFFFF',
    onSurface: '#FFFFFF',
    disabled: '#6B7280',
    placeholder: '#9CA3AF',
    backdrop: 'rgba(0, 0, 0, 0.7)',
    notification: '#EF4444',
    // Custom basketball colors
    success: '#10B981',
    warning: '#F59E0B',
    info: '#3B82F6',
    shot_made: '#10B981',
    shot_missed: '#EF4444',
    form_excellent: '#10B981',
    form_good: '#F59E0B',
    form_needs_work: '#EF4444',
    // New modern colors
    gray900: '#111827',
    gray800: '#1F2937',
    gray700: '#374151',
    gray600: '#4B5563',
    gray500: '#6B7280',
    gray400: '#9CA3AF',
    gray300: '#D1D5DB',
    orange500: '#F97316',
    orange600: '#EA580C',
    green500: '#22C55E',
    green600: '#16A34A',
    red500: '#EF4444',
    red600: '#DC2626',
    purple500: '#A855F7',
    purple600: '#9333EA',
    blue500: '#3B82F6',
    blue600: '#2563EB',
  },
};

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const borderRadius = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  round: 50,
}; 