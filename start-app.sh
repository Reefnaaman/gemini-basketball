#!/bin/bash
echo "🏀 Starting Basketball Coach AI Complete System..."
echo "Opening backend and frontend in separate terminal windows..."

# For macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Start backend in new terminal
    osascript -e 'tell application "Terminal" to do script "cd \"'$(pwd)'\" && ./start-backend.sh"'
    
    # Wait a moment then start frontend
    sleep 2
    osascript -e 'tell application "Terminal" to do script "cd \"'$(pwd)'\" && ./start-frontend.sh"'
    
    echo "✅ Both backend and frontend started in separate terminals"
    echo "📱 Scan the QR code with Expo Go app to test on your device"
else
    echo "ℹ️  Please run the following commands in separate terminals:"
    echo "   Terminal 1: ./start-backend.sh"
    echo "   Terminal 2: ./start-frontend.sh"
fi
