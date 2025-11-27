import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Modal,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { LinearGradient } from 'expo-linear-gradient';
import { SafeAreaView } from 'react-native-safe-area-context';

import { basketballAPI } from '../services/api';

const { width, height } = Dimensions.get('window');

export default function CameraScreen({ navigation }) {
  const [permission, requestPermission] = useCameraPermissions();
  const [isRecording, setIsRecording] = useState(false);
  const [cameraType, setCameraType] = useState('back');
  const [analysisModal, setAnalysisModal] = useState({
    visible: false,
    step: '',
    progress: 0,
  });
  
  const cameraRef = useRef(null);

  useEffect(() => {
    // Request permissions on component mount
    if (!permission?.granted) {
      requestPermission();
    }
  }, [permission, requestPermission]);

  const startRecording = async () => {
    if (!cameraRef.current) return;
    
    try {
      setIsRecording(true);
      const video = await cameraRef.current.recordAsync({
        quality: '720p',
        maxDuration: 60, // 1 minute max
      });
      
      setIsRecording(false);
      
      if (video) {
        await analyzeVideo(video);
      }
    } catch (error) {
      console.error('Recording failed:', error);
      setIsRecording(false);
      Alert.alert('Error', 'Failed to record video');
    }
  };

  const stopRecording = () => {
    if (cameraRef.current && isRecording) {
      cameraRef.current.stopRecording();
      setIsRecording(false);
    }
  };

  const pickVideoFromLibrary = async () => {
    try {
      const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();
      
      if (!permissionResult.granted) {
        Alert.alert('Permission Required', 'Please grant access to your photo library to select videos.');
        return;
      }

      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Videos,
        allowsEditing: false,
        quality: 0.8,
      });

      if (!result.canceled && result.assets && result.assets.length > 0) {
        const selectedVideo = result.assets[0];
        console.log('📹 Selected video:', selectedVideo.uri);
        
        // Format video data for analysis
        const videoData = {
          uri: selectedVideo.uri,
          type: selectedVideo.type || 'video/mp4',
          fileName: selectedVideo.fileName || 'selected_video.mp4',
        };
        
        await analyzeVideo(videoData);
      }
    } catch (error) {
      console.error('Error picking video:', error);
      Alert.alert('Error', 'Failed to select video from library');
    }
  };

  const analyzeVideo = async (media) => {
    try {
      console.log('🎯 Starting video analysis...');
      
      // Show analysis modal
      setAnalysisModal({
        visible: true,
        step: '🏀 Preparing Analysis...',
        progress: 25,
      });

      // Step 2: AI Analysis
      setAnalysisModal(prev => ({
        ...prev,
        step: `🤖 AI Analyzing Video...`,
        progress: 50
      }));
      
      const analysisResult = await basketballAPI.analyzeVideo(media);

      console.log('✅ Analysis completed:', analysisResult);

      // Step 3: Processing results
      setAnalysisModal(prev => ({
        ...prev,
        step: '📊 Processing Results...',
        progress: 90
      }));

      await new Promise(resolve => setTimeout(resolve, 1000));

      // Complete the progress
      setAnalysisModal(prev => ({
        ...prev,
        step: '✅ Analysis Complete!',
        progress: 100
      }));

      await new Promise(resolve => setTimeout(resolve, 800));

      // Hide modal
      setAnalysisModal({
        visible: false,
        step: '',
        progress: 0,
      });

      // Navigate to results screen with analysis data
      console.log('🚀 Navigating to results with analysis data');
      navigation.navigate('Results', { 
        analysisData: analysisResult.analysis 
      });

    } catch (error) {
      console.error('❌ Error analyzing video:', error);
      
      // Hide modal
      setAnalysisModal({
        visible: false,
        step: '',
        progress: 0,
      });

      // Show error alert
      Alert.alert(
        'Analysis Failed',
        'Failed to analyze video. Please try again.',
        [{ text: 'OK' }]
      );
    }
  };

  const toggleCameraType = () => {
    setCameraType(current => (current === 'back' ? 'front' : 'back'));
  };

  if (!permission) {
    return (
      <View style={styles.container}>
        <Text style={styles.message}>Requesting camera permissions...</Text>
      </View>
    );
  }

  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text style={styles.message}>Camera access is required to record videos</Text>
        <TouchableOpacity style={styles.permissionButton} onPress={requestPermission}>
          <Text style={styles.permissionButtonText}>Grant Permission</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <CameraView
        ref={cameraRef}
        style={styles.camera}
        facing={cameraType}
        mode="video"
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => navigation.goBack()}
          >
            <Ionicons name="close" size={24} color="#FFFFFF" />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Basketball Coach</Text>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={toggleCameraType}
          >
            <Ionicons name="camera-reverse" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        {/* Recording indicator */}
        {isRecording && (
          <View style={styles.recordingIndicator}>
            <View style={styles.recordingDot} />
            <Text style={styles.recordingText}>Recording...</Text>
          </View>
        )}

        {/* Bottom controls */}
        <View style={styles.bottomControls}>
          <TouchableOpacity
            style={styles.libraryButton}
            onPress={pickVideoFromLibrary}
          >
            <Ionicons name="images" size={24} color="#FFFFFF" />
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.recordButton, isRecording && styles.recordButtonActive]}
            onPress={isRecording ? stopRecording : startRecording}
          >
            <View style={[styles.recordButtonInner, isRecording && styles.recordButtonInnerActive]} />
          </TouchableOpacity>

          <View style={styles.placeholder} />
        </View>
      </CameraView>

      {/* Analysis Modal */}
      <Modal
        visible={analysisModal.visible}
        transparent={true}
        animationType="fade"
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Analyzing Your Shots</Text>
            <Text style={styles.modalStep}>{analysisModal.step}</Text>
            
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View 
                  style={[
                    styles.progressFill, 
                    { width: `${analysisModal.progress}%` }
                  ]} 
                />
              </View>
              <Text style={styles.progressText}>{analysisModal.progress}%</Text>
            </View>
            
            <ActivityIndicator size="large" color="#FF6B35" style={styles.spinner} />
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  camera: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 20,
  },
  headerButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  recordingIndicator: {
    position: 'absolute',
    top: 80,
    left: 20,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 0, 0, 0.8)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  recordingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#FFFFFF',
    marginRight: 8,
  },
  recordingText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  bottomControls: {
    position: 'absolute',
    bottom: 50,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 50,
  },
  libraryButton: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordButtonActive: {
    backgroundColor: 'rgba(255, 0, 0, 0.8)',
  },
  recordButtonInner: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#FF0000',
  },
  recordButtonInnerActive: {
    width: 30,
    height: 30,
    borderRadius: 6,
    backgroundColor: '#FFFFFF',
  },
  placeholder: {
    width: 50,
    height: 50,
  },
  message: {
    color: '#FFFFFF',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 100,
  },
  permissionButton: {
    backgroundColor: '#FF6B35',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    marginTop: 20,
    alignSelf: 'center',
  },
  permissionButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#1F2937',
    borderRadius: 20,
    padding: 30,
    alignItems: 'center',
    width: width * 0.8,
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 10,
  },
  modalStep: {
    fontSize: 16,
    color: '#9CA3AF',
    marginBottom: 20,
    textAlign: 'center',
  },
  progressContainer: {
    width: '100%',
    marginBottom: 20,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#374151',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#FF6B35',
    borderRadius: 4,
  },
  progressText: {
    color: '#FFFFFF',
    fontSize: 14,
    textAlign: 'center',
    marginTop: 8,
  },
  spinner: {
    marginTop: 10,
  },
}); 