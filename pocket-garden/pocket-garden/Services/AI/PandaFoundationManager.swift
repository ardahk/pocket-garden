//
//  PandaFoundationManager.swift
//  pocket-garden
//
//  Manages Apple Foundation Models availability checking.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class PandaFoundationManager {
    static let shared = PandaFoundationManager()
    private init() {}

    private(set) var notAvailableReason: String = ""

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                notAvailableReason = ""
                return true
            case .unavailable(.deviceNotEligible):
                notAvailableReason = "This device is not eligible for Apple Intelligence."
                return false
            case .unavailable(.appleIntelligenceNotEnabled):
                notAvailableReason = "Enable Apple Intelligence in Settings to get richer Bumblebee feedback."
                return false
            case .unavailable(.modelNotReady):
                notAvailableReason = "Apple Intelligence is downloading models. Connect to power and Wi‑Fi, then try again."
                return false
            case .unavailable(let other):
                notAvailableReason = "Apple Intelligence unavailable: \(String(describing: other))."
                return false
            }
        }
        #endif
        notAvailableReason = "Apple Intelligence requires iOS 26 or later."
        return false
    }
}
