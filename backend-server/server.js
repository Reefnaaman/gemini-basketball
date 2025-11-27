const express = require('express');
const multer = require('multer');
const fs = require('fs-extra');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const geminiService = require('./services/geminiService');
const computerVisionService = require('./services/computerVisionService');
const logger = require('./utils/logger');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8081', 'http://localhost:8082', 'http://localhost:19006'],
  credentials: true
}));

// Logging middleware
app.use(morgan('combined', {
  stream: {
    write: (message) => {
      logger.info(message.trim());
    }
  }
}));

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  logger.info('Created uploads directory');
}

// File upload configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'video-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  logger.info(`Received file: ${file.originalname}, mimetype: ${file.mimetype}`);
  
  // Check if file is a video or image
  if (file.mimetype.startsWith('video/') || file.mimetype.startsWith('image/')) {
    logger.info(`✅ File accepted: ${file.originalname} (${file.mimetype})`);
    cb(null, true);
  } else {
    logger.error(`❌ File rejected: ${file.originalname} (${file.mimetype})`);
    cb(new Error('Invalid file type. Only video and image files are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// AI Status endpoint
app.get('/api/ai/status', async (req, res) => {
  try {
    const connected = await geminiService.checkConnection();
    res.json({ connected });
  } catch (error) {
    logger.error('AI status check failed:', error);
    res.json({ connected: false });
  }
});

// Computer Vision Demo endpoint
app.post('/api/analysis/demo', async (req, res) => {
  try {
    const results = await computerVisionService.analyzeDemoVideo();
    res.json(results);
  } catch (error) {
    logger.error('Demo analysis failed:', error);
    res.status(500).json({ error: 'Failed to analyze demo video' });
  }
});

// Video Analysis endpoint - Simplified without sessions
app.post('/api/analysis/video', upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No video file uploaded' });
    }
    
    logger.info(`🎯 REAL VIDEO ANALYSIS - Processing video: ${req.file.filename}`);
    logger.info(`📁 File path: ${req.file.path}`);
    logger.info(`📊 File size: ${req.file.size} bytes`);
    logger.info(`🎥 Video MIME type: ${req.file.mimetype}`);
    
    // Use REAL AI video analysis with Gemini Vision
    logger.info(`🎯 Starting REAL video analysis with Gemini AI: ${req.file.path}`);
    const aiResults = await geminiService.analyzeVideoWithAI(req.file.path);
    
    // Validate analysis results
    if (!aiResults || typeof aiResults !== 'object') {
      throw new Error('Invalid analysis results received from AI service');
    }
    
    // Ensure required fields exist
    const validatedResults = {
      totalShots: aiResults.totalShots || 0,
      madeShots: aiResults.madeShots || 0,
      accuracy: aiResults.accuracy || 0,
      insights: aiResults.insights || {
        strengths: ['Analysis completed'],
        improvements: ['Continue practicing']
      },
      shots: aiResults.shots || [],
      timestamp: new Date().toISOString()
    };
    
    logger.info(`📊 Analysis results: ${validatedResults.totalShots} shots, ${validatedResults.madeShots} made, ${validatedResults.accuracy}% accuracy`);
    
    // Clean up uploaded file after analysis
    try {
      fs.removeSync(req.file.path);
      logger.info(`🗑️ Cleaned up uploaded file: ${req.file.filename}`);
    } catch (cleanupError) {
      logger.warn(`Failed to cleanup file: ${cleanupError.message}`);
    }
    
    res.json({
      success: true,
      analysis: validatedResults,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    logger.error('Real video analysis failed:', error);
    
    // Clean up uploaded file on error
    if (req.file && fs.existsSync(req.file.path)) {
      try {
        fs.removeSync(req.file.path);
        logger.info(`🗑️ Cleaned up file after error: ${req.file.filename}`);
      } catch (cleanupError) {
        logger.warn(`Failed to cleanup file after error: ${cleanupError.message}`);
      }
    }
    
    res.status(500).json({ 
      error: 'Failed to analyze video',
      details: error.message 
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'File too large. Maximum size is 50MB.' });
  }
  
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({ error: 'Unexpected file field.' });
  }
  
  if (err.message.includes('Invalid file type')) {
    return res.status(400).json({ error: err.message });
  }
  
  res.status(500).json({ 
    error: 'Internal server error',
    details: err.message 
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`🏀 Basketball Coach Backend running on port ${PORT}`);
  logger.info(`🔗 API URL: http://localhost:${PORT}/api`);
  logger.info(`📊 Health check: http://localhost:${PORT}/api/health`);
}); 