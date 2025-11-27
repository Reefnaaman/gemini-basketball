import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, Animated } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';

const ActionCard = ({ 
  title,
  subtitle,
  icon,
  onPress,
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  style,
  children
}) => {
  const [scaleAnim] = useState(new Animated.Value(1));
  const [opacityAnim] = useState(new Animated.Value(1));

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
    glass: {
      colors: ['rgba(31, 41, 55, 0.9)', 'rgba(55, 65, 81, 0.7)', 'rgba(31, 41, 55, 0.9)'],
      start: { x: 0, y: 0 },
      end: { x: 1, y: 1 },
      locations: [0, 0.5, 1]
    },
    outline: {
      colors: ['rgba(255, 107, 53, 0.1)', 'rgba(255, 140, 66, 0.1)', 'rgba(255, 107, 53, 0.1)'],
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
      titleSize: 14,
      subtitleSize: 12,
      iconSize: 20,
      minHeight: 60
    },
    medium: {
      padding: 16,
      borderRadius: 16,
      titleSize: 16,
      subtitleSize: 14,
      iconSize: 24,
      minHeight: 80
    },
    large: {
      padding: 20,
      borderRadius: 20,
      titleSize: 18,
      subtitleSize: 16,
      iconSize: 32,
      minHeight: 100
    }
  };

  const gradientConfig = gradientConfigs[variant];
  const sizeConfig = sizeConfigs[size];

  const handlePressIn = () => {
    if (disabled || loading) return;
    
    Animated.parallel([
      Animated.timing(scaleAnim, {
        toValue: 0.95,
        duration: 150,
        useNativeDriver: true,
      }),
      Animated.timing(opacityAnim, {
        toValue: 0.8,
        duration: 150,
        useNativeDriver: true,
      })
    ]).start();
  };

  const handlePressOut = () => {
    if (disabled || loading) return;
    
    Animated.parallel([
      Animated.timing(scaleAnim, {
        toValue: 1,
        duration: 150,
        useNativeDriver: true,
      }),
      Animated.timing(opacityAnim, {
        toValue: 1,
        duration: 150,
        useNativeDriver: true,
      })
    ]).start();
  };

  const animatedStyle = {
    transform: [{ scale: scaleAnim }],
    opacity: opacityAnim,
  };

  return (
    <Pressable
      onPress={onPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      disabled={disabled || loading}
      style={[styles.pressable, style]}
    >
      <Animated.View style={[animatedStyle]}>
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
              minHeight: sizeConfig.minHeight,
            },
            disabled && styles.disabled,
            variant === 'outline' && styles.outline
          ]}
        >
          {/* Main content */}
          <View style={styles.content}>
            {/* Header with icon and text */}
            <View style={styles.header}>
              {icon && (
                <View style={styles.iconContainer}>
                  <Ionicons 
                    name={icon} 
                    size={sizeConfig.iconSize} 
                    color={variant === 'outline' ? '#FF6B35' : '#FFFFFF'} 
                  />
                </View>
              )}
              
              <View style={styles.textContainer}>
                <Text style={[
                  styles.title,
                  { fontSize: sizeConfig.titleSize },
                  variant === 'outline' && styles.outlineText
                ]}>
                  {title}
                </Text>
                {subtitle && (
                  <Text style={[
                    styles.subtitle,
                    { fontSize: sizeConfig.subtitleSize },
                    variant === 'outline' && styles.outlineSubtext
                  ]}>
                    {subtitle}
                  </Text>
                )}
              </View>
            </View>

            {/* Custom children content */}
            {children && (
              <View style={styles.childrenContainer}>
                {children}
              </View>
            )}
          </View>

          {/* Loading indicator */}
          {loading && (
            <View style={styles.loadingOverlay}>
              <Ionicons name="hourglass" size={24} color="#FFFFFF" />
            </View>
          )}

          {/* Decorative elements */}
          <View style={styles.decorativeElements}>
            <View style={[styles.decorativeShape, { backgroundColor: 'rgba(255, 255, 255, 0.1)' }]} />
            <View style={[styles.decorativeShape, { backgroundColor: 'rgba(255, 255, 255, 0.05)' }]} />
          </View>

          {/* Action indicator */}
          {onPress && !disabled && !loading && (
            <View style={styles.actionIndicator}>
              <Ionicons 
                name="chevron-forward" 
                size={16} 
                color={variant === 'outline' ? '#FF6B35' : 'rgba(255, 255, 255, 0.6)'} 
              />
            </View>
          )}
        </LinearGradient>
      </Animated.View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  pressable: {
    marginVertical: 4,
  },
  container: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
    overflow: 'hidden',
    position: 'relative',
  },
  outline: {
    borderWidth: 2,
    borderColor: '#FF6B35',
  },
  disabled: {
    opacity: 0.5,
  },
  content: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    marginRight: 12,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    color: '#FFFFFF',
    fontWeight: '700',
    marginBottom: 2,
  },
  subtitle: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '500',
    lineHeight: 18,
  },
  outlineText: {
    color: '#FF6B35',
  },
  outlineSubtext: {
    color: 'rgba(255, 107, 53, 0.7)',
  },
  childrenContainer: {
    marginTop: 12,
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  decorativeElements: {
    position: 'absolute',
    top: 8,
    right: 8,
    flexDirection: 'column',
  },
  decorativeShape: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  actionIndicator: {
    position: 'absolute',
    top: 12,
    right: 12,
  },
});

export default ActionCard; 