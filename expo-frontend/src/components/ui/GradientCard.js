import React from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const GradientCard = ({ 
  children, 
  style, 
  variant = 'primary',
  onPress,
  disabled = false,
  elevation = 'medium'
}) => {
  // Gradient configurations for different variants
  const gradientConfigs = {
    primary: {
      colors: ['#FF6B35', '#FF8C42', '#FF6B35'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    secondary: {
      colors: ['#1F2937', '#374151', '#1F2937'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    accent: {
      colors: ['#FF6B35', '#FF4500', '#FF6B35'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 0 },
      locations: [0, 0.5, 1]
    },
    success: {
      colors: ['#10B981', '#34D399', '#10B981'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    warning: {
      colors: ['#F59E0B', '#FBBF24', '#F59E0B'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    outline: {
      colors: ['rgba(31, 41, 55, 0.1)', 'rgba(55, 65, 81, 0.1)', 'rgba(31, 41, 55, 0.1)'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    dark: {
      colors: ['#111827', '#1F2937', '#374151'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.3, 1]
    },
    glass: {
      colors: ['rgba(31, 41, 55, 0.8)', 'rgba(55, 65, 81, 0.6)', 'rgba(31, 41, 55, 0.8)'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    }
  };

  // Elevation configurations
  const elevationStyles = {
    low: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 2,
    },
    medium: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.15,
      shadowRadius: 8,
      elevation: 4,
    },
    high: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 8 },
      shadowOpacity: 0.2,
      shadowRadius: 16,
      elevation: 8,
    },
    basketball: {
      shadowColor: '#FF6B35',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.3,
      shadowRadius: 12,
      elevation: 6,
    }
  };

  const gradientConfig = gradientConfigs[variant];
  const elevationStyle = elevationStyles[elevation];

  const CardContent = () => (
    <LinearGradient
      colors={gradientConfig.colors}
      start={gradientConfig.start}
      end={gradientConfig.end}
      locations={gradientConfig.locations}
      style={[
        styles.gradient,
        elevationStyle,
        style
      ]}
    >
      <View style={styles.content}>
        {children}
      </View>
    </LinearGradient>
  );

  if (onPress && !disabled) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.pressable,
          pressed && styles.pressed
        ]}
      >
        <CardContent />
      </Pressable>
    );
  }

  return <CardContent />;
};

const styles = StyleSheet.create({
  gradient: {
    borderRadius: 16,
    overflow: 'hidden',
    minHeight: 60,
  },
  content: {
    padding: 16,
    flex: 1,
  },
  pressable: {
    borderRadius: 16,
  },
  pressed: {
    opacity: 0.9,
    transform: [{ scale: 0.98 }],
  },
});

export default GradientCard; 