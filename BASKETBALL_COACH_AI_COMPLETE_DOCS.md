# 🏀 Basketball Coach AI - Complete Technical Documentation

## 📋 **Project Overview**

The Basketball Coach AI Mobile App is a sophisticated React Native application that provides real-time basketball shot analysis using Google Gemini AI. It transforms basketball training by offering AI-powered coaching feedback, shot-by-shot analysis with timestamps, and performance tracking.

### **Key Features:**
- **Real-time Video Analysis**: Upload basketball videos for AI analysis
- **Shot-by-Shot Breakdown**: Detailed timestamp analysis of every shot
- **Michael Jordan-Style Feedback**: Direct, motivational coaching for each shot
- **Performance Tracking**: Cumulative statistics for made shots, layups, and three-pointers
- **Session History**: Track progress over time
- **Modern Mobile UI**: Dark basketball-themed interface

## 🎯 **Core AI Prompt (The Heart of the System)**

This is the stable, working prompt that powers the entire analysis system:

```
This is me playing basketball slowed down. 
Tell me how many shots I made tell me how many lay ups I made tell me how many three-pointers I made tell me how many shots I missed and tell me from where I made shots as well and tell me the steps on which made the shot and missed the shot 
On every shot. Give me feedback like you're Michael Jordan. 
go at 1 fps
Output Example:

{
    "shots": [
      {
        "timestamp_of_outcome": "0:07.5",
        "result": "missed",
        "shot_type": "Jump shot (around free-throw line)",
        "total_shots_made_so_far": 0,
        "total_shots_missed_so_far": 1,
        "total_layups_made_so_far": 0,
        "feedback": "You're pushing that ball, not shooting it; get your elbow under, extend fully, and follow through."
      },
      {
        "timestamp_of_outcome": "0:13.0",
        "result": "made",
        "shot_type": "Three-pointer",
        "total_shots_made_so_far": 1,
        "total_shots_missed_so_far": 1,
        "total_layups_made_so_far": 0,
        "feedback": "It went in, but watch that slight fade keep your shoulders square to the hoop through the whole motion."
      },
      {
        "timestamp_of_outcome": "0:21.5",
        "result": "made",
        "shot_type": "Layup",
        "total_shots_made_so_far": 2,
        "total_shots_missed_so_far": 1,
        "total_layups_made_so_far": 1,
        "feedback": "Drive that knee on the layup, protect the ball higher with your off-hand, and finish decisively."
      },
      {
        "timestamp_of_outcome": "0:28.5",
        "result": "made",
        "shot_type": "Jump shot (free-throw line)",
        "total_shots_made_so_far": 3,
        "total_shots_missed_so_far": 1,
        "total_layups_made_so_far": 1,
        "feedback": "Better balance, but that shot pocket and release point must be identical every single time for real consistency."
      }
    ]
  }
```

### **Prompt Output Format:**
- **timestamp_of_outcome**: Exact time when shot outcome is determined
- **result**: "made" or "missed"
- **shot_type**: Type and location (e.g., "Three-pointer", "Layup", "Jump shot (free-throw line)")
- **total_shots_made_so_far**: Cumulative made shots
- **total_shots_missed_so_far**: Cumulative missed shots
- **total_layups_made_so_far**: Cumulative made layups
- **feedback**: Michael Jordan-style coaching feedback of the shot

## 🏗️ **Technical Architecture**

### **Backend Stack:**
- **Framework**: Node.js with Express.js
- **AI Integration**: Google Gemini 2.5 Flash API
- **File Upload**: Multer for video/image handling
- **Logging**: Winston for comprehensive logging
- **Session Storage**: In-memory storage (can be upgraded to database)

### **Frontend Stack:**
- **Framework**: React Native with Expo SDK 53
- **Navigation**: React Navigation v6
- **UI Components**: React Native Paper
- **Camera**: Expo Camera API
- **Media Picker**: Expo Image Picker
- **State Management**: React Hooks

### **Infrastructure:**
- **Backend Port**: 3001
- **Frontend Port**: 8082 (Expo)
- **QR Server Port**: 3006
- **Network**: Configured for 10.0.0.1 (local network access)

## 📁 **Complete File Structure**

```
gemini-basketball/
├── backend-server/
│   ├── package.json
│   ├── server.js                    # Main Express server
│   ├── services/
│   │   ├── geminiService.js         # Gemini AI integration
│   │   ├── computerVisionService.js # Mock CV service
│   │   └── sessionService.js        # Session management
│   ├── utils/
│   │   └── logger.js                # Winston logger config
│   ├── uploads/                     # Temporary video storage
│   └── logs/                        # Application logs
│
├── expo-frontend/
│   ├── package.json
│   ├── App.js                       # Main app entry
│   ├── src/
│   │   ├── theme.js                 # Basketball theme colors
│   │   ├── screens/
│   │   │   ├── HomeScreen.js        # Dashboard with stats
│   │   │   ├── CameraScreen.js      # Video recording
│   │   │   ├── AnalysisScreen.js    # AI analysis results
│   │   │   ├── SessionHistoryScreen.js
│   │   │   └── SessionCompleteScreen.js
│   │   ├── components/
│   │   │   ├── StatsCard.js
│   │   │   └── RecentSessionCard.js
│   │   └── services/
│   │       └── api.js               # API client
│
├── qr-server.js                     # QR code display server
├── setup.sh                         # Automated setup script
└── BASKETBALL_COACH_AI_COMPLETE_DOCS.md
```

## 🔌 **API Endpoints**

### **Health & Status**
- `GET /api/health` - Server health check
- `GET /api/ai/status` - Gemini AI connection status

### **Video Analysis**
- `POST /api/analysis/video` - Upload and analyze video
  - Body: multipart/form-data with 'video' field
  - Returns: Complete shot-by-shot analysis

### **Session Management**
- `GET /api/sessions` - Get all sessions
- `GET /api/sessions/recent` - Get recent sessions
- `GET /api/sessions/stats` - Get session statistics
- `GET /api/sessions/:id` - Get specific session
- `POST /api/sessions` - Create new session
- `PUT /api/sessions/:id` - Update session
- `DELETE /api/sessions/:id` - Delete session

## 🎨 **UI/UX Design**

### **Color Theme:**
```javascript
colors: {
  primary: '#FF6B35',      // Basketball orange
  accent: '#FFD23F',       // Golden yellow
  background: '#1A1A1A',   // Dark background
  surface: '#2D2D2D',      // Card surface
  text: '#FFFFFF',         // White text
  placeholder: '#999999',   // Gray placeholder
  error: '#FF4444',        // Error red
  success: '#4CAF50',      // Success green
}
```

### **Key Screens:**

1. **Home Screen**
   - Hero section: "READY TO DOMINATE?"
   - Today's insights with accuracy percentage
   - Recent sessions list
   - Quick stats cards

2. **Camera Screen**
   - Live camera preview
   - Video picker option
   - Upload progress indicator

3. **Analysis Screen**
   - Shot-by-shot breakdown
   - Michael Jordan feedback for each shot
   - Overall statistics
   - Visual shot indicators

4. **Session Complete Screen**
   - "BEAST MODE!" celebration
   - Session summary
   - Performance metrics

## 🚀 **Setup Instructions**

### **Prerequisites:**
- Node.js 16+
- Expo CLI
- Expo Go app on mobile device
- Google Cloud API key with Gemini API enabled

### **Quick Start:**
```bash
# Clone the repository
git clone [repository-url]
cd gemini-basketball

# Run automated setup
chmod +x setup.sh
./setup.sh

# Or manual setup:
# Backend
cd backend-server
npm install
npm start

# Frontend (new terminal)
cd expo-frontend
npm install
npx expo start

# QR Server (new terminal)
node qr-server.js
```

### **Environment Variables:**
```javascript
// Backend
GEMINI_API_KEY=AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY
PORT=3001

// Frontend
API_BASE_URL=http://10.0.0.1:3001
```

## 🔄 **Data Flow**

1. **User uploads video** → Frontend video picker
2. **Video sent to backend** → Multer handles upload
3. **Backend processes video** → Gemini AI analyzes shots
4. **AI returns analysis** → Shot-by-shot JSON format
5. **Backend parses response** → Extracts statistics
6. **Frontend displays results** → Shows feedback and metrics
7. **Session saved** → Stored for history tracking

## 🎯 **Gemini AI Integration Details**

### **Model Configuration:**
- **Model**: gemini-2.5-flash
- **Temperature**: 0.1 (consistent responses)
- **Max Tokens**: 2048
- **File Upload**: Google AI File Manager API

### **Video Processing:**
1. Video uploaded to Google AI File Manager
2. File URI passed to Gemini model
3. Model analyzes at 1 FPS as requested
4. Returns structured JSON response

### **Error Handling:**
- Fallback to default analysis on errors
- Comprehensive logging at each step
- User-friendly error messages

## 📊 **Sample Analysis Output**

```json
{
  "totalShots": 4,
  "madeShots": 3,
  "accuracy": 75,
  "insights": {
    "strengths": ["Made 1 layup", "Made 1 three-pointer"],
    "improvements": ["Missed 1 shot", "Focus on consistency in shot form"]
  },
  "shots": [
    {
      "id": 1,
      "timestamp": "0:07.5",
      "type": "Jump shot (around free-throw line)",
      "outcome": "Missed",
      "mjFeedback": "You're pushing that ball, not shooting it; get your elbow under, extend fully, and follow through."
    },
    {
      "id": 2,
      "timestamp": "0:13.0",
      "type": "Three-pointer",
      "outcome": "Made",
      "mjFeedback": "It went in, but watch that slight fade keep your shoulders square to the hoop through the whole motion."
    }
  ]
}
```

## 🛠️ **Troubleshooting**

### **Common Issues:**

1. **"Could not connect to server"**
   - Check backend is running on port 3001
   - Verify network IP matches device network
   - Ensure API_BASE_URL uses correct IP

2. **"Invalid file type"**
   - Supported formats: MP4, MOV, AVI, MKV
   - Check file size (limit: 100MB)

3. **"AI analysis failed"**
   - Verify Gemini API key is valid
   - Check API quotas in Google Cloud Console
   - Ensure video contains basketball content

### **Debug Commands:**
```bash
# Check server health
curl http://localhost:3001/api/health

# Check AI status
curl http://localhost:3001/api/ai/status

# View logs
tail -f backend-server/logs/combined.log
```

## 🔮 **Future Enhancements**

1. **Database Integration**: PostgreSQL for persistent storage
2. **User Authentication**: JWT-based auth system
3. **Video Streaming**: Real-time analysis during recording
4. **Advanced Analytics**: Shot charts, heat maps
5. **Social Features**: Share sessions, leaderboards
6. **Offline Mode**: Cache analysis for offline viewing

## 📝 **Important Notes**

- The core prompt is optimized and should only be modified minimally
- The 1 FPS analysis provides detailed frame-by-frame breakdown
- Michael Jordan-style feedback is direct and motivational
- The system tracks cumulative statistics throughout the video
- All timestamps are in MM:SS.S format

## 🤝 **Contributing**

When modifying the system:
1. Keep the core prompt structure intact
2. Test with various basketball videos
3. Ensure JSON parsing handles edge cases
4. Maintain the Michael Jordan coaching persona
5. Update documentation for any changes

---

**Version**: 1.0.0  
**Last Updated**: January 2025  
**API Key**: AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY (Development only) 
 
 