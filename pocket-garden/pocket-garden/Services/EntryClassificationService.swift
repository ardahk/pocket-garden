//
//  EntryClassificationService.swift
//  pocket-garden
//
//  AFM-based Entry Classification Service
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
class EntryClassificationService {
    private var session: LanguageModelSession?
    
    init() {
        setupSession()
    }
    
    private func setupSession() {
        let instructions = """
        You are a journal entry classifier. Analyze journal entries and categorize them with exactly 2 tags:
        
        1. MOOD CATEGORY (what's happening overall): Choose ONE from:
           - Productive
           - Mindful
           - Reflective
           - Excited
           - Grateful
           - Anxious
           - Peaceful
           - Energized
           - Contemplative
           - Joyful
        
        2. FOCUS AREA (what to focus on): Choose ONE from:
           - Gratitude
           - Goals
           - Family
           - Career
           - Health
           - Relationships
           - Self-care
           - Growth
           - Creativity
           - Balance
        
        Respond in this exact JSON format:
        {
          "moodCategory": "<category>",
          "focusArea": "<area>"
        }
        
        Only respond with valid JSON, nothing else.
        """
        
        session = try? LanguageModelSession(instructions: instructions)
    }
    
    func classifyEntry(transcription: String) async throws -> (moodCategory: String, focusArea: String) {
        guard let session = session else {
            throw ClassificationError.sessionNotAvailable
        }
        
        let prompt = "Classify this journal entry:\n\n\(transcription)"
        
        var fullResponse = ""
        
        do {
            let stream = session.streamResponse(to: prompt)
            for try await partialResponse in stream {
                fullResponse += partialResponse.content
            }
            
            // Parse JSON response
            guard let data = fullResponse.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let mood = json["moodCategory"],
                  let focus = json["focusArea"] else {
                throw ClassificationError.invalidResponse
            }
            
            return (moodCategory: mood, focusArea: focus)
            
        } catch {
            throw ClassificationError.classificationFailed(error.localizedDescription)
        }
    }
    
    enum ClassificationError: Error {
        case sessionNotAvailable
        case invalidResponse
        case classificationFailed(String)
    }
}

// Fallback classification for when AFM is not available
class FallbackClassificationService {
    func classifyEntry(transcription: String, rating: Int) -> (moodCategory: String, focusArea: String) {
        let text = transcription.lowercased()
        
        // Simple keyword-based classification
        let moodCategory: String
        let focusArea: String
        
        // Determine mood based on keywords and rating
        if rating >= 8 {
            if text.contains("accomplish") || text.contains("done") || text.contains("finish") {
                moodCategory = "Productive"
            } else if text.contains("excit") || text.contains("opport") {
                moodCategory = "Excited"
            } else if text.contains("thank") || text.contains("grateful") {
                moodCategory = "Grateful"
            } else {
                moodCategory = "Joyful"
            }
        } else if rating >= 6 {
            if text.contains("calm") || text.contains("peace") {
                moodCategory = "Peaceful"
            } else if text.contains("think") || text.contains("reflect") {
                moodCategory = "Reflective"
            } else {
                moodCategory = "Mindful"
            }
        } else {
            if text.contains("worry") || text.contains("stress") || text.contains("anxious") {
                moodCategory = "Anxious"
            } else {
                moodCategory = "Contemplative"
            }
        }
        
        // Determine focus area based on keywords
        if text.contains("work") || text.contains("job") || text.contains("career") || text.contains("project") {
            focusArea = "Career"
        } else if text.contains("family") || text.contains("mom") || text.contains("dad") || text.contains("sibling") {
            focusArea = "Family"
        } else if text.contains("friend") || text.contains("relationship") {
            focusArea = "Relationships"
        } else if text.contains("health") || text.contains("exercise") || text.contains("sleep") {
            focusArea = "Health"
        } else if text.contains("goal") || text.contains("plan") || text.contains("achieve") {
            focusArea = "Goals"
        } else if text.contains("grateful") || text.contains("thank") || text.contains("appreciate") {
            focusArea = "Gratitude"
        } else if text.contains("learn") || text.contains("grow") {
            focusArea = "Growth"
        } else if text.contains("rest") || text.contains("relax") || text.contains("care") {
            focusArea = "Self-care"
        } else {
            focusArea = "Balance"
        }
        
        return (moodCategory: moodCategory, focusArea: focusArea)
    }
}
