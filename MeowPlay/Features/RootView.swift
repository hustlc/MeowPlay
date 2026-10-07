import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .tint(.purple)
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            CatalogView()
                .tabItem { Label("Sounds", systemImage: "waveform") }

            PhraseTranslatorView()
                .tabItem { Label("Translate", systemImage: "character.bubble") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart.fill") }

            JournalView()
                .tabItem { Label("Journal", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
