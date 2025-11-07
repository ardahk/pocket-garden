# Setup Instructions for Pocket Garden

## Required Permissions Setup

Since this app will use voice recording and speech recognition in Part 2, you'll need to add the following permissions to your Xcode project.

### Adding Permissions in Xcode

1. Open the project in Xcode
2. Select the **pocket-garden** target in the project navigator
3. Go to the **Info** tab
4. Add the following keys under "Custom iOS Target Properties":

#### Microphone Usage

- **Key**: `Privacy - Microphone Usage Description` (or `NSMicrophoneUsageDescription`)
- **Value**: `We need microphone access to record your voice journals.`

#### Speech Recognition Usage

- **Key**: `Privacy - Speech Recognition Usage Description` (or `NSSpeechRecognitionUsageDescription`)
- **Value**: `We need speech recognition to transcribe your voice journals and provide personalized support.`

### Alternative Method: Direct Info.plist Editing

If you prefer to edit the Info.plist directly, add these entries:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice journals.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to transcribe your voice journals and provide personalized support.</string>
```

## Build Configuration

### Minimum iOS Version

- **iOS 17.0+** is required for SwiftData and modern SwiftUI features
- Verify this in:
  - Project Settings → General → Deployment Info → iOS Deployment Target

### Capabilities (No Additional Capabilities Required)

The app uses only on-device processing, so no special entitlements are needed:
- ✅ On-device speech recognition
- ✅ Local-only data storage with SwiftData
- ✅ No cloud services required

## Part 1 Implementation Status

### ✅ Completed

1. **Design System**
   - Colors, Typography, Spacing, Theme
   - Beautiful Natural Growth color palette
   - Comprehensive view extensions

2. **Data Models**
   - EmotionEntry with SwiftData
   - TreeData and TreeStage enums
   - Forest weather system

3. **Reusable UI Components**
   - CustomButton (Primary, Secondary, Icon, FAB, Tag)
   - EmotionSlider with beautiful animations
   - Card components (Basic, Entry, Info, Stat, Empty State)
   - Loading animations
   - Custom shapes (Blob, Cloud, Mountain, Flower, etc.)

4. **Main Views**
   - HomeView with daily check-in
   - VoiceJournalView (placeholder for Part 2)
   - ForestGardenView (placeholder for Part 3)
   - EntriesListView with search
   - EntryDetailView

5. **Navigation**
   - Tab-based navigation
   - SwiftData integration
   - Smooth transitions

### 🎨 Design Highlights

- **Fluid Animations**: Spring-based, delightful micro-interactions
- **Color-Coded Emotions**: Visual feedback throughout
- **Organic Shapes**: Nature-inspired design elements
- **Haptic Feedback**: Physical interaction feedback
- **Accessibility Ready**: VoiceOver labels, dynamic type support

## Next Steps

### Part 2: Core Features (To Be Implemented)

- Voice recording with Speech framework
- On-device transcription
- AI feedback generation
- Enhanced data persistence
- Entry editing capabilities

### Part 3: Forest Garden & Polish (To Be Implemented)

- Beautiful tree visualizations
- Interactive forest scrolling
- Growth animations
- Weather effects
- Final polish and accessibility enhancements

## Testing the App

1. Open `pocket-garden.xcodeproj` in Xcode
2. Select a simulator (iPhone 15 Pro recommended) or physical device
3. Build and run (⌘R)
4. Explore the beautiful UI and design system!

### Preview Features

The app includes SwiftUI previews for all major components:
- Individual component previews
- View previews with sample data
- Multiple states (empty, populated, loading)

To view previews in Xcode:
1. Open any SwiftUI file
2. Click "Resume" in the Canvas (⌘⌥↵)
3. Interact with live previews

## Project Structure

```
pocket-garden/
├── Core/
│   ├── Design/          # Design system (Colors, Typography, Theme)
│   ├── Models/          # SwiftData models
│   └── Extensions/      # View extensions
├── Features/
│   ├── Home/            # Home screen
│   ├── Journal/         # Voice journaling
│   ├── Forest/          # Forest garden
│   └── History/         # Entry history
└── Components/          # Reusable UI components
```

## Known Limitations (Part 1)

- Voice recording is a placeholder (shows sample transcription)
- AI feedback uses random templates (not contextual yet)
- Forest garden shows emoji trees (detailed visualizations in Part 3)
- No actual audio recording/playback yet

These will all be implemented in Parts 2 and 3!

## Support

For issues or questions about this implementation, refer to:
- `BUILD_PLAN.md` - Comprehensive 3-part build plan
- Apple Documentation links in the original instructions
- SwiftUI previews for component examples

---

**Built with ❤️ and beautiful design** 🌱✨
