//
//  DataImportService.swift
//  pocket-garden
//
//  Service for validating and importing exported data
//

import Foundation
import SwiftData

/// Service for importing exported Pocket Forest data
final class DataImportService {
    
    // MARK: - Testing Configuration
    
    /// 🔒 SECURITY FLAG - SIGNATURE VALIDATION
    /// 
    /// CURRENT STATUS: ENABLED (signature validation is ACTIVE)
    /// 
    /// This flag controls whether HMAC-SHA256 signature validation is enforced.
    /// When enabled (false), only files exported by the app can be imported.
    /// This prevents users from manually editing JSON or importing malicious files.
    /// 
    /// ⚠️ FOR TESTING ONLY: Set to true to bypass signature validation
    /// This should NEVER be true in production builds!
    private let bypassSignatureValidation = false // 🔒 SECURITY ENABLED
    
    // MARK: - Error Types
    
    enum ImportError: Error, LocalizedError {
        case invalidFile
        case signatureValidationFailed
        case corruptedData
        case incompatibleVersion
        case importFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return "The file is not a valid Pocket Forest export."
            case .signatureValidationFailed:
                return "This file was not exported from Pocket GaForestrden or has been modified."
            case .corruptedData:
                return "The export file appears to be corrupted."
            case .incompatibleVersion:
                return "This export was created with an incompatible version of Pocket Forest."
            case .importFailed(let message):
                return "Import failed: \(message)"
            }
        }
    }
    
    // MARK: - Validation
    
    /// Validate and parse an export file
    /// - Parameter fileURL: URL to the export JSON file
    /// - Returns: Parsed ExportData if valid
    /// - Throws: ImportError if validation fails
    func validateAndParse(fileURL: URL) throws -> ExportData {
        // Start accessing security-scoped resource
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFile
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        // Read file data
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: fileURL)
        } catch {
            throw ImportError.invalidFile
        }
        
        // Extract signature and validate
        // NOTE: Signature validation can be bypassed for testing (see bypassSignatureValidation flag)
        if !bypassSignatureValidation {
            guard let (payloadData, signature) = DataSecurityService.shared.stripSignature(from: jsonData) else {
                throw ImportError.corruptedData
            }
            
            // SECURITY: Validate HMAC-SHA256 signature to ensure file authenticity
            // This prevents importing tampered or malicious JSON files
            guard DataSecurityService.shared.validateSignature(signature, for: payloadData) else {
                throw ImportError.signatureValidationFailed
            }
        }
        
        // Decode the full export data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData: ExportData
        do {
            exportData = try decoder.decode(ExportData.self, from: jsonData)
        } catch {
            throw ImportError.corruptedData
        }
        
        // Validate data integrity
        try validateDataIntegrity(exportData)
        
        return exportData
    }
    
    // MARK: - Data Integrity Validation
    
    private func validateDataIntegrity(_ data: ExportData) throws {
        // Validate emotion ratings are in range
        for entry in data.entries {
            if entry.emotionRating < 1 || entry.emotionRating > 10 {
                throw ImportError.corruptedData
            }
        }
        
        // Validate tree types
        let validTreeTypes = Set(["oak", "pine", "cherry"])
        for tree in data.trees {
            if !validTreeTypes.contains(tree.treeType) {
                throw ImportError.corruptedData
            }
        }
        
        // Validate dates are reasonable (not too far in future)
        let maxFutureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let minPastDate = Calendar.current.date(byAdding: .year, value: -50, to: Date()) ?? Date()
        
        for entry in data.entries {
            if entry.date > maxFutureDate || entry.date < minPastDate {
                throw ImportError.corruptedData
            }
        }
    }
    
    // MARK: - Import
    
    /// Import data into the model context
    /// - Parameters:
    ///   - exportData: The validated export data
    ///   - context: The SwiftData model context
    @MainActor
    func importData(_ exportData: ExportData, to context: ModelContext) throws {
        // First, clear all existing data
        try clearAllData(from: context)
        
        // Import Emotion Entries
        for exportEntry in exportData.entries {
            let entry = EmotionEntry(
                emotionRating: exportEntry.emotionRating,
                date: exportEntry.date,
                transcription: exportEntry.transcription,
                aiFeedback: exportEntry.aiFeedback,
                treeStage: exportEntry.treeStage,
                tags: exportEntry.tags
            )
            // Set additional properties that aren't in the initializer
            entry.moodCategory = exportEntry.moodCategory
            entry.focusArea = exportEntry.focusArea
            entry.isFavorite = exportEntry.isFavorite
            entry.hasViewedFeedback = exportEntry.hasViewedFeedback
            
            context.insert(entry)
        }
        
        // Import Growing Trees
        for exportTree in exportData.trees {
            let tree = GrowingTree(
                id: exportTree.id,
                plantedDate: exportTree.plantedDate,
                lastWateredDate: exportTree.lastWateredDate,
                waterCount: exportTree.waterCount,
                treeType: exportTree.treeType,
                isFullyGrown: exportTree.isFullyGrown,
                position: GrowingTreePosition(x: exportTree.position.x, y: exportTree.position.y)
            )
            context.insert(tree)
        }
        
        // NOTE: Achievements are NOT imported because they:
        // - Are automatically initialized by AchievementManager on app launch
        // - Will be backfilled with correct progress based on imported entries/trees
        // - This ensures achievement progress always matches the actual data
        
        // NOTE: CalmSessions are NOT imported because:
        // - This feature isn't currently tracking sessions in the app
        // - Planned for future but not implemented yet
        
        // Import Worry Tree Entries (from Safe Space - Worry Tree exercise)
        for exportWorry in exportData.worryTreeEntries {
            let worry = WorryTreeEntry(
                id: exportWorry.id,
                date: exportWorry.date,
                worryText: exportWorry.worryText,
                canControl: exportWorry.canControl,
                actionPlan: exportWorry.actionPlan,
                letGoNote: exportWorry.letGoNote,
                pandaFeedback: exportWorry.pandaFeedback
            )
            context.insert(worry)
        }
        
        // Save context
        do {
            try context.save()
        } catch {
            throw ImportError.importFailed(error.localizedDescription)
        }
        
        // Backfill achievement progress
        backfillAchievementProgress(context: context)
    }
    
    // MARK: - Clear Data
    
    @MainActor
    private func clearAllData(from context: ModelContext) throws {
        // Delete Emotion Entries (with file cleanup)
        let entryDescriptor = FetchDescriptor<EmotionEntry>()
        let allEntries = try context.fetch(entryDescriptor)
        for entry in allEntries {
            if let url = entry.voiceRecordingURL {
                try? FileManager.default.removeItem(at: url)
            }
            context.delete(entry)
        }
        
        // Delete all GrowingTrees
        let treeDescriptor = FetchDescriptor<GrowingTree>()
        let trees = try context.fetch(treeDescriptor)
        for tree in trees {
            context.delete(tree)
        }
        
        // NOTE: Achievements are NOT deleted because:
        // - They auto-initialize if missing
        // - Progress is recalculated by backfillAchievementProgress() after import
        // - This ensures achievements always match the imported data
        
        // NOTE: CalmSessions are NOT deleted/imported (feature not fully implemented)
        
        // Delete all WorryTreeEntries
        let worryDescriptor = FetchDescriptor<WorryTreeEntry>()
        let worries = try context.fetch(worryDescriptor)
        for worry in worries {
            context.delete(worry)
        }
        
        // Save deletions
        try context.save()
    }
    
    // MARK: - Backfill Achievements
    
    @MainActor
    private func backfillAchievementProgress(context: ModelContext) {
        // Fetch all entries and trees for achievement calculation
        let entryDescriptor = FetchDescriptor<EmotionEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let treeDescriptor = FetchDescriptor<GrowingTree>()
        
        guard let entries = try? context.fetch(entryDescriptor),
              let trees = try? context.fetch(treeDescriptor) else { return }
        
        // Calculate current streak
        let streak = calculateStreak(entries: entries)
        
        // Run achievement check
        AchievementManager.shared.checkAndUpdateAchievements(
            entries: entries,
            trees: trees,
            currentStreak: streak,
            modelContext: context
        )
    }
    
    private func calculateStreak(entries: [EmotionEntry]) -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let startDay = hasEntryToday ? 0 : 1
        let maxDaysToCheck = entries.count + 1
        
        for i in startDay..<maxDaysToCheck {
            guard let expectedDate = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            if entries.first(where: { calendar.isDate($0.date, inSameDayAs: expectedDate) }) != nil {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}

