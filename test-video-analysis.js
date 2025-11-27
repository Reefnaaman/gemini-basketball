#!/usr/bin/env node

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const API_BASE_URL = 'http://localhost:3001/api';

async function testVideoAnalysis() {
  console.log('🎯 Testing Video Analysis Flow...\n');
  
  try {
    // 1. Test health check
    console.log('1. Testing health check...');
    const healthResponse = await axios.get(`${API_BASE_URL}/health`);
    console.log('✅ Health check passed:', healthResponse.data.status);
    
    // 2. Test AI status
    console.log('\n2. Testing AI status...');
    const aiResponse = await axios.get(`${API_BASE_URL}/ai/status`);
    console.log('✅ AI status:', aiResponse.data.connected ? 'Connected' : 'Disconnected');
    
    // 3. Test session stats
    console.log('\n3. Testing session stats...');
    const statsResponse = await axios.get(`${API_BASE_URL}/sessions/stats`);
    console.log('✅ Session stats:', statsResponse.data);
    
    // 4. Test recent sessions
    console.log('\n4. Testing recent sessions...');
    const recentResponse = await axios.get(`${API_BASE_URL}/sessions/recent`);
    console.log('✅ Recent sessions:', recentResponse.data.length, 'sessions');
    
    // 5. Test video analysis (requires a video file)
    console.log('\n5. Testing video analysis...');
    
    // Check if we have a test video file
    const testVideoPath = path.join(__dirname, 'test-video.mp4');
    if (!fs.existsSync(testVideoPath)) {
      console.log('⚠️  No test video file found. Skipping video analysis test.');
      console.log('   To test video analysis, place a video file at:', testVideoPath);
      return;
    }
    
    const formData = new FormData();
    formData.append('video', fs.createReadStream(testVideoPath));
    
    console.log('📤 Uploading video for analysis...');
    const analysisResponse = await axios.post(`${API_BASE_URL}/analysis/video`, formData, {
      headers: {
        ...formData.getHeaders(),
      },
      timeout: 60000, // 60 second timeout
    });
    
    console.log('✅ Video analysis completed!');
    console.log('📊 Analysis results:');
    console.log('   - Session ID:', analysisResponse.data.sessionId);
    console.log('   - Total shots:', analysisResponse.data.analysis.totalShots);
    console.log('   - Made shots:', analysisResponse.data.analysis.madeShots);
    console.log('   - Accuracy:', analysisResponse.data.analysis.accuracy + '%');
    console.log('   - Strengths:', analysisResponse.data.analysis.insights.strengths);
    console.log('   - Improvements:', analysisResponse.data.analysis.insights.improvements);
    
    // 6. Test retrieving session analysis
    console.log('\n6. Testing session analysis retrieval...');
    const sessionId = analysisResponse.data.sessionId;
    const sessionAnalysisResponse = await axios.get(`${API_BASE_URL}/sessions/${sessionId}/analysis`);
    console.log('✅ Session analysis retrieved:', sessionAnalysisResponse.data.summary);
    
    console.log('\n🎉 All tests passed! Video analysis flow is working correctly.');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
    process.exit(1);
  }
}

// Run the test
testVideoAnalysis(); 