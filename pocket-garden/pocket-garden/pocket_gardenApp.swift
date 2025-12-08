//
//  pocket_gardenApp.swift
//  pocket-garden
//
//  Created by Arda Hoke on 11/6/25.
//

import SwiftUI
import SwiftData

@main
struct pocket_gardenApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    MainTabView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    OnboardingView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: hasCompletedOnboarding)
        }
        .modelContainer(for: [EmotionEntry.self, GrowingTree.self, Quote.self, Achievement.self, CalmSession.self, WorryTreeEntry.self])
    }
}
