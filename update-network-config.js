#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');

// Function to get the best network IP
function getNetworkIP() {
  const networkInterfaces = os.networkInterfaces();
  const validIPs = [];
  
  for (const [name, interfaces] of Object.entries(networkInterfaces)) {
    for (const interface of interfaces) {
      if (interface.family === 'IPv4' && !interface.internal) {
        validIPs.push({
          ip: interface.address,
          name: name,
          priority: name.includes('en0') ? 1 : name.includes('en') ? 2 : 3
        });
      }
    }
  }
  
  // Sort by priority and return the best one
  validIPs.sort((a, b) => a.priority - b.priority);
  return validIPs[0]?.ip || '172.21.12.176';
}

// Update the API configuration file
function updateApiConfig() {
  const networkIP = getNetworkIP();
  const apiFilePath = path.join(__dirname, 'expo-frontend', 'src', 'services', 'api.js');
  
  try {
    // Read the current file
    let content = fs.readFileSync(apiFilePath, 'utf8');
    
    // Update the API_BASE_URL with the current network IP
    const regex = /const API_BASE_URL = __DEV__\s*\?\s*'http:\/\/[\d.]+:3001\/api'/;
    const newUrl = `const API_BASE_URL = __DEV__ \n  ? 'http://${networkIP}:3001/api'`;
    
    content = content.replace(regex, newUrl);
    
    // Write the updated content back
    fs.writeFileSync(apiFilePath, content, 'utf8');
    
    console.log(`✅ Updated API configuration to use network IP: ${networkIP}`);
    console.log(`📱 Frontend will connect to: http://${networkIP}:3001/api`);
    
    return networkIP;
  } catch (error) {
    console.error('❌ Failed to update API configuration:', error.message);
    return null;
  }
}

// Run the update
const networkIP = updateApiConfig();

if (networkIP) {
  console.log('\n🏀 Basketball Coach AI - Network Configuration Updated');
  console.log('================================================');
  console.log(`📡 Network IP: ${networkIP}`);
  console.log(`🔧 Backend API: http://${networkIP}:3001/api`);
  console.log(`📱 Expo URL: exp://${networkIP}:8082`);
  console.log(`🌐 QR Code: http://localhost:3006`);
  console.log('================================================\n');
} 
 
 