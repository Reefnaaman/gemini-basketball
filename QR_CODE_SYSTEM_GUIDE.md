# 🏀 Basketball Coach AI - QR Code System Guide

## Overview

The QR code system automatically detects your network IP and generates the correct connection URL for your mobile device. It includes:

1. **Dynamic Network Detection**: Automatically finds your current network IP
2. **Auto-Refreshing QR Page**: Updates every 30 seconds to reflect network changes
3. **Network Configuration Script**: Updates frontend API URLs automatically
4. **Service Status Monitoring**: Shows real-time status of all services

## Components

### 1. QR Server (`qr-server.js`)
- **Port**: 3006
- **Features**:
  - Dynamic network IP detection
  - Auto-refreshing web page (every 30 seconds)
  - Service status indicators
  - Beautiful UI with instructions
  - API endpoint for network info: `http://localhost:3006/api/network`

### 2. Network Config Updater (`update-network-config.js`)
- Automatically updates `expo-frontend/src/services/api.js` with current network IP
- Run with: `node update-network-config.js`
- Integrated into the start script

### 3. Start Services Script (`start-services.sh`)
- Detects network IP
- Updates frontend configuration
- Starts all services in correct order
- Shows connection URLs

## Quick Start

### Option 1: Use the Start Script (Recommended)
```bash
./start-services.sh
```

This will:
1. Detect your network IP
2. Update frontend API configuration
3. Start backend server (port 3001)
4. Start QR server (port 3006)
5. Start Expo (port 8082)
6. Display all connection URLs

### Option 2: Manual Start
```bash
# 1. Update network configuration
node update-network-config.js

# 2. Start backend
cd backend-server && npm start

# 3. Start QR server (in new terminal)
node qr-server.js

# 4. Start Expo (in new terminal)
cd expo-frontend && npx expo start --lan --port 8082
```

## Accessing the QR Code

1. Open your browser to: `http://localhost:3006`
2. You'll see:
   - Current network IP in the top-right
   - QR code that updates automatically
   - Connection URL (exp://YOUR_IP:8082)
   - Service status indicators
   - Connection instructions

## Features

### Auto-Refresh
The QR page refreshes every 30 seconds to:
- Update network IP if it changes
- Regenerate QR code with new IP
- Check service status

### Network Priority
The system prioritizes network interfaces:
1. `en0` (typically Wi-Fi on Mac)
2. Other `en*` interfaces
3. Any other IPv4 interfaces

### API Endpoints
- Health Check: `http://localhost:3001/api/health`
- Network Info: `http://localhost:3006/api/network`

## Troubleshooting

### QR Code Shows Wrong IP
1. Refresh the page (it auto-refreshes every 30 seconds)
2. Run `node update-network-config.js` to update frontend
3. Restart services with `./start-services.sh`

### Can't Connect from Phone
1. Ensure phone is on same Wi-Fi network
2. Check firewall settings
3. Verify all services are running (check status indicators)
4. Try manual URL entry in Expo Go app

### Services Not Starting
1. Check for port conflicts:
   ```bash
   lsof -i :3001  # Backend
   lsof -i :3006  # QR Server
   lsof -i :8082  # Expo
   ```
2. Kill existing processes:
   ```bash
   pkill -f "node server.js"
   pkill -f "node qr-server.js"
   pkill -f "expo start"
   ```

## Network Configuration

The system automatically updates these configurations:
- Frontend API URL: `expo-frontend/src/services/api.js`
- QR Code URL: Dynamic based on current network
- Expo connection: Uses `--lan` flag for network access

## Best Practices

1. **Always use the start script** for consistent configuration
2. **Check the QR page** at `http://localhost:3006` to verify network settings
3. **Restart services** if you change networks (Wi-Fi to Ethernet, etc.)
4. **Keep Expo Go app updated** on your phone for best compatibility

## Example Output

When everything is working correctly:
```
🏀 Basketball Coach AI - Starting Services
📡 Network IP: 172.21.12.176
================================
✅ All services started!

📱 Mobile App URL: exp://172.21.12.176:8082
🌐 QR Code Page: http://localhost:3006
🔧 Backend API: http://localhost:3001/api
```

## API Configuration

The frontend automatically uses the correct network IP:
```javascript
const API_BASE_URL = __DEV__ 
  ? 'http://172.21.12.176:3001/api'  // Automatically updated
  : 'https://your-production-url.com/api';
```

This ensures your mobile app always connects to the backend server correctly. 
 
 