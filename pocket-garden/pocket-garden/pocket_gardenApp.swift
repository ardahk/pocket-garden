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
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: EmotionEntry.self)
    }
}
