#!/bin/bash

# Get the network IP address
NETWORK_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)

if [ -z "$NETWORK_IP" ]; then
    NETWORK_IP="172.21.12.176"  # Fallback to your current IP
fi

echo "🏀 Basketball Coach AI - Starting Services"
echo "📡 Network IP: $NETWORK_IP"
echo "================================"

# Update frontend API configuration with current network IP
echo "🔄 Updating network configuration..."
node update-network-config.js

# Kill any existing processes
echo "🔄 Cleaning up existing processes..."
pkill -f "node server.js" 2>/dev/null
pkill -f "node qr-server.js" 2>/dev/null
pkill -f "expo start" 2>/dev/null

sleep 2

# Start backend server
echo "🚀 Starting backend server on port 3001..."
cd backend-server && npm start &
BACKEND_PID=$!

sleep 3

# Check if backend is running
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend server is running"
else
    echo "❌ Backend server failed to start"
    exit 1
fi

# Start QR server
echo "🚀 Starting QR server on port 3006..."
cd .. && node qr-server.js &
QR_PID=$!

sleep 2

# Start Expo
echo "🚀 Starting Expo on port 8082..."
cd expo-frontend && npx expo start --lan --port 8082 --clear &
EXPO_PID=$!

sleep 5

echo ""
echo "================================"
echo "✅ All services started!"
echo ""
echo "📱 Mobile App URL: exp://$NETWORK_IP:8082"
echo "🌐 QR Code Page: http://localhost:3006"
echo "🔧 Backend API: http://localhost:3001/api"
echo ""
echo "Press Ctrl+C to stop all services"
echo "================================"

# Wait for user to press Ctrl+C
trap 'echo "Stopping services..."; kill $BACKEND_PID $QR_PID $EXPO_PID 2>/dev/null; exit' INT
wait 
 
 