import XCTest
@testable import MeowPlay

@MainActor
final class AudioPlayerTests: XCTestCase {
    func testMissingAudioIsAReadableFailure() {
        let player = AudioPlayer(bundle: Bundle(for: AudioPlayerTests.self))
        let card = SoundCard(
            id: "missing",
            title: "Missing",
            category: .greeting,
            tier: .free,
            safetyTag: .gentle,
            assetName: "definitely_missing.m4a",
            sortOrder: 1,
            contentVersion: 1
        )

        XCTAssertFalse(player.play(card))
        XCTAssertTrue(player.errorMessage?.contains("Audio coming soon") == true)
        XCTAssertNil(player.playingSoundID)
    }
}
