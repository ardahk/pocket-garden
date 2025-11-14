//
//  MainTabView.swift
//  pocket-garden
//
//  Main Navigation - Tab Bar
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            // Forest Tab
            NavigationStack {
                ForestGardenViewRedesigned()
            }
            .tabItem {
                Label("Garden", systemImage: "leaf.fill")
            }
            .tag(1)

            // History Tab
            NavigationStack {
                EntriesListViewRedesigned()
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(2)
        }
        .accentColor(.primaryGreen)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.backgroundCream)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
