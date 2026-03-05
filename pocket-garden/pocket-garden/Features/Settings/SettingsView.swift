//
//  SettingsView.swift
//  pocket-garden
//
//  Settings & Privacy View
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @DevObserveInjection var inject: DevInjectionToken
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("userFirstName") private var userFirstName = ""
    @State private var editableFirstName = ""
    
    @State private var showExportSheet = false
    @State private var isExporting = false
    @State private var showExportToast = false
    @State private var showDeleteWarning = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var exportURL: URL?
    @State private var exportTask: Task<Void, Never>? = nil
    @State private var showNotificationSettingsAlert = false
    @State private var showFeedbackLaunchPrompt = false
    @State private var showFeedbackErrorAlert = false
    @State private var feedbackErrorMessage = ""
    
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
        settingsView
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
            .overlay {
                if showFeedbackLaunchPrompt {
                    feedbackLaunchOverlay
                }
            }
            .onAppear {
                editableFirstName = UserNameSanitizer.filterForInput(userFirstName)
                Task {
                    await notificationService.checkAuthorizationStatus()
                    syncNotificationToggleWithSystemStatus()
                }
            }
            .onChange(of: editableFirstName) { _, newValue in
                let filtered = UserNameSanitizer.filterForInput(newValue)
                if filtered != newValue {
                    editableFirstName = filtered
                }
            }
            .onChange(of: notificationService.authorizationStatus) { _, _ in
                syncNotificationToggleWithSystemStatus()
            }
            .devEnableInjection()
    }

    private var settingsView: some View {
        NavigationStack {
            settingsContent
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
        .alert("Couldn't Open Email", isPresented: $showFeedbackErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(feedbackErrorMessage)
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportFile(result)
        }
    }

    private var settingsContent: some View {
        ZStack {
            Color.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    personalizationSection
                    notificationsSection
                    dataOverviewSection
                    privacySection
                }
                .padding(Layout.screenPadding)
                .padding(.bottom, Spacing.xxxl)
            }

            if isExporting {
                exportLoadingOverlayCard
            }
        }
    }

    private var exportLoadingOverlayCard: some View {
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

    // MARK: - Feedback Launch Overlay

    private var feedbackLaunchOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        showFeedbackLaunchPrompt = false
                    }
                }

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.14))
                        .frame(width: 72, height: 72)

                    Text("🐝")
                        .font(.system(size: 34))
                }

                VStack(spacing: Spacing.sm) {
                    Text("Send Feedback")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("Bumblebee is about to open your favorite mail app.")
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                VStack(spacing: Spacing.md) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            showFeedbackLaunchPrompt = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            openFeedbackEmail()
                        }
                    } label: {
                        Text("Open")
                            .font(Typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.primaryGreen)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            showFeedbackLaunchPrompt = false
                        }
                    } label: {
                        Text("Not Now")
                            .font(Typography.buttonSmall)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.backgroundCream)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 28, y: 10)
            )
            .padding(.horizontal, Spacing.xl)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: showFeedbackLaunchPrompt)
    }
    
    // MARK: - Notifications Section

    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Name", systemImage: "person.fill")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("What should Bumblebee call you?")
                        .font(Typography.body)
                        .foregroundColor(.textPrimary)

                    TextField("First name", text: $editableFirstName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundCream)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primaryGreen.opacity(0.2), lineWidth: 1)
                                )
                        )

                    if hasNameChanges {
                        Button(action: {
                            let trimmed = UserNameSanitizer.sanitize(editableFirstName)
                            guard !trimmed.isEmpty else { return }
                            editableFirstName = trimmed
                            userFirstName = trimmed
                            Theme.Haptics.success()
                        }) {
                            Text("Save Name")
                                .font(Typography.buttonSmall)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primaryGreen)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isNameInputValid)
                        .opacity(isNameInputValid ? 1 : 0.55)
                    }

                    Text("Used only on this device to personalize Bumblebee feedback.")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Reminders", systemImage: "bell.fill")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Card {
                VStack(spacing: Spacing.lg) {
                    Toggle(isOn: Binding(
                        get: {
                            notificationService.preferences.notificationsEnabled && canDeliverNotifications
                        },
                        set: { newValue in
                            if newValue {
                                Task {
                                    await notificationService.checkAuthorizationStatus()

                                    if notificationService.authorizationStatus == .denied {
                                        await MainActor.run {
                                            notificationService.preferences.notificationsEnabled = false
                                            showNotificationSettingsAlert = true
                                        }
                                    } else {
                                        let granted = await notificationService.requestAuthorization()
                                        await notificationService.checkAuthorizationStatus()
                                        await MainActor.run {
                                            notificationService.preferences.notificationsEnabled = granted
                                            if !granted {
                                                notificationService.cancelAllNotifications()
                                                if notificationService.authorizationStatus == .denied {
                                                    showNotificationSettingsAlert = true
                                                }
                                            }
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

            Text("Data stays on this device. To move devices, export then import.")
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
            
            VStack(spacing: Spacing.md) {
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: .primaryGreen,
                    title: "Send Feedback",
                    description: "We read every message, your thoughts shape the app"
                ) {
                    Theme.Haptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        showFeedbackLaunchPrompt = true
                    }
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

    private var isNameInputValid: Bool {
        !UserNameSanitizer.sanitize(editableFirstName).isEmpty
    }

    private var hasNameChanges: Bool {
        UserNameSanitizer.sanitize(editableFirstName) != UserNameSanitizer.sanitize(userFirstName)
    }

    private var canDeliverNotifications: Bool {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    private func syncNotificationToggleWithSystemStatus() {
        if !canDeliverNotifications {
            notificationService.preferences.notificationsEnabled = false
        }
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
            let trimmedName = UserNameSanitizer.sanitize(userFirstName)
            var export = ExportData(
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                signature: "", // Placeholder
                userFirstName: trimmedName.isEmpty ? nil : trimmedName,
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
            }
        }
    }
    
    private var formattedExportDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var feedbackRecipient: String { "support@pocketforest.app" }
    private var feedbackSubject: String {
        let name = UserNameSanitizer.sanitize(userFirstName)
        return name.isEmpty ? "Thank you" : "Thank you \(name)"
    }
    private var feedbackBody: String {
        """
        Thank you for sending us a feedback message. You can edit this email, and we are looking forward to responding within 24-48 hours.
        """
    }
    
    private func openFeedbackEmail() {
        let url = FeedbackEmailClient.defaultMail.composeURL(to: feedbackRecipient, subject: feedbackSubject, body: feedbackBody)
        guard UIApplication.shared.canOpenURL(url) else {
            feedbackErrorMessage = "No compatible mail app was found. Please install a mail app and try again."
            showFeedbackErrorAlert = true
            return
        }
        UIApplication.shared.open(url)
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
                    importErrorMessage = "This file doesn't appear to be a valid Pocket Forest export. You can only import files that were exported directly from this app."
                case .invalidFile:
                    importErrorMessage = "Couldn't read this file. Make sure you're importing a file that was exported from Pocket Forest."
                case .corruptedData:
                    importErrorMessage = "This export file appears to be corrupted. Please try exporting again from the original device."
                case .incompatibleVersion:
                    importErrorMessage = "This export was created with an incompatible version of Pocket Forest."
                case .importFailed(let message):
                    importErrorMessage = "Import failed: \(message)"
                }
                showImportError = true
            } catch {
                importErrorMessage = "Couldn't import this file. Only files exported from Pocket Forest can be imported."
                showImportError = true
            }
            
        case .failure:
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
    }
}

// MARK: - Export Models

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    var signature: String // HMAC-SHA256 signature (mutable for signing process)
    let userFirstName: String?
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

private enum FeedbackEmailClient {
    case defaultMail

    func composeURL(to recipient: String, subject: String, body: String) -> URL {
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? recipient
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body

        switch self {
        case .defaultMail:
            return URL(string: "mailto:\(encodedRecipient)?subject=\(encodedSubject)&body=\(encodedBody)")!
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
