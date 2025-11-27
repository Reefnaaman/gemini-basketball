# Basketball Coach App - Resources

This folder contains the original demo files and resources needed for development and testing.

## Original Demo Files

### `ball.json`
The original Gemini-generated shot analysis data containing:
- 4 shots with timestamps and outcomes
- Shot types (Jump shot, Three-pointer, Layup)
- AI-generated coaching feedback
- Running statistics

**Usage in iOS App:**
- Our `ComputerVisionDemo.swift` loads this file for comparison
- Used to validate our CV algorithms against the original analysis
- Provides reference data for testing

### `ball.py`
The original Python demo script showing:
- MediaPipe pose detection implementation
- OpenCV video processing
- Frame-by-frame overlay rendering
- Statistics display and animation

**Key Insights for iOS Implementation:**
- Uses MediaPipe for pose detection (we use Apple Vision)
- Processes at ~3 FPS (we achieve 20+ FPS)
- Shows overlay rendering techniques
- Demonstrates feedback display timing

## Missing Files

You'll need to add these files to test the full demo:

### `final_ball.mov`
- The original basketball video file (16MB)
- Contains the actual basketball shooting session
- Used by `ComputerVisionDemo.swift` for testing
- ✅ **Now included in Resources folder**

### All Original Files Included
All original demo files are now included in this Resources folder:
- ✅ `ball.json` - Gemini analysis data
- ✅ `ball.py` - Original Python implementation  
- ✅ `final_ball.mov` - Basketball video (16MB)

## Usage in Development

### Running the Demo
```swift
// In your iOS app or test
await runComputerVisionDemo()
```

### Loading Original Data
```swift
// Our demo automatically loads and compares with original data
let originalData = loadOriginalShotData() // Loads ball.json
```

### Comparison Testing
The demo compares:
- Shot detection accuracy
- Shot type classification
- Feedback generation quality
- Performance metrics

## File Structure
```
BasketballCoachApp/Resources/
├── ball.json              ✅ Original Gemini analysis
├── ball.py                ✅ Original Python demo  
├── final_ball.mov         ✅ Basketball video (16MB)
└── README.md              ✅ This file
```

## Integration Notes

Our iOS implementation is designed to be compatible with the original data format:

```swift
// Our ShotAnalysis matches ball.json structure
struct ShotAnalysis {
    let timestamp: TimeInterval    // "0:07.5"
    let outcome: ShotOutcome      // "made"/"missed"
    let shotType: ShotType        // "Jump shot"
    let feedback: String          // Coaching feedback
}
```

This ensures we can:
- Compare our results with original analysis
- Validate our algorithms
- Maintain compatibility with future enhancements 