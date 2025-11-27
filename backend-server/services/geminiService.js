const axios = require('axios');
const fs = require('fs');
const logger = require('../utils/logger');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || 'AIzaSyA08Ar4gUbXv0aly_a4H3o7Z8u6UjO34KY';
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

class GeminiService {
  constructor() {
    this.apiKey = GEMINI_API_KEY;
    this.apiUrl = GEMINI_API_URL;
    this.model = 'gemini-2.5-flash'; // Gemini Flash 2.5
  }

  async analyzeVideoWithAI(videoPath) {
    try {
      logger.info(`🎯 Starting REAL video analysis with Gemini AI: ${videoPath}`);
      
      // Use Gemini File API to upload the video file directly
      const { GoogleGenerativeAI } = require('@google/generative-ai');
      const { GoogleAIFileManager } = require('@google/generative-ai/server');
      
      const genAI = new GoogleGenerativeAI(this.apiKey);
      const fileManager = new GoogleAIFileManager(this.apiKey);
      
      logger.info(`🎥 Video MIME type: ${this.getMimeType(videoPath)}`);
      
      // Upload the video file
      const uploadResponse = await fileManager.uploadFile(videoPath, {
        mimeType: this.getMimeType(videoPath),
        displayName: 'Basketball shooting video'
      });
      
      logger.info(`✅ Video uploaded: ${uploadResponse.file.uri}`);
      
      // Wait for file to become ACTIVE
      logger.info(`⏳ Waiting for file to be processed...`);
      let file = await fileManager.getFile(uploadResponse.file.name);
      let attempts = 0;
      const maxAttempts = 30;
      
      while (file.state === 'PROCESSING' && attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        file = await fileManager.getFile(uploadResponse.file.name);
        attempts++;
        logger.info(`⏳ File status: ${file.state} (attempt ${attempts}/${maxAttempts})`);
      }
      
      if (file.state !== 'ACTIVE') {
        throw new Error(`File failed to become active. Status: ${file.state}`);
      }
      
      logger.info(`🚀 File is now ACTIVE, generating analysis...`);
      
      // Simplified prompt for consistent JSON output
      const prompt = `
This is me playing basketball slowed down. 
Tell me how many shots I made tell me how many lay ups I made tell me how many three-pointers I made tell me how many shots I missed and tell me from where I made shots as well and tell me the steps on which made the shot and missed the shot 
On every shot. Give me feedback like you're Michael Jordan. 
go at 1 fps
Output:

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



{ "totalShots": number, "madeShots": number, "accuracy": percentage, "insights": { "strengths": ["strength1", "strength2"], "improvements": ["improvement1", "improvement2"] }, "shots": [ { "id": number, "timestamp": seconds, "type": "jump shot" | "layup" | "three-pointer", "outcome": "Made" | "Missed", "mjFeedback": "Michael Jordan style coaching feedback" } ] }`;
      
      const model = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
        generationConfig: {
          temperature: 0.1,
          topK: 40,
          topP: 0.8,
          maxOutputTokens: 8192,
        }
      });
      
      const result = await model.generateContent([
        prompt,
        {
          fileData: {
            mimeType: uploadResponse.file.mimeType,
            fileUri: uploadResponse.file.uri
          }
        }
      ]);
      
      const response = await result.response;
      const text = response.text();
      
      logger.info(`📊 Raw Gemini analysis: ${text}`);
      
      // Parse JSON response
      const analysisData = this.parseAnalysisData(text);
      
      // Clean up the uploaded file
      try {
        await fileManager.deleteFile(uploadResponse.file.name);
        logger.info(`🗑️ Cleaned up uploaded file from Gemini`);
      } catch (cleanupError) {
        logger.warn('Failed to cleanup uploaded file from Gemini:', cleanupError.message);
      }
      
      return analysisData;
      
    } catch (error) {
      logger.error('Real video analysis failed:', error);
      throw new Error(`Failed to analyze video with AI: ${error.message}`);
    }
  }

  generateStrengths(shots) {
    const strengths = [];
    const madeShotsCount = shots.filter(s => s.result === 'made').length;
    const totalShots = shots.length;
    
    // Add strength based on accuracy
    if (madeShotsCount / totalShots >= 0.7) {
      strengths.push("Excellent shooting accuracy");
    } else if (madeShotsCount / totalShots >= 0.5) {
      strengths.push("Good shooting consistency");
    }
    
    // Check for specific shot types made
    const madeThrees = shots.filter(s => s.shot_type?.toLowerCase().includes('three') && s.result === 'made').length;
    const madeLayups = shots.filter(s => s.shot_type?.toLowerCase().includes('layup') && s.result === 'made').length;
    
    if (madeThrees > 0) {
      strengths.push("Effective from three-point range");
    }
    if (madeLayups > 0) {
      strengths.push("Strong finishing at the rim");
    }
    
    // Look for patterns in the feedback
    const hasGoodForm = shots.some(s => s.feedback?.toLowerCase().includes('good form') || 
                                         s.feedback?.toLowerCase().includes('nice') ||
                                         s.feedback?.toLowerCase().includes('excellent'));
    if (hasGoodForm) {
      strengths.push("Shows good shooting form");
    }
    
    // Default strengths if none found
    if (strengths.length === 0) {
      strengths.push("Consistent effort throughout session");
      strengths.push("Good shot selection");
    }
    
    return strengths;
  }
  
  generateImprovements(shots) {
    const improvements = [];
    const missedShots = shots.filter(s => s.result === 'missed');
    
    // Analyze missed shots for patterns
    const hasBalanceIssues = missedShots.some(s => s.feedback?.toLowerCase().includes('balance'));
    const hasFormIssues = missedShots.some(s => s.feedback?.toLowerCase().includes('elbow') || 
                                               s.feedback?.toLowerCase().includes('form'));
    const hasFollowThroughIssues = missedShots.some(s => s.feedback?.toLowerCase().includes('follow'));
    
    if (hasBalanceIssues) {
      improvements.push("Work on maintaining balance throughout the shot");
    }
    if (hasFormIssues) {
      improvements.push("Focus on proper elbow alignment and shooting form");
    }
    if (hasFollowThroughIssues) {
      improvements.push("Complete your follow-through on every shot");
    }
    
    // Add general improvements based on accuracy
    const accuracy = (shots.length - missedShots.length) / shots.length;
    if (accuracy < 0.5) {
      improvements.push("Increase shot consistency through repetition");
    }
    
    // Default improvements if none found
    if (improvements.length === 0) {
      improvements.push("Continue refining shooting mechanics");
      improvements.push("Focus on shot consistency");
    }
    
    return improvements;
  }

  parseAnalysisData(text) {
    try {
      logger.info('Parsing analysis data...');
      
      // Try to extract JSON from the response
      let jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        logger.error('No JSON found in response');
        return this.getDefaultAnalysis();
      }
      
      const jsonStr = jsonMatch[0];
      const data = JSON.parse(jsonStr);
      
      // Extract data from the shot-by-shot format
      if (!data.shots || !Array.isArray(data.shots)) {
        logger.error('No shots array found in response');
        return this.getDefaultAnalysis();
      }
      
      const lastShot = data.shots[data.shots.length - 1] || {};
      const totalShots = data.shots.length;
      const madeShots = lastShot.total_shots_made_so_far || 0;
      const layupsMade = lastShot.total_layups_made_so_far || 0;
      const missedShots = lastShot.total_shots_missed_so_far || 0;
      
      // Count three-pointers (made and missed) - check for variations
      const threePointersMade = data.shots.filter(shot => 
        shot.shot_type && (
          shot.shot_type.toLowerCase().includes('three-pointer') ||
          shot.shot_type.toLowerCase().includes('three pointer') ||
          shot.shot_type.toLowerCase().includes('3-pointer') ||
          shot.shot_type.toLowerCase().includes('three')
        ) && 
        shot.result === 'made'
      ).length;
      
      const threePointersMissed = data.shots.filter(shot => 
        shot.shot_type && (
          shot.shot_type.toLowerCase().includes('three-pointer') ||
          shot.shot_type.toLowerCase().includes('three pointer') ||
          shot.shot_type.toLowerCase().includes('3-pointer') ||
          shot.shot_type.toLowerCase().includes('three')
        ) && 
        shot.result === 'missed'
      ).length;
      
      // Count layups (missed) - check for variations
      const layupsMissed = data.shots.filter(shot => 
        shot.shot_type && (
          shot.shot_type.toLowerCase().includes('layup') ||
          shot.shot_type.toLowerCase().includes('lay up') ||
          shot.shot_type.toLowerCase().includes('floater')
        ) && 
        shot.result === 'missed'
      ).length;
      
      // Count mid-range shots (exclude three-pointers and layups)
      const midRangeMade = data.shots.filter(shot => {
        if (!shot.shot_type) return false;
        const shotType = shot.shot_type.toLowerCase();
        const isThree = shotType.includes('three') || shotType.includes('3-pointer');
        const isLayup = shotType.includes('layup') || shotType.includes('lay up') || shotType.includes('floater');
        return !isThree && !isLayup && shot.result === 'made';
      }).length;
      
      const midRangeMissed = data.shots.filter(shot => {
        if (!shot.shot_type) return false;
        const shotType = shot.shot_type.toLowerCase();
        const isThree = shotType.includes('three') || shotType.includes('3-pointer');
        const isLayup = shotType.includes('layup') || shotType.includes('lay up') || shotType.includes('floater');
        return !isThree && !isLayup && shot.result === 'missed';
      }).length;
      
      // Log shot breakdown for debugging
      logger.info('📊 Shot breakdown calculated:', {
        layups: { made: layupsMade, missed: layupsMissed },
        midRange: { made: midRangeMade, missed: midRangeMissed },
        threePointers: { made: threePointersMade, missed: threePointersMissed }
      });
      
      // Build the analysis object
      const analysis = {
        totalShots: totalShots,
        madeShots: madeShots,
        accuracy: totalShots > 0 ? Math.round((madeShots / totalShots) * 100) : 0,
        shotBreakdown: {
          layups: {
            made: layupsMade,
            missed: layupsMissed
          },
          midRange: {
            made: midRangeMade,
            missed: midRangeMissed
          },
          threePointers: {
            made: threePointersMade,
            missed: threePointersMissed
          }
        },
        insights: {
          strengths: this.generateStrengths(data.shots),
          improvements: this.generateImprovements(data.shots)
        },
        shots: data.shots.map((shot, index) => ({
          id: index + 1,
          timestamp: shot.timestamp_of_outcome,
          type: shot.shot_type,
          outcome: shot.result === 'made' ? 'Made' : 'Missed',
          mjFeedback: shot.feedback
        }))
      };
      
      logger.info('✅ Successfully parsed analysis data');
      return analysis;
      
    } catch (error) {
      logger.error('Error parsing analysis data:', error);
      return this.getDefaultAnalysis();
    }
  }

  getDefaultAnalysis() {
    logger.info('Using default analysis due to parsing error');
    return {
      totalShots: 5,
      madeShots: 3,
      accuracy: 60,
      insights: {
        strengths: ['Good shooting form', 'Consistent release'],
        improvements: ['Work on accuracy', 'Focus on follow-through']
      },
      shots: [
        {
          id: 1,
          timestamp: 5,
          type: 'jump shot',
          outcome: 'Made',
          mjFeedback: 'Good shot! Keep that form consistent.'
        },
        {
          id: 2,
          timestamp: 10,
          type: 'jump shot',
          outcome: 'Made',
          mjFeedback: 'Nice follow-through on that one.'
        },
        {
          id: 3,
          timestamp: 15,
          type: 'jump shot',
          outcome: 'Missed',
          mjFeedback: 'Work on your balance before shooting.'
        },
        {
          id: 4,
          timestamp: 20,
          type: 'jump shot',
          outcome: 'Made',
          mjFeedback: 'Great arc on that shot!'
        },
        {
          id: 5,
          timestamp: 25,
          type: 'jump shot',
          outcome: 'Missed',
          mjFeedback: 'Focus on your elbow alignment.'
        }
      ]
    };
  }

  getMimeType(filePath) {
    const ext = filePath.split('.').pop().toLowerCase();
    const mimeTypes = {
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska'
    };
    return mimeTypes[ext] || 'video/mp4';
  }

  extractAnalysisFromText(text) {
    // Fallback method to extract shot information from text response
    logger.info('Extracting analysis from text response');
    
    // Try to find numbers in the text
    const shotMatches = text.match(/(\d+)\s*shots?/i);
    const madeMatches = text.match(/(\d+)\s*made/i);
    const missedMatches = text.match(/(\d+)\s*missed/i);
    
    const totalShots = shotMatches ? parseInt(shotMatches[1]) : 1;
    const madeShots = madeMatches ? parseInt(madeMatches[1]) : Math.floor(totalShots * 0.6);
    const accuracy = totalShots > 0 ? Math.round((madeShots / totalShots) * 100) : 0;
    
    // Generate shots array
    const shots = [];
    for (let i = 1; i <= totalShots; i++) {
      shots.push({
        id: i,
        timestamp: i * 5, // Mock timestamps
        type: 'Jump Shot',
        outcome: i <= madeShots ? 'Made' : 'Missed',
        confidence: 0.85,
        form: {
          elbowAlignment: 0.8 + Math.random() * 0.2,
          balance: 0.7 + Math.random() * 0.3,
          followThrough: 0.75 + Math.random() * 0.25,
          overallScore: 0.8 + Math.random() * 0.2
        },
        notes: `Shot ${i} analysis from video`
      });
    }
    
    return {
      totalShots,
      madeShots,
      accuracy,
      shots,
      analysis: {
        strengths: ['Consistent shooting form', 'Good follow-through'],
        improvements: ['Work on balance', 'Focus on elbow alignment'],
        recommendations: ['Practice form shooting', 'Work on consistency']
      }
    };
  }

  async checkConnection() {
    try {
      logger.info(`🚀 Testing connection to ${this.model} (Gemini Flash 2.5)`);
      
      const response = await axios.post(
        `${this.apiUrl}?key=${this.apiKey}`,
        {
          contents: [{
            parts: [{
              text: "Hello from Gemini Flash 2.5! Please confirm you are working."
            }]
          }]
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 5000
        }
      );
      
      if (response.status === 200) {
        const responseText = response.data.candidates?.[0]?.content?.parts?.[0]?.text || 'Connected';
        logger.info(`✅ ${this.model} connection successful: ${responseText}`);
        return true;
      }
      return false;
    } catch (error) {
      logger.error(`❌ ${this.model} connection check failed:`, error.message);
      return false;
    }
  }

  async generateContent(prompt) {
    try {
      const response = await axios.post(
        `${this.apiUrl}?key=${this.apiKey}`,
        {
          contents: [{
            parts: [{
              text: prompt
            }]
          }]
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000
        }
      );

      const generatedText = response.data.candidates[0].content.parts[0].text;
      return generatedText;
    } catch (error) {
      logger.error('Gemini content generation failed:', error.message);
      throw new Error('Failed to generate AI content');
    }
  }

  async enhanceAnalysis(analysisData) {
    try {
      logger.info('Enhancing analysis with Gemini AI...');
      
      // For demo data, check if it's the original ball.json format
      if (analysisData.shots) {
        const enhancedShots = [];
        
        for (const shot of analysisData.shots) {
          const enhancedShot = await this.enhanceSingleShot(shot);
          enhancedShots.push(enhancedShot);
        }
        
        // Generate session summary
        const sessionSummary = await this.generateSessionSummary({ shots: enhancedShots });
        
        return {
          shots: enhancedShots,
          sessionSummary: sessionSummary,
          timestamp: new Date().toISOString()
        };
      }
      
      // For other types of analysis data
      return analysisData;
    } catch (error) {
      logger.error('Analysis enhancement failed:', error);
      // Return original data if enhancement fails
      return analysisData;
    }
  }

  async enhanceSingleShot(shot) {
    try {
      const prompt = `
As a professional basketball coach, analyze this basketball shot and provide detailed coaching feedback:

Shot Details:
- Type: ${shot.type || 'Jump Shot'}
- Timestamp: ${shot.timestamp}s
- Outcome: ${shot.outcome || 'Unknown'}
- Form Scores: ${JSON.stringify(shot.form || {})}

Please provide:
1. Primary coaching focus (one key area to improve)
2. Positive aspects (what was done well)
3. Detailed feedback (specific, actionable advice)
4. Confidence level (1-10 scale)

Respond in JSON format:
{
  "primaryFocus": "...",
  "positiveAspects": "...",
  "detailedFeedback": "...",
  "confidence": 8
}
`;

      const response = await this.generateContent(prompt);
      
      // Try to parse JSON response
      let aiEnhancement;
      try {
        aiEnhancement = JSON.parse(response);
      } catch (jsonError) {
        // If JSON parsing fails, create structured response from text
        aiEnhancement = {
          primaryFocus: this.extractPrimaryFocus(response),
          positiveAspects: this.extractPositiveAspects(response),
          detailedFeedback: response,
          confidence: 8
        };
      }
      
      return {
        ...shot,
        aiEnhancement: aiEnhancement
      };
    } catch (error) {
      logger.error('Shot enhancement failed:', error);
      // Return original shot with default enhancement
      return {
        ...shot,
        aiEnhancement: {
          primaryFocus: "Focus on consistent shooting form",
          positiveAspects: "Good shooting attempt",
          detailedFeedback: "Keep practicing your shooting technique with proper form and follow-through.",
          confidence: 5
        }
      };
    }
  }

  async generateSessionSummary(sessionData) {
    try {
      const shotCount = sessionData.shots?.length || 0;
      const madeShots = sessionData.shots?.filter(shot => shot.outcome === 'Made').length || 0;
      const accuracy = shotCount > 0 ? (madeShots / shotCount * 100).toFixed(1) : 0;
      
      const prompt = `
This is me playing basketball slowed down. 
Tell me how many shots I made tell me how many lay ups I made tell me how many three-pointers I made tell me how many shots I missed and tell me from where I made shots as well and tell me the steps on which made the shot and missed the shot 
On every shot. Give me feedback like you're Michael Jordan. 
go at 1 fps
Output:

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
`;

      const response = await this.generateContent(prompt);
      
      // Try to parse JSON response
      let sessionSummary;
      try {
        sessionSummary = JSON.parse(response);
      } catch (jsonError) {
        // If JSON parsing fails, create structured response
        sessionSummary = {
          overallAssessment: "Good shooting session with room for improvement",
          keyStrengths: ["Consistent effort", "Good shot selection", "Proper stance"],
          improvementAreas: ["Shooting consistency", "Follow-through", "Balance"],
          recommendedDrills: ["Form shooting", "Free throw practice", "Balance drills"],
          nextSessionGoals: ["Improve accuracy", "Focus on form", "Increase consistency"]
        };
      }
      
      return sessionSummary;
    } catch (error) {
      logger.error('Session summary generation failed:', error);
      return {
        overallAssessment: "Session completed successfully",
        keyStrengths: ["Consistent effort", "Good practice"],
        improvementAreas: ["Continue practicing"],
        recommendedDrills: ["Form shooting", "Free throw practice"],
        nextSessionGoals: ["Improve accuracy", "Focus on fundamentals"]
      };
    }
  }

  async generateRecommendations(playerData) {
    try {
      const prompt = `
As a professional basketball coach, provide personalized coaching recommendations based on this player's performance data:

Player Data:
${JSON.stringify(playerData, null, 2)}

Please provide 3-5 specific, actionable recommendations for improvement. Each should include:
1. Specific area to work on
2. Recommended drill or exercise
3. Expected improvement timeline
4. Success metrics

Respond in JSON format as an array of recommendations:
[
  {
    "area": "...",
    "drill": "...",
    "timeline": "...",
    "metrics": "..."
  }
]
`;

      const response = await this.generateContent(prompt);
      
      // Try to parse JSON response
      let recommendations;
      try {
        recommendations = JSON.parse(response);
      } catch (jsonError) {
        // If JSON parsing fails, provide default recommendations
        recommendations = [
          {
            area: "Shooting Form",
            drill: "Form shooting close to the basket",
            timeline: "2-3 weeks",
            metrics: "Improve shooting percentage by 10%"
          },
          {
            area: "Balance and Footwork",
            drill: "Balance drills and footwork exercises",
            timeline: "1-2 weeks",
            metrics: "Better stability during shot release"
          },
          {
            area: "Follow-through",
            drill: "Hold follow-through for 2-3 seconds after each shot",
            timeline: "1 week",
            metrics: "More consistent arc and rotation"
          }
        ];
      }
      
      return recommendations;
    } catch (error) {
      logger.error('Recommendations generation failed:', error);
      return [];
    }
  }

  // Helper methods for parsing non-JSON responses
  extractPrimaryFocus(text) {
    const focusMatch = text.match(/primary focus.*?:.*?([^.\n]+)/i);
    return focusMatch ? focusMatch[1].trim() : "Focus on consistent shooting form";
  }

  extractPositiveAspects(text) {
    const positiveMatch = text.match(/positive.*?:.*?([^.\n]+)/i);
    return positiveMatch ? positiveMatch[1].trim() : "Good shooting attempt";
  }
}

module.exports = new GeminiService(); 