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
    
    @State private var showExportSheet = false
    @State private var isExporting = false
    @State private var showExportToast = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var exportURL: URL?
    @State private var exportTask: Task<Void, Never>? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
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
                
                // Delete
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: .errorRed,
                    title: "Delete All Data",
                    description: "Permanently remove all entries from this device"
                ) {
                    Theme.Haptics.warning()
                    showDeleteConfirmation = true
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

            // Build export entries on the main actor (SwiftData-bound)
            let exportEntries: [ExportEntry] = await MainActor.run {
                entries.map { entry in
                    ExportEntry(
                        date: entry.date,
                        emotionRating: entry.emotionRating,
                        transcription: entry.transcription,
                        aiFeedback: entry.aiFeedback,
                        tags: entry.tags,
                        moodCategory: entry.moodCategory,
                        focusArea: entry.focusArea,
                        isFavorite: entry.isFavorite
                    )
                }
            }

            if Task.isCancelled { return }

            if Task.isCancelled { return }

            let export = ExportData(
                exportDate: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                entries: exportEntries
            )

            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

                let data = try encoder.encode(export)

                if Task.isCancelled { return }

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "pocket-garden-export-\(formattedExportDate).json"
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
    let entries: [ExportEntry]
}

struct ExportEntry: Codable {
    let date: Date
    let emotionRating: Int
    let transcription: String?
    let aiFeedback: String?
    let tags: [String]?
    let moodCategory: String?
    let focusArea: String?
    let isFavorite: Bool
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
