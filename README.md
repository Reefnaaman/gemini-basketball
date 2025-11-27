# Basketball Coach AI - Simplified

A streamlined basketball shot analysis app powered by Google Gemini AI. Upload or record basketball videos to get instant AI-powered analysis and coaching feedback.

## Features

- **Video Analysis**: Upload or record basketball videos for instant analysis
- **AI Coaching**: Get detailed feedback on your shots from our AI coach
- **Shot Breakdown**: See individual shot analysis with accuracy metrics
- **Performance Insights**: Receive personalized tips to improve your game

## Architecture

### Backend (`backend-server/`)
- **Express.js** server with video upload and analysis endpoints
- **Google Gemini AI** integration for basketball shot analysis
- **Multer** for video file handling
- **Real-time AI analysis** with detailed feedback

### Frontend (`expo-frontend/`)
- **React Native** with Expo for cross-platform mobile app
- **Simple navigation** with Home → Camera → Results flow
- **Real-time camera** recording and gallery video selection
- **Beautiful UI** with analysis results display

## Quick Start

1. **Start Backend**:
   ```bash
   cd backend-server
   npm install
   npm start
   ```

2. **Start Frontend**:
   ```bash
   cd expo-frontend
   npm install
   npx expo start
   ```

3. **Use the App**:
   - Open the app and tap "Start Analysis"
   - Record a video or select from gallery
   - Get instant AI analysis and feedback

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/ai/status` - AI connection status
- `POST /api/analysis/video` - Upload video for analysis
- `POST /api/analysis/demo` - Demo analysis

## App Flow

1. **Home Screen**: Welcome screen with AI status
2. **Camera Screen**: Record or select video
3. **Results Screen**: View analysis and feedback

## Technologies

- **Backend**: Node.js, Express.js, Google Gemini AI
- **Frontend**: React Native, Expo
- **AI**: Google Gemini Vision API
- **Storage**: File system (videos processed and deleted)

## Configuration

Set your Google Gemini API key in the backend service or environment variables.

## Development

The app is now simplified without session management, making it easier to develop and maintain. Each video analysis is independent and results are shown immediately.
