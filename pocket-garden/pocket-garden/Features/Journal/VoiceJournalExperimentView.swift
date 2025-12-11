//
//  VoiceJournalExperimentView.swift
//  pocket-garden
//
//  Experimental Voice Journal View with SwiftWhisper Toggle
//

import SwiftUI
import SwiftData
import Inject

// MARK: - Animated Loading Dots

struct LoadingDotsView: View {
    @State private var dotScales: [CGFloat] = [0.5, 0.5, 0.5]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 10, height: 10)
                    .scaleEffect(dotScales[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                dotScales[index] = 1.0
            }
        }
    }
}

struct VoiceJournalExperimentView: View {
    @ObserveInjection var inject
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let emotionRating: Int
    var onComplete: (() -> Void)? = nil
    
    // Service selection - Default to Whisper only
    @State private var useWhisper = true
    
    // Services
    // @State private var speechService = SpeechRecognitionService()
    @State private var whisperService = WhisperService()
    @State private var classificationService: Any? = nil // Will be EntryClassificationService if available
    
    // Recording state
    @State private var recordingSeconds: Int = 0
    @State private var recordingTimer: Timer?
    @State private var showingPermissionDenied = false
    @State private var showingError = false
    @State private var isGeneratingFeedback = false
    @State private var showMascotFeedback = false
    @State private var savedEntry: EmotionEntry?
    @State private var previousTranscription: String = "" // For appending mode
    @State private var saveAudioAsFavorite: Bool = false
    
    // Animation states
    @State private var breatheScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    @State private var pulseOpacity: Double = 0.3
    
    // Keyboard and confirmation states
    @FocusState private var isTextEditorFocused: Bool
    @State private var showDiscardConfirmation = false
    @State private var pendingDiscardAction: DiscardAction? = nil
    
    enum DiscardAction {
        case redo
        case dismiss
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    // Remove service toggle - Whisper only
                    // serviceToggleView
                    
                    if needsAuthorization() {
                        permissionRequestView
                    } else {
                        mainContentView
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                if !needsAuthorization() {
                    Button(action: {
                        // If there's unsaved transcription, show confirmation
                        if !transcription().isEmpty && !isRecording() {
                            pendingDiscardAction = .dismiss
                            showDiscardConfirmation = true
                            Theme.Haptics.warning()
                        } else {
                            cancelRecording()
                            dismiss()
                        }
                    }) {
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, Layout.screenPadding)
                    .padding(.top, 16)
                }
            }
            .overlay(alignment: .top) {
                if isRecording() && !needsAuthorization() {
                    // Elegant timer display
                    VStack(spacing: Spacing.xs) {
                        HStack(spacing: Spacing.sm) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .opacity(pulseOpacity)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        pulseOpacity = 1.0
                                    }
                                }
                            
                            Text("Recording")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text(formatTime(recordingSeconds))
                            .font(.system(size: 34, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.top, 60)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isRecording() && !needsAuthorization() {
                // Elegant stop button
                Button(action: {
                    stopRecording()
                    Theme.Haptics.medium()
                }) {
                    HStack(spacing: Spacing.md) {
                        // Stop icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                        }
                        
                        Text("Stop Recording")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Bumblebee listening indicator
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                            
                            Text("🐝")
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.leading, Spacing.md)
                    .padding(.trailing, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.9), Color.red.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 15, y: 5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showMascotFeedback) {
            if let entry = savedEntry {
                MascotFeedbackView(entry: entry) {
                    showMascotFeedback = false
                    dismiss()
                    // Call completion callback to switch to garden tab
                    onComplete?()
                }
            }
        }
        .overlay {
            // Custom discard confirmation overlay
            if showDiscardConfirmation {
                discardConfirmationOverlay
            }
        }
        .interactiveDismissDisabled(!transcription().isEmpty && !isRecording())
        .enableInjection()
    }
    
    // MARK: - Service Toggle (Commented out - Whisper only)
    /*
    private var serviceToggleView: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Transcription Method")
                    .font(Typography.subheadline)
                    .foregroundColor(.primaryGreen)
                
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(useWhisper ? "Whisper (OpenAI)" : "Apple SFSpeech")
                            .font(Typography.body)
                            .fontWeight(.medium)
                        
                        Text(useWhisper 
                            ? "Transcribes after recording • More reliable • Offline"
                            : "Real-time transcription • Timer-based restarts")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $useWhisper)
                        .labelsHidden()
                        .disabled(isRecording())
                }
            }
        }
        .opacity(isRecording() ? 0.6 : 1.0)
    }
    */
    
    // MARK: - Permission Request
    
    private var permissionRequestView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen)
            
            VStack(spacing: Spacing.md) {
                Text("Voice Journaling")
                    .font(Typography.title)
                    .fontWeight(.bold)
                
                Text("Express your thoughts naturally with voice transcription")
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureRow(
                    icon: "lock.shield.fill",
                    text: "Private & Secure",
                    description: "100% on-device processing"
                )
                
                FeatureRow(
                    icon: "waveform",
                    text: "Process After Recording",
                    description: "Speak freely, transcribe when done"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    text: "AI-Powered Insights",
                    description: "Get gentle feedback from your garden mascot"
                )
            }
            .padding(.horizontal)
            
            PrimaryButton("Enable Voice Journaling", icon: "mic.fill") {
                Task {
                    let granted = await requestPermissions()
                    if !granted {
                        showingPermissionDenied = true
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    // Top spacing for X button
                    Spacer()
                        .frame(height: 40)
                    
                    // Show transcribing view full screen (no other content)
                    if isTranscribing() {
                        statusView
                            .frame(height: screenHeight - 120)
                    } else {
                        // Transcription card (only after transcription complete)
                        if !transcription().isEmpty && !isRecording() {
                            transcriptionView
                            
                            // Action buttons
                            postRecordingActionsView
                                .padding(.top, Spacing.sm)
                        } else {
                            // Recording controls (idle or recording state)
                            Spacer()
                                .frame(height: max(screenHeight * 0.12, 60))
                            
                            recordingControlsView
                            
                            Spacer()
                                .frame(height: max(screenHeight * 0.15, 80))
                        }
                    }
                    
                    // Bottom spacing
                    if isRecording() {
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextEditorFocused = false
            }
        }
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: Spacing.xl) {
            if isTranscribing() {
                transcribingView
            } else if !isRecording() {
                EmptyView()
            }
        }
    }
    
    // MARK: - Transcribing State
    
    private var transcribingView: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            // Animated mascot with glow
            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentGold.opacity(0.2),
                                Color.accentGold.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(breatheScale)
                
                // Rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.accentGold.opacity(0.4),
                                Color.accentGold.opacity(0.1),
                                Color.accentGold.opacity(0.4)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(ringRotation))
                
                // Mascot
                GardenMascot(emotion: .thinking, size: 120)
            }
            .onAppear {
                startIdleAnimations()
            }
            
            // Status text
            VStack(spacing: Spacing.md) {
                Text("Transcribing your thoughts")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Bumblebee is listening carefully...")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
            }
            
            // Progress indicator
            if whisperService.transcriptionProgress > 0 {
                VStack(spacing: Spacing.sm) {
                    // Custom progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primaryGreen.opacity(0.15))
                                .frame(height: 12)
                            
                            // Fill with gradient
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * whisperService.transcriptionProgress, height: 12)
                                .animation(.easeOut(duration: 0.3), value: whisperService.transcriptionProgress)
                            
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 12)
                                .offset(x: (geometry.size.width * whisperService.transcriptionProgress) - 30)
                                .mask(
                                    RoundedRectangle(cornerRadius: 6)
                                        .frame(width: geometry.size.width * whisperService.transcriptionProgress, height: 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                        }
                    }
                    .frame(width: 260, height: 12)
                    
                    // Percentage
                    Text("\(Int(whisperService.transcriptionProgress * 100))%")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
            } else {
                // Animated loading dots
                LoadingDotsView()
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with more breathing room
            HStack {
                Image(systemName: "text.quote")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryGreen)
                
                Text("Your Journal Entry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                // Word count
                Text("\(transcription().split(separator: " ").count) words")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
            .padding(.bottom, Spacing.sm)
            
            // Text editor with focus state
            TextEditor(text: Binding(
                get: { transcription() },
                set: { whisperService.transcription = $0 }
            ))
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.textPrimary)
            .frame(minHeight: isTextEditorFocused ? 140 : 200, maxHeight: isTextEditorFocused ? 200 : 350, alignment: .topLeading)
            .scrollContentBackground(.hidden)
            .focused($isTextEditorFocused)
        }
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        )
        .animation(.easeInOut(duration: 0.25), value: isTextEditorFocused)
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsView: some View {
        VStack(spacing: Spacing.xl) {
            if isRecording() {
                recordingActiveView
            } else if !isTranscribing() && transcription().isEmpty {
                recordingIdleView
            }
        }
    }
    
    // MARK: - Idle State (Before Recording)
    
    private var recordingIdleView: some View {
        VStack(spacing: Spacing.xxl) {
            // Instructional text
            VStack(spacing: Spacing.sm) {
                Text("Tap to start recording")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Text("Share what's on your mind")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
            .opacity(breatheScale > 1.02 ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 2), value: breatheScale)
            
            // Animated mic button
            ZStack {
                // Outer breathing ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.15),
                                Color.primaryGreen.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(breatheScale)
                
                // Middle ring with rotation
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.3),
                                Color.primaryGreen.opacity(0.1),
                                Color.primaryGreen.opacity(0.3)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(ringRotation))
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.2),
                                Color.primaryGreen.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(breatheScale * 0.95)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen,
                                Color.primaryGreen.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: 20, y: 8)
                
                // Mic icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                startRecording()
                Theme.Haptics.medium()
            }
            .onAppear {
                startIdleAnimations()
            }
            .onDisappear {
                stopIdleAnimations()
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Recording Active State
    
    private var recordingActiveView: some View {
        let level = whisperService.audioLevel
        
        return ZStack {
            // Outer wave rings (audio reactive)
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.primaryGreen.opacity(0.15 - Double(index) * 0.04),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(180 + index * 50), height: CGFloat(180 + index * 50))
                    .scaleEffect(1.0 + level * CGFloat(0.15 - Double(index) * 0.03))
                    .animation(.easeOut(duration: 0.15), value: level)
            }
            
            // Pulsing glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primaryGreen.opacity(0.25 + level * 0.2),
                            Color.primaryGreen.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(1.0 + level * 0.2)
                .animation(.easeOut(duration: 0.12), value: level)
            
            // Main recording circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.primaryGreen,
                            Color.primaryGreen.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(1.0 + level * 0.08)
                .shadow(color: Color.primaryGreen.opacity(0.5), radius: 25 + level * 15, y: 8)
                .animation(.easeOut(duration: 0.1), value: level)
            
            // Waveform visualization inside button
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 4, height: waveformHeight(for: index, level: level))
                        .animation(.easeOut(duration: 0.08), value: level)
                }
            }
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - Animation Helpers
    
    private func waveformHeight(for index: Int, level: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 50
        let variation: [CGFloat] = [0.6, 1.0, 0.8, 1.0, 0.6]
        return baseHeight + (maxHeight - baseHeight) * level * variation[index]
    }
    
    private func startIdleAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breatheScale = 1.08
        }
        
        // Ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
    
    private func stopIdleAnimations() {
        breatheScale = 1.0
        ringRotation = 0
    }
    
    // MARK: - Discard Confirmation Overlay
    
    private var discardConfirmationOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDiscardConfirmation = false
                        pendingDiscardAction = nil
                    }
                }
            
            // Confirmation card
            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.errorRed.opacity(0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.errorRed)
                }
                
                // Text
                VStack(spacing: Spacing.sm) {
                    Text(pendingDiscardAction == .redo ? "Start Over?" : "Discard Entry?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Your recording will be lost and cannot be recovered.")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Buttons
                VStack(spacing: Spacing.md) {
                    // Destructive action
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDiscardConfirmation = false
                        }
                        
                        // Perform the action
                        if pendingDiscardAction == .redo {
                            cancelRecording()
                            recordingSeconds = 0
                            saveAudioAsFavorite = false
                            Theme.Haptics.medium()
                        } else {
                            cancelRecording()
                            dismiss()
                        }
                        pendingDiscardAction = nil
                    }) {
                        Text(pendingDiscardAction == .redo ? "Yes, Start Over" : "Yes, Discard")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.errorRed)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Cancel action
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDiscardConfirmation = false
                            pendingDiscardAction = nil
                        }
                    }) {
                        Text("Keep Editing")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.primaryGreen.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, y: 10)
            )
            .padding(.horizontal, Spacing.xl)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDiscardConfirmation)
    }
    
    // MARK: - Post Recording Actions
    
    private var postRecordingActionsView: some View {
        VStack(spacing: Spacing.lg) {
            // Favorite toggle - elegant card style
            Button(action: {
                if recordingSeconds <= 300 {
                    saveAudioAsFavorite.toggle()
                    Theme.Haptics.selection()
                }
            }) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(saveAudioAsFavorite ? Color.errorRed.opacity(0.15) : Color.gray.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: saveAudioAsFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(saveAudioAsFavorite ? .errorRed : .textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save as Favorite")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        Text(recordingSeconds <= 300 ? "Keep audio recording attached" : "Audio too long to save")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Toggle indicator
                    ZStack {
                        Capsule()
                            .fill(saveAudioAsFavorite ? Color.primaryGreen : Color.gray.opacity(0.2))
                            .frame(width: 50, height: 30)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 26, height: 26)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                            .offset(x: saveAudioAsFavorite ? 10 : -10)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: saveAudioAsFavorite)
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(recordingSeconds > 300)
            .opacity(recordingSeconds > 300 ? 0.6 : 1.0)
            
            // Action buttons row
            HStack(spacing: Spacing.md) {
                // Continue Adding - secondary style
                Button(action: {
                    previousTranscription = transcription()
                    startRecording()
                    Theme.Haptics.medium()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Add More")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.primaryGreen.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                
                // Record Again - tertiary style (with confirmation)
                Button(action: {
                    pendingDiscardAction = .redo
                    showDiscardConfirmation = true
                    Theme.Haptics.warning()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Redo")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Save button - primary action
            Button(action: {
                saveEntry()
                Theme.Haptics.success()
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Save Journal Entry")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.primaryGreen.opacity(0.35), radius: 12, y: 6)
                )
            }
            .buttonStyle(.plain)
            .disabled(isGeneratingFeedback)
        }
    }
    
    // MARK: - Save Button (Legacy - kept for compatibility)
    
    private var saveButtonView: some View {
        PrimaryButton("Save Journal Entry", icon: "checkmark.circle.fill") {
            saveEntry()
        }
        .disabled(isGeneratingFeedback)
    }
    
    // MARK: - Helper Methods
    
    private func needsAuthorization() -> Bool {
        // Whisper doesn't need speech recognition authorization, only microphone
        false
    }
    
    private func isRecording() -> Bool {
        whisperService.isRecording
    }
    
    private func isTranscribing() -> Bool {
        whisperService.isTranscribing
    }
    
    private func transcription() -> String {
        whisperService.transcription
    }
    
    private func requestPermissions() async -> Bool {
        return await whisperService.requestPermissions()
    }
    
    private func startRecording() {
        Task {
            do {
                try await whisperService.startRecording()
                
                // Start timer
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    recordingSeconds += 1
                }
                saveAudioAsFavorite = false
            } catch {
                showingError = true
            }
        }
    }
    
    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        Task {
            await whisperService.stopRecording()
            
            // If we were appending, combine with previous transcription
            if !previousTranscription.isEmpty {
                whisperService.transcription = previousTranscription + " " + whisperService.transcription
                previousTranscription = "" // Reset
            }
        }
    }
    
    private func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingSeconds = 0
        saveAudioAsFavorite = false
        
        whisperService.cancelRecording()
    }
    
    private func saveEntry() {
        isGeneratingFeedback = true
        let shouldFavorite = saveAudioAsFavorite
        let shouldSaveAudio = saveAudioAsFavorite && recordingSeconds <= 300

        let entry = EmotionEntry(
            emotionRating: emotionRating,
            date: Date(),
            transcription: transcription().isEmpty ? nil : transcription()
        )
        entry.isFavorite = shouldFavorite
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            savedEntry = entry
            
            // Classify entry in background
            Task {
                await classifyEntry(entry)
            }
            
            if shouldSaveAudio {
                Task {
                    do {
                        let url = try await whisperService.exportCompressedAudio(forEntryID: entry.id)
                        await MainActor.run {
                            entry.voiceRecordingURL = url
                            try? modelContext.save()
                        }
                    } catch {
                        whisperService.discardRecordingFile()
                        print("Failed to export audio: \(error)")
                    }
                }
            } else {
                whisperService.discardRecordingFile()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isGeneratingFeedback = false
                showMascotFeedback = true
                saveAudioAsFavorite = false
                recordingSeconds = 0
            }
        } catch {
            print("Failed to save entry: \(error)")
            showingError = true
            isGeneratingFeedback = false
        }
    }
    
    private func classifyEntry(_ entry: EmotionEntry) async {
        guard let text = entry.cleanedTranscription, !text.isEmpty else { return }
        
        // Try AFM classification first (iOS 26+)
        if #available(iOS 26.0, *) {
            if classificationService == nil {
                classificationService = EntryClassificationService()
            }
            
            if let service = classificationService as? EntryClassificationService {
                do {
                    let result = try await service.classifyEntry(transcription: text)
                    await MainActor.run {
                        entry.moodCategory = result.moodCategory
                        entry.focusArea = result.focusArea
                        try? modelContext.save()
                    }
                    return
                } catch {
                    print("AFM classification failed: \(error)")
                }
            }
        }
        
        // Fallback classification
        let fallback = FallbackClassificationService()
        let result = fallback.classifyEntry(transcription: text, rating: entry.emotionRating)
        await MainActor.run {
            entry.moodCategory = result.moodCategory
            entry.focusArea = result.focusArea
            try? modelContext.save()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primaryGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(text)
                    .font(Typography.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Voice Service Protocol (Commented out - not needed for Whisper only)
/*
protocol VoiceServiceProtocol {
    var isRecording: Bool { get }
    var isTranscribing: Bool { get }
    var transcription: String { get }
}

extension SpeechRecognitionService: VoiceServiceProtocol {}
extension WhisperService: VoiceServiceProtocol {}
*/

// MARK: - Preview

#Preview {
    VoiceJournalExperimentView(emotionRating: 4)
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
