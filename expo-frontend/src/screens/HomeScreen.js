import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { SafeAreaView } from 'react-native-safe-area-context';

import { basketballAPI } from '../services/api';

const { width } = Dimensions.get('window');

export default function HomeScreen({ navigation }) {
  const [aiStatus, setAiStatus] = useState('disconnected');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    checkAIConnection();
  }, []);

  const checkAIConnection = async () => {
    try {
      const connected = await basketballAPI.checkAIStatus();
      setAiStatus(connected ? 'connected' : 'disconnected');
    } catch (error) {
      console.error('AI status check failed:', error);
      setAiStatus('disconnected');
    }
  };

  const handleStartSession = () => {
    if (aiStatus !== 'connected') {
      return;
    }
    navigation.navigate('Camera');
  };

  const getAIStatusColor = () => {
    return aiStatus === 'connected' ? '#22C55E' : '#EF4444';
  };

  const getAIStatusText = () => {
    return aiStatus === 'connected' ? 'AI Connected' : 'AI Disconnected';
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView 
        style={styles.scrollView}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting}>Ready to dominate? 🏀</Text>
            <Text style={styles.subtitle}>Let's analyze your basketball shots</Text>
          </View>
          <View style={[styles.aiStatus, { backgroundColor: getAIStatusColor() }]}>
            <Text style={styles.aiStatusText}>{getAIStatusText()}</Text>
          </View>
        </View>

        {/* Hero Section */}
        <View style={styles.section}>
          <LinearGradient
            colors={['#FF6B35', '#F7931E']}
            style={styles.heroCard}
          >
            <View style={styles.heroContent}>
              <Ionicons name="basketball" size={48} color="#FFFFFF" />
              <Text style={styles.heroTitle}>START ANALYZING</Text>
              <Text style={styles.heroSubtitle}>
                Record or upload a basketball video to get AI-powered analysis
              </Text>
              <TouchableOpacity
                style={[
                  styles.heroButton,
                  { opacity: aiStatus !== 'connected' ? 0.5 : 1 }
                ]}
                onPress={handleStartSession}
                disabled={aiStatus !== 'connected'}
              >
                <Ionicons name="videocam" size={20} color="#FF6B35" />
                <Text style={styles.heroButtonText}>
                  {aiStatus === 'connected' ? 'Start Analysis' : 'AI Disconnected'}
                </Text>
              </TouchableOpacity>
            </View>
          </LinearGradient>
        </View>

        {/* Features Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What You'll Get</Text>
          <View style={styles.featuresGrid}>
            <View style={styles.featureCard}>
              <Ionicons name="target" size={32} color="#FF6B35" />
              <Text style={styles.featureTitle}>Shot Analysis</Text>
              <Text style={styles.featureText}>
                Detailed breakdown of each shot with accuracy metrics
              </Text>
            </View>
            
            <View style={styles.featureCard}>
              <Ionicons name="person" size={32} color="#FF6B35" />
              <Text style={styles.featureTitle}>AI Coaching</Text>
              <Text style={styles.featureText}>
                Get personalized feedback from our AI coach
              </Text>
            </View>
            
            <View style={styles.featureCard}>
              <Ionicons name="trending-up" size={32} color="#FF6B35" />
              <Text style={styles.featureTitle}>Improvement Tips</Text>
              <Text style={styles.featureText}>
                Specific recommendations to improve your game
              </Text>
            </View>
          </View>
        </View>

        {/* Instructions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>How It Works</Text>
          <View style={styles.instructionsList}>
            <View style={styles.instructionItem}>
              <View style={styles.instructionNumber}>
                <Text style={styles.instructionNumberText}>1</Text>
              </View>
              <Text style={styles.instructionText}>
                Record a video of your basketball shots or upload from gallery
              </Text>
            </View>
            
            <View style={styles.instructionItem}>
              <View style={styles.instructionNumber}>
                <Text style={styles.instructionNumberText}>2</Text>
              </View>
              <Text style={styles.instructionText}>
                Our AI analyzes each shot for accuracy and form
              </Text>
            </View>
            
            <View style={styles.instructionItem}>
              <View style={styles.instructionNumber}>
                <Text style={styles.instructionNumberText}>3</Text>
              </View>
              <Text style={styles.instructionText}>
                Get detailed feedback and tips to improve your game
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.bottomPadding} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111827',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 20,
  },
  greeting: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  subtitle: {
    fontSize: 16,
    color: '#9CA3AF',
    marginTop: 4,
  },
  aiStatus: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  aiStatusText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
  },
  section: {
    paddingHorizontal: 16,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  heroCard: {
    borderRadius: 20,
    padding: 24,
    alignItems: 'center',
  },
  heroContent: {
    alignItems: 'center',
  },
  heroTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 12,
    marginBottom: 8,
  },
  heroSubtitle: {
    fontSize: 16,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 20,
    opacity: 0.9,
  },
  heroButton: {
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    gap: 8,
  },
  heroButtonText: {
    color: '#FF6B35',
    fontSize: 16,
    fontWeight: '600',
  },
  featuresGrid: {
    gap: 16,
  },
  featureCard: {
    backgroundColor: '#1F2937',
    padding: 20,
    borderRadius: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#374151',
  },
  featureTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginTop: 12,
    marginBottom: 8,
  },
  featureText: {
    fontSize: 14,
    color: '#9CA3AF',
    textAlign: 'center',
    lineHeight: 20,
  },
  instructionsList: {
    gap: 16,
  },
  instructionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  instructionNumber: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#FF6B35',
    justifyContent: 'center',
    alignItems: 'center',
  },
  instructionNumberText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
  instructionText: {
    flex: 1,
    fontSize: 16,
    color: '#D1D5DB',
    lineHeight: 22,
  },
  bottomPadding: {
    height: 20,
  },
}); 