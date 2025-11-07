# Emotional Garden - 3-Part Build Plan

## Overview
Building a beautifully designed emotional wellness iOS app with voice journaling, AI feedback, and a virtual forest garden visualization.

**Key Principle: DESIGN IS KEY** - Every component must be fluid, cute, and uniquely designed.

---

## 🎨 Part 1: Foundation & Design System (Week 1-2)

### Goals
- Establish a solid, beautiful design foundation
- Create reusable, polished UI components
- Set up data models and project structure
- Build the core navigation experience

### Deliverables

#### 1.1 Design System Implementation
- **Color Palette**: Natural Growth theme
  - Primary: Soft sage green (#A8C69F)
  - Secondary: Warm terracotta (#E5A888)
  - Background: Cream white (#FAF8F3)
  - Accent: Golden yellow (#F4D06F)
  - Additional emotion-based colors
- **Typography System**:
  - SF Pro Rounded for headings
  - SF Pro for body text
  - Dynamic Type support
- **Theme Manager**: Centralized design tokens
- **Spacing System**: Consistent padding/margins

#### 1.2 Project Structure
```
pocket-garden/
├── pocket-garden/
│   ├── App/
│   │   ├── pocket_gardenApp.swift
│   │   └── AppDelegate.swift (if needed)
│   ├── Core/
│   │   ├── Design/
│   │   │   ├── Theme.swift
│   │   │   ├── Colors.swift
│   │   │   ├── Typography.swift
│   │   │   └── Spacing.swift
│   │   ├── Models/
│   │   │   ├── EmotionEntry.swift
│   │   │   └── TreeData.swift
│   │   └── Extensions/
│   │       ├── View+Extensions.swift
│   │       └── Color+Extensions.swift
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── DailyRatingCard.swift
│   │   ├── Journal/
│   │   │   ├── VoiceJournalView.swift
│   │   │   ├── RecordingButton.swift
│   │   │   └── TranscriptionView.swift
│   │   ├── Forest/
│   │   │   ├── ForestGardenView.swift
│   │   │   ├── TreeView.swift
│   │   │   └── ForestBackground.swift
│   │   └── History/
│   │       ├── EntriesListView.swift
│   │       └── EntryDetailView.swift
│   ├── Components/
│   │   ├── CustomButton.swift
│   │   ├── EmotionSlider.swift
│   │   ├── Card.swift
│   │   ├── LoadingAnimation.swift
│   │   └── CustomShapes.swift
│   ├── Services/
│   │   └── (To be added in Part 2)
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
```

#### 1.3 SwiftData Models
- **EmotionEntry**: Core data model
  - id, date, emotionRating, transcription, aiFeedback, treeStage
- **Model relationships** and queries setup

#### 1.4 Reusable UI Components
- **CustomButton**: With press animations and haptics
- **EmotionSlider**: Beautiful 1-10 rating slider with emoji feedback
- **Card**: Glassmorphic card container with shadows
- **GradientBackground**: Animated gradient backgrounds
- **CustomShapes**: Organic shapes for nature theme

#### 1.5 Navigation Structure
- Tab-based navigation
- Sheet presentations for modal views
- Smooth transitions between screens

#### 1.6 Main Views (Skeleton)
- **HomeView**: Daily check-in interface
- **ForestGardenView**: Forest visualization (placeholder)
- **EntriesListView**: History view (placeholder)
- **VoiceJournalView**: Journal entry (placeholder)

### Success Criteria for Part 1
✅ Design system fully implemented and documented
✅ All UI components are polished and reusable
✅ App has a cohesive, beautiful visual identity
✅ Navigation flows smoothly
✅ Data models are set up correctly
✅ Code is clean, organized, and well-structured

---

## 🎙️ Part 2: Core Features & Functionality (Week 2-3)

### Goals
- Implement emotion rating functionality
- Add voice recording and transcription
- Build AI feedback system
- Complete data persistence
- Create entry viewing experience

### Deliverables

#### 2.1 Daily Emotion Rating
- Interactive EmotionSlider with smooth animations
- Real-time emoji and color feedback
- Save rating to SwiftData
- Daily limit (one entry per day)

#### 2.2 Voice Recording System
- **SpeechRecognitionService**:
  - Request microphone and speech permissions
  - On-device transcription (privacy-first)
  - Real-time transcription display
  - Error handling and user feedback
- **RecordingButton**: Animated recording UI
- **WaveformView**: Visual audio feedback
- **Audio session management**

#### 2.3 AI Feedback System
- **AppleIntelligenceService**:
  - Sentiment analysis using Natural Language framework
  - Context-aware response templates
  - Emotion pattern recognition
  - Personalized, supportive feedback generation
- Template library (30+ variations)
- Feedback display with beautiful animations

#### 2.4 Data Persistence
- SwiftData integration
- CRUD operations for EmotionEntry
- Query optimization
- Data migration strategy

#### 2.5 Entry Viewing
- **EntriesListView**:
  - Chronological list of entries
  - Beautiful card-based layout
  - Pull-to-refresh
  - Swipe actions (delete, edit)
- **EntryDetailView**:
  - Full entry display
  - AI feedback showcase
  - Edit/delete options

#### 2.6 Permissions & Privacy
- Info.plist configuration
- Permission request UI
- Privacy-first messaging
- Local-only data storage

### Success Criteria for Part 2
✅ Users can rate their emotions daily
✅ Voice recording and transcription work flawlessly
✅ AI feedback feels intelligent and supportive
✅ All data persists correctly
✅ Entry viewing is smooth and intuitive
✅ App respects user privacy completely

---

## 🌳 Part 3: Forest Garden & Polish (Week 4-5)

### Goals
- Implement tree growth visualization
- Create scrollable forest garden
- Add delightful animations
- Polish every interaction
- Prepare for launch

### Deliverables

#### 3.1 Tree Visualization System
- **TreeView**: 5 growth stages
  - Seed, Sprout, Young Tree, Mature Tree, Blooming Tree
  - Custom path shapes for organic look
  - Emotion-based coloring
  - Smooth growth animations
- **TreeGrowthAnimation**: Spring-based animations
- Blossom/decoration system based on ratings

#### 3.2 Forest Garden View
- **Horizontal scrolling landscape**
- **Parallax background layers**:
  - Sky with time-of-day gradient
  - Mountains silhouette
  - Forest floor with grass
- **Weather system**:
  - Sunny for positive trends
  - Partly cloudy for mixed
  - Gentle rain for reflective periods
- **Tree placement algorithm**: Organic, non-grid layout
- **Interactive gestures**:
  - Tap tree to view entry
  - Pinch to zoom
  - Shake for particle effects

#### 3.3 Advanced Animations
- **Tree growth sequences**: Seed to full tree
- **Particle effects**: Leaves, butterflies, sparkles
- **Loading animations**: Custom spinners
- **Success celebrations**: Confetti on milestone achievements
- **Micro-interactions**: Button presses, card reveals, transitions

#### 3.4 Polish & Refinement
- **Haptic feedback** throughout the app
- **Sound effects** (optional, subtle nature sounds)
- **Empty states**: Beautiful illustrations and helpful text
- **Error states**: Friendly error messages
- **Loading states**: Skeleton screens and spinners

#### 3.5 Onboarding
- Beautiful welcome screens (3-4 slides)
- Permission requests with context
- Quick tutorial on first use
- Optional skip option

#### 3.6 Accessibility
- VoiceOver support for all elements
- Dynamic Type throughout
- Reduce Motion alternatives
- High contrast mode support
- Alternative text input option

#### 3.7 Testing & Optimization
- Performance testing (60fps target)
- Memory optimization
- Test on multiple device sizes
- Edge case handling
- User testing session

#### 3.8 App Store Preparation
- Screenshots (6.7", 6.5", 5.5" displays)
- App icon design
- App Store description
- Privacy policy
- Terms of service

### Success Criteria for Part 3
✅ Forest garden is stunning and interactive
✅ Animations are smooth and delightful
✅ App feels polished in every detail
✅ Accessibility is comprehensive
✅ Performance is excellent on all devices
✅ Ready for App Store submission

---

## 📊 Progress Tracking

### Part 1 Status: 🚀 IN PROGRESS
- [ ] Design system
- [ ] Project structure
- [ ] Data models
- [ ] UI components
- [ ] Navigation
- [ ] Main views skeleton

### Part 2 Status: ⏳ NOT STARTED
- [ ] Emotion rating
- [ ] Voice recording
- [ ] AI feedback
- [ ] Data persistence
- [ ] Entry viewing

### Part 3 Status: ⏳ NOT STARTED
- [ ] Tree visualization
- [ ] Forest garden
- [ ] Animations
- [ ] Polish
- [ ] Accessibility
- [ ] App Store prep

---

## 🎯 Key Design Principles

1. **Fluid & Organic**: Rounded corners, smooth animations, nature-inspired shapes
2. **Minimal & Clean**: Ample whitespace, focused content
3. **Delightful Interactions**: Micro-animations, haptic feedback, sound
4. **Emotionally Intelligent**: Color and imagery reflect user's emotional state
5. **Privacy-Focused**: On-device processing, clear data practices
6. **Accessible**: Works beautifully for everyone

---

## 🚀 Next Steps

**Current Focus: Part 1 - Foundation & Design System**

1. Implement design system (Theme, Colors, Typography)
2. Create folder structure
3. Build SwiftData models
4. Design and build reusable UI components
5. Create beautiful HomeView
6. Set up navigation

**Let's build something beautiful! 🌱✨**
