import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function ResultsScreen({ navigation, route }) {
  const { analysisData } = route.params || {};

  // Fallback data if no analysis provided
  const analysis = analysisData || {
    totalShots: 0,
    madeShots: 0,
    accuracy: 0,
    insights: {
      strengths: ['No data available'],
      improvements: ['Upload a video to get analysis']
    },
    shots: []
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#FFFFFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>🏀 Shot Analysis</Text>
        <TouchableOpacity style={styles.shareButton}>
          <Ionicons name="share-outline" size={24} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Performance Overview */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Your Performance</Text>
          
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <LinearGradient
                colors={['#22C55E', '#16A34A']}
                style={styles.statIcon}
              >
                <Ionicons name="basketball" size={24} color="white" />
              </LinearGradient>
              <Text style={styles.statValue}>
                {analysis.madeShots}/{analysis.totalShots}
              </Text>
              <Text style={styles.statLabel}>Shots Made</Text>
            </View>
            
            <View style={styles.statCard}>
              <LinearGradient
                colors={['#F97316', '#EA580C']}
                style={styles.statIcon}
              >
                <Ionicons name="trending-up" size={24} color="white" />
              </LinearGradient>
              <Text style={styles.statValue}>
                {Math.round(analysis.accuracy)}%
              </Text>
              <Text style={styles.statLabel}>Accuracy</Text>
            </View>
          </View>
        </View>

        {/* Shot-by-Shot Analysis */}
        {analysis.shots && analysis.shots.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Shot-by-Shot Analysis</Text>
            {analysis.shots.map((shot, index) => (
              <View key={index} style={styles.shotCard}>
                <View style={styles.shotHeader}>
                  <Text style={styles.shotTitle}>
                    Shot #{shot.id} - {shot.type} 
                    <Text style={shot.outcome === 'Made' ? styles.shotMade : styles.shotMissed}>
                      {shot.outcome === 'Made' ? ' ✅' : ' ❌'}
                    </Text>
                  </Text>
                  <Text style={styles.shotTime}>{shot.timestamp}s</Text>
                </View>
                {shot.mjFeedback && (
                  <View style={styles.mjFeedbackContainer}>
                    <Text style={styles.mjFeedbackLabel}>🐐 MJ Says:</Text>
                    <Text style={styles.mjFeedbackText}>"{shot.mjFeedback}"</Text>
                  </View>
                )}
              </View>
            ))}
          </View>
        )}

        {/* AI Insights */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🤖 AI Insights</Text>
          
          <View style={styles.insightCard}>
            <View style={styles.insightHeader}>
              <Ionicons name="checkmark-circle" size={24} color="#22C55E" />
              <Text style={styles.insightTitle}>What You Did Right</Text>
            </View>
            {analysis.insights.strengths.map((strength, index) => (
              <View key={index} style={styles.insightItem}>
                <Ionicons name="checkmark" size={16} color="#22C55E" />
                <Text style={styles.insightText}>{strength}</Text>
              </View>
            ))}
          </View>

          <View style={styles.insightCard}>
            <View style={styles.insightHeader}>
              <Ionicons name="alert-circle" size={24} color="#F97316" />
              <Text style={styles.insightTitle}>What Needs Work</Text>
            </View>
            {analysis.insights.improvements.map((improvement, index) => (
              <View key={index} style={styles.insightItem}>
                <Ionicons name="arrow-up" size={16} color="#F97316" />
                <Text style={styles.insightText}>{improvement}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Action Buttons */}
        <View style={styles.actionSection}>
          <TouchableOpacity
            style={styles.primaryButton}
            onPress={() => navigation.navigate('Camera')}
          >
            <Ionicons name="videocam" size={20} color="white" />
            <Text style={styles.primaryButtonText}>Analyze Another Video</Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={() => navigation.navigate('Home')}
          >
            <Ionicons name="home" size={20} color="#FF6B35" />
            <Text style={styles.secondaryButtonText}>Back to Home</Text>
          </TouchableOpacity>
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#000000',
    borderBottomWidth: 1,
    borderBottomColor: '#374151',
  },
  backButton: {
    padding: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  shareButton: {
    padding: 8,
  },
  content: {
    flex: 1,
  },
  section: {
    padding: 16,
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  statsGrid: {
    flexDirection: 'row',
    gap: 12,
  },
  statCard: {
    flex: 1,
    backgroundColor: '#1F2937',
    padding: 16,
    borderRadius: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#374151',
  },
  statIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#9CA3AF',
    textAlign: 'center',
  },
  shotCard: {
    backgroundColor: '#1F2937',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#374151',
  },
  shotHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  shotTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  shotMade: {
    color: '#22C55E',
  },
  shotMissed: {
    color: '#EF4444',
  },
  shotTime: {
    fontSize: 14,
    color: '#9CA3AF',
  },
  mjFeedbackContainer: {
    backgroundColor: '#374151',
    padding: 12,
    borderRadius: 8,
    marginTop: 8,
  },
  mjFeedbackLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FF6B35',
    marginBottom: 4,
  },
  mjFeedbackText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontStyle: 'italic',
    lineHeight: 20,
  },
  insightCard: {
    backgroundColor: '#1F2937',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#374151',
  },
  insightHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  insightTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
  },
  insightItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  insightText: {
    fontSize: 14,
    color: '#D1D5DB',
    marginLeft: 8,
    flex: 1,
  },
  actionSection: {
    padding: 16,
    gap: 12,
  },
  primaryButton: {
    backgroundColor: '#FF6B35',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    gap: 8,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FF6B35',
    gap: 8,
  },
  secondaryButtonText: {
    color: '#FF6B35',
    fontSize: 16,
    fontWeight: '600',
  },
  bottomPadding: {
    height: 20,
  },
}); 