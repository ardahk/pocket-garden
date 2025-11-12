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
    @UIApplicationDelegateAdaptor(AppDelegate.class) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Lock orientation to portrait
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UINavigationController.attemptRotationToDeviceOrientation()
                }
        }
        .modelContainer(for: EmotionEntry.self)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .portrait
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure appearance for dark mode support
        configureAppearance()
        return true
    }

    private func configureAppearance() {
        // Ensure tab bar looks good in both light and dark mode
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()

        // Light mode
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundCream)

        // Dark mode - use system background
        if let darkAppearance = UITraitCollection(userInterfaceStyle: .dark).performAsCurrent({
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            return appearance
        }) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
        }

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.backgroundCream)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
