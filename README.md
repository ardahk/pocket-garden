# 🌱 Pocket Garden - Emotional Wellness iOS App

A beautifully designed emotional wellness app where users rate their daily emotions, voice journal with AI-powered feedback, and grow a virtual forest representing their emotional journey.

## ✨ Features

- **Daily Emotion Rating** - Beautiful 1-10 slider with emoji feedback ✅
- **Voice Journaling** - On-device transcription with real-time display ✅
- **AI Motivation** - Intelligent, contextual feedback (60+ templates) ✅
- **Forest Garden** - Visual representation of your journey (Coming in Part 3)
- **Historical Entries** - Search and browse past journal entries ✅

## 🎨 Design Philosophy

**DESIGN IS KEY** - Every pixel is crafted with care:
- Fluid, organic animations with spring physics
- Natural Growth color palette (sage green, terracotta, cream)
- Emotion-based color coding throughout
- Micro-interactions and haptic feedback
- Accessibility-first approach

## 📱 Current Status: Part 2 Complete ✅

### Implemented in Part 1 & 2

**Foundation & Design (Part 1):**
- ✅ **Design System**: Colors, typography, spacing, theme
- ✅ **Data Models**: SwiftData models for EmotionEntry, TreeData
- ✅ **UI Components**: Buttons, sliders, cards, loaders, shapes
- ✅ **Main Views**: Home, Journal, Forest, History
- ✅ **Navigation**: Tab-based navigation with SwiftUI
- ✅ **Beautiful Animations**: Spring-based, delightful interactions

**Core Features (Part 2):**
- ✅ **Voice Recording**: Real microphone recording with Speech framework
- ✅ **On-Device Transcription**: Real-time transcription display
- ✅ **AI Feedback**: Sentiment analysis + 60+ contextual templates
- ✅ **Waveform Visualization**: Beautiful animated recording UI
- ✅ **Permission Handling**: Privacy-focused permission requests
- ✅ **Error Recovery**: Comprehensive error handling

### Coming in Part 3

- Beautiful tree visualizations (5 growth stages)
- Interactive forest scrolling with parallax
- Growth animations and particle effects
- Weather system based on emotional trends
- Final polish and accessibility enhancements

## 🚀 Getting Started

1. **Clone the repository**
2. **Open in Xcode**: `open pocket-garden/pocket-garden.xcodeproj`
3. **Review Setup Instructions**: See `SETUP_INSTRUCTIONS.md`
4. **Build and Run**: Press ⌘R in Xcode

## 📐 Project Structure

```
pocket-garden/
├── Core/
│   ├── Design/          # Theme, colors, typography, spacing
│   ├── Models/          # SwiftData models
│   └── Extensions/      # View extensions and helpers
├── Services/            # Voice recording & AI services ✨
│   ├── SpeechRecognitionService.swift
│   └── AppleIntelligenceService.swift
├── Features/
│   ├── Home/            # Daily check-in and dashboard
│   ├── Journal/         # Voice journaling interface (FULL IMPLEMENTATION)
│   ├── Forest/          # Forest garden visualization
│   └── History/         # Entry list and detail views
└── Components/          # Reusable UI components + waveforms
```

## 🎯 Tech Stack

- **iOS 17.0+** | **SwiftUI** | **SwiftData**
- **Speech Framework** ✅ | **Natural Language** ✅ | **AVFoundation** ✅

## 📚 Documentation

- **BUILD_PLAN.md** - Comprehensive 3-part development plan
- **SETUP_INSTRUCTIONS.md** - Setup guide and permissions
- **PART2_SUMMARY.md** - Detailed Part 2 implementation details

---

**Built with ❤️ for emotional wellness** 🌱✨