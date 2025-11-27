import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

export default function ProfileScreen({ navigation }) {
  const playerStats = {
    name: "Basketball Player",
    level: "Beginner",
    sessionsCompleted: 0,
    totalShots: 0,
    accuracy: 0,
    bestAccuracy: 0,
    favoriteShot: "Jump Shot",
    joinDate: new Date().toLocaleDateString(),
  };

  const profileSections = [
    {
      title: "Player Info",
      items: [
        { icon: "person", label: "Name", value: playerStats.name },
        { icon: "trophy", label: "Level", value: playerStats.level },
        { icon: "calendar", label: "Joined", value: playerStats.joinDate },
      ]
    },
    {
      title: "Quick Stats",
      items: [
        { icon: "basketball", label: "Sessions", value: playerStats.sessionsCompleted },
        { icon: "target", label: "Total Shots", value: playerStats.totalShots },
        { icon: "stats-chart", label: "Avg Accuracy", value: `${playerStats.accuracy}%` },
      ]
    },
    {
      title: "Preferences",
      items: [
        { icon: "settings", label: "Settings", value: "Configure", action: true },
        { icon: "help-circle", label: "Help & Support", value: "Get Help", action: true },
        { icon: "information-circle", label: "About", value: "v1.0.0", action: true },
      ]
    }
  ];

  const handleSectionPress = (item) => {
    if (item.action) {
      // Handle action items
      switch (item.label) {
        case "Settings":
          // Navigate to settings if implemented
          break;
        case "Help & Support":
          // Navigate to help if implemented
          break;
        case "About":
          // Show about info
          break;
      }
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Profile</Text>
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <LinearGradient
            colors={['#FF6B35', '#F7931E']}
            style={styles.profileGradient}
          >
            <View style={styles.avatarContainer}>
              <Ionicons name="person" size={48} color="#FFFFFF" />
            </View>
            <Text style={styles.playerName}>{playerStats.name}</Text>
            <Text style={styles.playerLevel}>{playerStats.level}</Text>
          </LinearGradient>
        </View>

        {/* Profile Sections */}
        {profileSections.map((section, sectionIndex) => (
          <View key={sectionIndex} style={styles.section}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            <View style={styles.sectionContent}>
              {section.items.map((item, itemIndex) => (
                <TouchableOpacity
                  key={itemIndex}
                  style={styles.sectionItem}
                  onPress={() => handleSectionPress(item)}
                  disabled={!item.action}
                >
                  <View style={styles.itemLeft}>
                    <Ionicons name={item.icon} size={20} color="#FF6B35" />
                    <Text style={styles.itemLabel}>{item.label}</Text>
                  </View>
                  <View style={styles.itemRight}>
                    <Text style={styles.itemValue}>{item.value}</Text>
                    {item.action && (
                      <Ionicons name="chevron-forward" size={16} color="#9CA3AF" />
                    )}
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ))}

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>
            Basketball Coach AI • Powered by Gemini
          </Text>
        </View>
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
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#000000',
    borderBottomWidth: 1,
    borderBottomColor: '#374151',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  scrollView: {
    flex: 1,
  },
  profileCard: {
    margin: 16,
    borderRadius: 16,
    overflow: 'hidden',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  profileGradient: {
    padding: 24,
    alignItems: 'center',
  },
  avatarContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  playerName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  playerLevel: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  section: {
    marginHorizontal: 16,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  sectionContent: {
    backgroundColor: '#1F2937',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#374151',
  },
  sectionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#374151',
  },
  itemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  itemLabel: {
    fontSize: 16,
    color: '#FFFFFF',
    marginLeft: 12,
  },
  itemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  itemValue: {
    fontSize: 16,
    color: '#9CA3AF',
    marginRight: 8,
  },
  footer: {
    padding: 24,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
}); 