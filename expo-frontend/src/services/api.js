import axios from 'axios';

// Configuration
const API_BASE_URL = __DEV__ 
  ? 'http://10.0.0.1:3001/api'  // Development - use network IP for mobile device
  : 'https://your-production-url.com/api';  // Production

const GEMINI_API_KEY = 'AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY';

// Create axios instance with appropriate timeout
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 seconds for general API calls
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor for authentication
api.interceptors.request.use(
  (config) => {
    // Add Gemini API key to headers
    config.headers['X-Gemini-API-Key'] = GEMINI_API_KEY;
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      // Handle authentication errors
      console.log('Authentication error - redirecting to login');
    }
    
    return Promise.reject(error);
  }
);

export const basketballAPI = {
  // Health check
  healthCheck: async () => {
    try {
      const response = await api.get('/health');
      return response.data;
    } catch (error) {
      console.error('Health check failed:', error);
      return { status: 'offline' };
    }
  },

  // AI Status
  checkAIStatus: async () => {
    try {
      const response = await api.get('/ai/status');
      return response.data.connected;
    } catch (error) {
      console.error('AI status check failed:', error);
      return false;
    }
  },

  // Demo Analysis
  analyzeDemo: async () => {
    try {
      const response = await api.post('/analysis/demo', {
        videoFile: 'final_ball.mov'
      });
      return response.data;
    } catch (error) {
      console.error('Demo analysis failed:', error);
      throw new Error('Failed to analyze demo video');
    }
  },

  // Video Analysis - Simplified without sessions
  analyzeVideo: async (videoData) => {
    try {
      console.log('📤 Uploading video for analysis...', {
        uri: videoData.uri,
        type: videoData.type || videoData.mimeType,
        name: videoData.fileName || videoData.filename
      });

      const formData = new FormData();
      // Properly format file for React Native
      formData.append('video', {
        uri: videoData.uri,
        type: videoData.type || videoData.mimeType || 'video/mp4',
        name: videoData.fileName || videoData.filename || 'basketball_video.mp4',
      });

      const response = await api.post('/analysis/video', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        timeout: 120000, // 2 minutes for video processing with AI analysis
      });

      console.log('✅ Video analysis API response:', response.data);
      
      // Return the analysis results directly
      return response.data;
    } catch (error) {
      console.error('❌ Video analysis API failed:', error.response?.data || error.message);
      
      // Re-throw error so it can be handled by the calling function
      throw new Error(`Video analysis failed: ${error.response?.data?.error || error.message}`);
    }
  },
}; 