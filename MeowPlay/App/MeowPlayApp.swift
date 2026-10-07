import SwiftData
import SwiftUI

@main
struct MeowPlayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var catalog = CatalogStore()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var entitlements = EntitlementStore()

    private let modelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(catalog)
                .environmentObject(audioPlayer)
                .environmentObject(entitlements)
                .task { await entitlements.start() }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        audioPlayer.stop()
                    } else {
                        Task { await entitlements.refreshEntitlements() }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

private enum AppModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([
            FavoriteEntry.self,
            PlaybackEntry.self,
            ReactionEntry.self,
            SoundPlaylist.self
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Keep the soundboard usable if local history storage is unavailable.
            let memoryOnly = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryOnly])
            } catch {
                fatalError("The local data model could not be created: \(error)")
            }
        }
    }
}
