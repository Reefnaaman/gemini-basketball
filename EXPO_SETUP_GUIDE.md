# 🏀 Basketball Coach AI - Setup Guide

## Quick Setup

### 1. **Install Dependencies**
```bash
# Run the automated setup
chmod +x setup.sh
./setup.sh
```

### 2. **Start Services**
```bash
# Terminal 1: Backend
cd backend-server && npm start

# Terminal 2: Frontend
cd expo-frontend && npm start

# Terminal 3: QR Server (optional)
node qr-server.js
```

### 3. **Connect Mobile Device**
- Install Expo Go app on your phone
- Scan QR code from terminal or visit http://localhost:3006
- Start using the basketball coach!

## Manual Setup (if needed)

### Backend Setup
```bash
cd backend-server
npm install
echo "GEMINI_API_KEY=AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY" > .env
npm start
```

### Frontend Setup
```bash
cd expo-frontend
npm install
npm start
```

## Troubleshooting

### Common Issues

1. **"Cannot connect to backend"**
   - Check backend is running on port 3001
   - Verify phone and computer are on same Wi-Fi network

2. **"Expo Go not loading"**
   - Restart Expo development server
   - Clear Expo cache: `rm -rf .expo`

3. **"AI status shows offline"**
   - Check Gemini API key in backend/.env
   - Verify internet connection

### Debug Commands
```bash
# Check backend health
curl http://localhost:3001/api/health

# Check AI status
curl http://localhost:3001/api/ai/status

# View backend logs
cd backend-server && npm start
```

## Project Structure

```
gemini-basketball/
├── backend-server/          # Node.js Express API
│   ├── services/           # Business logic
│   ├── server.js           # Main server
│   └── package.json
├── expo-frontend/           # React Native app
│   ├── src/screens/        # App screens
│   ├── src/components/     # UI components
│   ├── App.js             # Main app
│   └── package.json
├── BasketballCoachApp/      # iOS Swift version
└── qr-server.js            # QR code server
```

## Development

### Available Scripts
- `./setup.sh` - Automated setup
- `./start-backend.sh` - Start backend server
- `./start-frontend.sh` - Start Expo frontend
- `./start-app.sh` - Start both services

### Environment Variables
Create `backend-server/.env`:
```
NODE_ENV=development
PORT=3001
GEMINI_API_KEY=your_api_key_here
``` 