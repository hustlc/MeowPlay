import SwiftData
import XCTest
@testable import MeowPlay

@MainActor
final class LocalPersistenceTests: XCTestCase {
    func testPlaylistToggleDoesNotDuplicateSound() {
        let playlist = SoundPlaylist(name: "Play Time")

        playlist.toggle(soundID: "play_with_me")
        playlist.toggle(soundID: "play_with_me")
        playlist.toggle(soundID: "play_with_me")

        XCTAssertEqual(playlist.soundIDs, ["play_with_me"])
    }

    func testFavoriteAndReactionPersistInMemory() throws {
        let schema = Schema([FavoriteEntry.self, ReactionEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        context.insert(FavoriteEntry(soundID: "come_here"))
        context.insert(ReactionEntry(soundID: "come_here", reaction: .cameCloser))
        try context.save()

        let favorites = try context.fetch(FetchDescriptor<FavoriteEntry>())
        let reactions = try context.fetch(FetchDescriptor<ReactionEntry>())
        XCTAssertEqual(favorites.map(\.soundID), ["come_here"])
        XCTAssertEqual(reactions.first?.reaction, .cameCloser)
    }
}

