//
//  SettingsView.swift
//  pocket-garden
//
//  Settings & Privacy View
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var showExportSheet = false
    @State private var isExporting = false
    @State private var showExportToast = false
    @State private var showDeleteWarning = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var exportURL: URL?
    @State private var exportTask: Task<Void, Never>? = nil
    @State private var showNotificationSettingsAlert = false
    
    // Import states
    @State private var showImportPicker = false
    @State private var showImportWarning = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var isImporting = false
    @State private var selectedImportURL: URL?
    @State private var pendingImportData: ExportData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Notifications Section
                        notificationsSection
                        
                        // Data Overview Section
                        dataOverviewSection
                        
                        // Privacy & Data Section
                        privacySection
                    }
                    .padding(Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                }

                // Export loading overlay
                if isExporting {
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                            .scaleEffect(1.2)
                        
                        Text("Preparing your export...")
                            .font(Typography.body)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            Theme.Haptics.light()
                            exportTask?.cancel()
                            exportTask = nil
                            isExporting = false
                        }) {
                            Text("Cancel")
                                .font(Typography.buttonSmall)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.cardBackground)
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                    .padding(Spacing.xl)
                    .background(Color.backgroundCream)
                    .cornerRadius(CornerRadius.lg)
                    .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2).ignoresSafeArea())
                    .transition(.opacity)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url]) {
                        withAnimation {
                            showExportToast = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run {
                                withAnimation {
                                    showExportToast = false
                                }
                            }
                        }
                    }
                }
            }
            .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your journal entries from this device. This action cannot be undone.")
            }
            .alert("Data Deleted", isPresented: $showDeleteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All your data has been successfully deleted from this device.")
            }
            .alert("Notifications Permission Required", isPresented: $showNotificationSettingsAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Notifications are currently disabled. To enable them, please go to Settings > Pocket Forest > Notifications and turn on \"Allow Notifications\".")
            }
            .alert("Import Successful", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All your data has been successfully imported. Your trees, entries, and progress have been restored.")
            }
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportFile(result)
            }
        }
        .overlay(alignment: .bottom) {
            if showExportToast {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primaryGreen)
                    Text("Export ready. You can save or share your file from the sheet you opened.")
                        .font(Typography.caption)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .padding(.bottom, Spacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if showDeleteWarning {
                deleteWarningOverlay
            }
        }
        .overlay {
            if showImportWarning {
                importWarningOverlay
            }
        }
        .overlay {
            if isImporting {
                importLoadingOverlay
            }
        }
        .onAppear {
            // Sync notification toggle with actual authorization status
            Task {
                await notificationService.checkAuthorizationStatus()
                if notificationService.authorizationStatus == .denied {
                    notificationService.preferences.notificationsEnabled = false
                }
            }
        }
    }
    
    // MARK: - Delete Warning Overlay
    
    private var deleteWarningOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDeleteWarning = false
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
                    Text("Delete All Data?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("This will permanently delete all your journal entries, trees, achievements, and exercises from this device. This action cannot be undone.")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Buttons
                VStack(spacing: Spacing.md) {
                    // Destructive action - proceed to system confirmation
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteWarning = false
                        }
                        // Small delay to let the overlay dismiss, then show system confirmation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showDeleteConfirmation = true
                        }
                    }) {
                        Text("Yes, Delete Everything")
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
                            showDeleteWarning = false
                        }
                    }) {
                        Text("Cancel")
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteWarning)
    }
    
    // MARK: - Import Warning Overlay
    
    private var importWarningOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showImportWarning = false
                    }
                }
            
            // Confirmation card
            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.primaryGreen)
                }
                
                // Text
                VStack(spacing: Spacing.sm) {
                    Text("Import Data?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("This will replace all your current journal entries, trees, achievements, and exercises with the imported data. Your current data will be permanently deleted. This action cannot be undone.")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Buttons
                VStack(spacing: Spacing.md) {
                    // Import action
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showImportWarning = false
                        }
                        // Small delay to let the overlay dismiss, then perform import
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            performImport()
                        }
                    }) {
                        Text("Yes, Import Data")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.primaryGreen)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Cancel action
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showImportWarning = false
                            selectedImportURL = nil
                            pendingImportData = nil
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.12))
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showImportWarning)
    }
    
    // MARK: - Import Loading Overlay
    
    private var importLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                    .scaleEffect(1.2)
                
                Text("Importing your data...")
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Please don't close the app")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.xl)
            .background(Color.backgroundCream)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
            .frame(maxWidth: 260)
        }
        .transition(.opacity)
    }
    
    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Reminders", systemImage: "bell.fill")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Card {
                VStack(spacing: Spacing.lg) {
                    Toggle(isOn: Binding(
                        get: { notificationService.preferences.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    await notificationService.checkAuthorizationStatus()

                                    if notificationService.authorizationStatus == .denied {
                                        await MainActor.run {
                                            showNotificationSettingsAlert = true
                                        }
                                    } else {
                                        let granted = await notificationService.requestAuthorization()
                                        await MainActor.run {
                                            notificationService.preferences.notificationsEnabled = granted
                                        }
                                    }
                                }
                            } else {
                                notificationService.preferences.notificationsEnabled = false
                                notificationService.cancelAllNotifications()
                            }
                        }
                    )) {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryGreen.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Reminders")
                                    .font(Typography.body)
                                    .foregroundColor(.textPrimary)
                                Text("Gentle nudges on days you haven't journaled")
                                    .font(Typography.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .tint(.primaryGreen)

                    if notificationService.preferences.notificationsEnabled {
                        Divider()

                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .padding(.top, 1)
                            Text("Two gentle reminders — around 6 PM and 9 PM — on any day you haven't checked in yet. No reminder on days you've already journaled.")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
            }
        }
    }
    
    private func calculateStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let startDay = hasEntryToday ? 0 : 1
        let maxDaysToCheck = entries.count + 1
        
        for i in startDay..<maxDaysToCheck {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: today)!
            if entries.first(where: { calendar.isDate($0.date, inSameDayAs: expectedDate) }) != nil {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Data Overview Section
    
    private var dataOverviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Your Data", systemImage: "doc.text.fill")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            Card {
                VStack(spacing: Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Total Entries")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text("\(entries.count)")
                                .font(Typography.title2)
                                .foregroundColor(.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: Spacing.xs) {
                            Text("Date Range")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text(dateRangeText)
                                .font(Typography.callout)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.primaryGreen)
                        Text("Stored on this device only")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Data & Privacy", systemImage: "hand.raised.fill")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                // Access
                SettingsRow(
                    icon: "eye.fill",
                    iconColor: .primaryGreen,
                    title: "Access Your Data",
                    description: "View all your journal entries in the History tab"
                ) {
                    // Just informational - dismiss and user can go to History
                    Theme.Haptics.light()
                    dismiss()
                }
                
                // Export
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    iconColor: .accentGold,
                    title: "Export Your Data",
                    description: "Download a copy of all your entries"
                ) {
                    Theme.Haptics.light()
                    exportData()
                }
                
                // Import
                SettingsRow(
                    icon: "square.and.arrow.down.fill",
                    iconColor: .primaryGreen,
                    title: "Import Your Data",
                    description: "Restore data from another device"
                ) {
                    Theme.Haptics.light()
                    showImportPicker = true
                }
                
                // Delete
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: .errorRed,
                    title: "Delete All Data",
                    description: "Permanently remove all entries from this device"
                ) {
                    Theme.Haptics.warning()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDeleteWarning = true
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var dateRangeText: String {
        guard !entries.isEmpty else { return "No entries" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        if let oldest = entries.last?.date, let newest = entries.first?.date {
            if Calendar.current.isDate(oldest, inSameDayAs: newest) {
                return formatter.string(from: oldest)
            }
            return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
        }
        return "No entries"
    }
    
    private func exportData() {
        // Prevent multiple exports at the same time
        guard !isExporting else { return }

        exportTask?.cancel()

        exportTask = Task {
            let startTime = Date()
            await MainActor.run {
                withAnimation {
                    isExporting = true
                }
            }

            // Fetch all data models on the main actor (SwiftData-bound)
            let (exportEntries, exportTrees, exportWorryEntries) = await MainActor.run {
                // Entries
                let entriesData = entries.map { entry in
                    ExportEntry(
                        id: entry.id,
                        date: entry.date,
                        emotionRating: entry.emotionRating,
                        transcription: entry.transcription,
                        aiFeedback: entry.aiFeedback,
                        tags: entry.tags,
                        moodCategory: entry.moodCategory,
                        focusArea: entry.focusArea,
                        isFavorite: entry.isFavorite,
                        hasViewedFeedback: entry.hasViewedFeedback,
                        treeStage: entry.treeStage
                    )
                }
                
                // Trees
                let treeDescriptor = FetchDescriptor<GrowingTree>()
                let trees = (try? modelContext.fetch(treeDescriptor)) ?? []
                let treesData = trees.map { tree in
                    ExportTree(
                        id: tree.id,
                        plantedDate: tree.plantedDate,
                        lastWateredDate: tree.lastWateredDate,
                        waterCount: tree.waterCount,
                        treeType: tree.treeType,
                        isFullyGrown: tree.isFullyGrown,
                        position: ExportTreePosition(x: tree.position.x, y: tree.position.y)
                    )
                }
                
                // Worry Tree Entries (from Safe Space - Worry Tree exercise)
                let worryDescriptor = FetchDescriptor<WorryTreeEntry>()
                let worryEntries = (try? modelContext.fetch(worryDescriptor)) ?? []
                let worryData = worryEntries.map { entry in
                    ExportWorryTreeEntry(
                        id: entry.id,
                        date: entry.date,
                        worryText: entry.worryText,
                        canControl: entry.canControl,
                        actionPlan: entry.actionPlan,
                        letGoNote: entry.letGoNote,
                        pandaFeedback: entry.pandaFeedback
                    )
                }
                
                return (entriesData, treesData, worryData)
            }

            if Task.isCancelled { return }

            // Create export with placeholder signature
            var export = ExportData(
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                signature: "", // Placeholder
                entries: exportEntries,
                trees: exportTrees,
                worryTreeEntries: exportWorryEntries
            )

            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.sortedKeys] // Sorted keys for consistent signing
                
                // Get payload for signing (without signature)
                let payloadDict = export.dictionaryForSigning()
                guard let payloadData = DataSecurityService.shared.createPayloadForSigning(payloadDict) else {
                    throw NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create payload for signing"])
                }
                
                // Generate signature
                let signature = DataSecurityService.shared.generateSignature(for: payloadData)
                export.signature = signature
                
                // Re-encode with signature and pretty printing
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(export)

                if Task.isCancelled { return }

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "pocket-forest-export-\(formattedExportDate).json"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try data.write(to: fileURL)

                if Task.isCancelled { return }

                let minimumDuration: TimeInterval = 0.5
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minimumDuration {
                    let remaining = minimumDuration - elapsed
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }

                await MainActor.run {
                    exportURL = fileURL
                    showExportSheet = true
                    withAnimation {
                        isExporting = false
                    }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation {
                        isExporting = false
                    }
                }
                print("Export failed: \(error)")
            }
        }
    }
    
    private var formattedExportDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
    
    private func deleteAllData() {
        do {
            // 1. Delete SwiftData Models
            
            // Emotion Entries (with file cleanup)
            let entryDescriptor = FetchDescriptor<EmotionEntry>()
            let allEntries = try modelContext.fetch(entryDescriptor)
            for entry in allEntries {
                if let url = entry.voiceRecordingURL {
                    try? FileManager.default.removeItem(at: url)
                }
                modelContext.delete(entry)
            }
            
            // Helper to delete all of a type
            func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
                let descriptor = FetchDescriptor<T>()
                let items = try modelContext.fetch(descriptor)
                for item in items {
                    modelContext.delete(item)
                }
            }
            
            try deleteAll(GrowingTree.self)
            try deleteAll(Achievement.self)
            try deleteAll(Quote.self)
            try deleteAll(CalmSession.self)
            try deleteAll(WorryTreeEntry.self)
            
            try modelContext.save()
            
            // 2. Reset UserDefaults (preserving onboarding state)
            let defaults = UserDefaults.standard
            let onboardingCompleted = defaults.bool(forKey: "hasCompletedOnboarding")
            
            if let bundleID = Bundle.main.bundleIdentifier {
                defaults.removePersistentDomain(forName: bundleID)
            }
            
            // Restore onboarding state
            defaults.set(onboardingCompleted, forKey: "hasCompletedOnboarding")
            defaults.synchronize()
            
            showDeleteSuccess = true
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    // MARK: - Import Functions
    
    private func handleImportFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedImportURL = url
            
            // Validate file first
            do {
                let exportData = try DataImportService().validateAndParse(fileURL: url)
                pendingImportData = exportData
                // Valid file - show warning
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showImportWarning = true
                }
            } catch let error as DataImportService.ImportError {
                switch error {
                case .signatureValidationFailed:
                    importErrorMessage = "This file was not exported from Pocket Forest or has been modified."
                case .invalidFile:
                    importErrorMessage = "Unable to read this file. Please ensure it's a valid Pocket Forest export."
                case .corruptedData:
                    importErrorMessage = "The export file appears to be corrupted or contains invalid data."
                case .incompatibleVersion:
                    importErrorMessage = "This export was created with an incompatible version of Pocket Forest."
                case .importFailed(let message):
                    importErrorMessage = "Import failed: \(message)"
                }
                showImportError = true
            } catch {
                importErrorMessage = "Unable to read this file. Please ensure it's a valid Pocket Forest export."
                showImportError = true
            }
            
        case .failure(let error):
            print("File picker error: \(error)")
            importErrorMessage = "Could not access the selected file."
            showImportError = true
        }
    }
    
    private func performImport() {
        guard let url = selectedImportURL else { return }
        
        withAnimation {
            isImporting = true
        }
        
        Task {
            do {
                let exportData = try DataImportService().validateAndParse(fileURL: url)
                try DataImportService().importData(exportData, to: modelContext)
                
                await MainActor.run {
                    withAnimation {
                        isImporting = false
                    }
                    selectedImportURL = nil
                    pendingImportData = nil
                    showImportSuccess = true
                    Theme.Haptics.success()
                }
            } catch let error as DataImportService.ImportError {
                await MainActor.run {
                    withAnimation {
                        isImporting = false
                    }
                    selectedImportURL = nil
                    pendingImportData = nil
                    importErrorMessage = error.localizedDescription
                    showImportError = true
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        isImporting = false
                    }
                    selectedImportURL = nil
                    pendingImportData = nil
                    importErrorMessage = "Import failed. Please try again."
                    showImportError = true
                }
            }
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            .padding(Layout.cardPadding)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .pressAnimation()
    }
}

// MARK: - Export Models

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    var signature: String // HMAC-SHA256 signature (mutable for signing process)
    let entries: [ExportEntry]
    let trees: [ExportTree]
    // NOTE: Achievements are NOT exported/imported because they:
    // - Auto-initialize on first launch
    // - Auto-backfill progress from entries/trees on import
    // - Are recalculated to match the imported data
    // NOTE: CalmSessions are NOT exported/imported because:
    // - The app doesn't currently track calm sessions
    // - This was planned functionality that isn't implemented yet
    let worryTreeEntries: [ExportWorryTreeEntry]
    
    /// Create a dictionary for signing (excludes signature field)
    func dictionaryForSigning() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Encode to JSON then decode to dictionary to get proper representation
        guard let data = try? encoder.encode(self),
              var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        dict.removeValue(forKey: "signature")
        return dict
    }
}

struct ExportEntry: Codable {
    let id: UUID
    let date: Date
    let emotionRating: Int
    let transcription: String?
    let aiFeedback: String?
    let tags: [String]?
    let moodCategory: String?
    let focusArea: String?
    let isFavorite: Bool
    let hasViewedFeedback: Bool
    let treeStage: Int
}

struct ExportTree: Codable {
    let id: UUID
    let plantedDate: Date
    let lastWateredDate: Date?
    let waterCount: Int
    let treeType: String
    let isFullyGrown: Bool
    let position: ExportTreePosition
}

struct ExportTreePosition: Codable {
    let x: Double
    let y: Double
}

struct ExportWorryTreeEntry: Codable {
    let id: UUID
    let date: Date
    let worryText: String
    let canControl: Bool?
    let actionPlan: String?
    let letGoNote: String?
    let pandaFeedback: String?
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
