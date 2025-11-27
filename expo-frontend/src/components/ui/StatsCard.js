import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

const StatsCard = ({ 
  title,
  value,
  subtitle,
  icon,
  trend,
  variant = 'primary',
  size = 'medium',
  onPress
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
    success: {
      colors: ['#22C55E', '#16A34A', '#22C55E'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    warning: {
      colors: ['#F59E0B', '#D97706', '#F59E0B'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    glass: {
      colors: ['rgba(31, 41, 55, 0.9)', 'rgba(55, 65, 81, 0.7)', 'rgba(31, 41, 55, 0.9)'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    }
  };

  // Size configurations
  const sizeConfigs = {
    small: {
      padding: 12,
      borderRadius: 12,
      titleSize: 12,
      valueSize: 20,
      subtitleSize: 10,
      iconSize: 20
    },
    medium: {
      padding: 16,
      borderRadius: 16,
      titleSize: 14,
      valueSize: 28,
      subtitleSize: 12,
      iconSize: 24
    },
    large: {
      padding: 20,
      borderRadius: 20,
      titleSize: 16,
      valueSize: 36,
      subtitleSize: 14,
      iconSize: 32
    }
  };

  const gradientConfig = gradientConfigs[variant];
  const sizeConfig = sizeConfigs[size];

  const getTrendColor = () => {
    if (!trend) return '#9CA3AF';
    return trend > 0 ? '#22C55E' : trend < 0 ? '#EF4444' : '#9CA3AF';
  };

  const getTrendIcon = () => {
    if (!trend) return null;
    if (trend > 0) return 'trending-up';
    if (trend < 0) return 'trending-down';
    return 'remove';
  };

  return (
    <LinearGradient
      colors={gradientConfig.colors}
      start={gradientConfig.start}
      end={gradientConfig.end}
      locations={gradientConfig.locations}
      style={[
        styles.container,
        {
          padding: sizeConfig.padding,
          borderRadius: sizeConfig.borderRadius,
        }
      ]}
    >
      {/* Header with icon and title */}
      <View style={styles.header}>
        {icon && (
          <Ionicons 
            name={icon} 
            size={sizeConfig.iconSize} 
            color="rgba(255, 255, 255, 0.8)" 
            style={styles.icon}
          />
        )}
        <Text style={[
          styles.title,
          { fontSize: sizeConfig.titleSize }
        ]}>
          {title}
        </Text>
      </View>

      {/* Main value */}
      <View style={styles.valueContainer}>
        <Text style={[
          styles.value,
          { fontSize: sizeConfig.valueSize }
        ]}>
          {value}
        </Text>
        {trend !== undefined && (
          <View style={styles.trendContainer}>
            <Ionicons 
              name={getTrendIcon()} 
              size={16} 
              color={getTrendColor()}
            />
            <Text style={[
              styles.trendText,
              { color: getTrendColor() }
            ]}>
              {Math.abs(trend)}%
            </Text>
          </View>
        )}
      </View>

      {/* Subtitle */}
      {subtitle && (
        <Text style={[
          styles.subtitle,
          { fontSize: sizeConfig.subtitleSize }
        ]}>
          {subtitle}
        </Text>
      )}

      {/* Decorative elements */}
      <View style={styles.decorativeElements}>
        <View style={[styles.decorativeDot, { backgroundColor: 'rgba(255, 255, 255, 0.1)' }]} />
        <View style={[styles.decorativeDot, { backgroundColor: 'rgba(255, 255, 255, 0.05)' }]} />
        <View style={[styles.decorativeDot, { backgroundColor: 'rgba(255, 255, 255, 0.02)' }]} />
      </View>
    </LinearGradient>
  );
};

const styles = StyleSheet.create({
  container: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
    overflow: 'hidden',
    position: 'relative',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  icon: {
    marginRight: 8,
  },
  title: {
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  valueContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  value: {
    color: '#FFFFFF',
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  trendContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  trendText: {
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 4,
  },
  subtitle: {
    color: 'rgba(255, 255, 255, 0.6)',
    fontWeight: '500',
    lineHeight: 16,
  },
  decorativeElements: {
    position: 'absolute',
    top: 12,
    right: 12,
    flexDirection: 'row',
  },
  decorativeDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginLeft: 4,
  },
});

export default StatsCard; 