import XCTest
@testable import MeowPlay

final class PhraseTranslatorTests: XCTestCase {
    func testComeHerePhraseSelectsComeHereSound() {
        let translator = PhraseTranslator()
        let result = translator.translate("过来陪我", cards: sampleCards())

        XCTAssertEqual(result?.card.category, .comeHere)
        XCTAssertEqual(result?.card.title, "Come Here")
    }

    func testUnknownPhraseFallsBackToFirstSafeSound() {
        let translator = PhraseTranslator()
        let result = translator.translate("Good night, friend", cards: sampleCards())

        XCTAssertEqual(result?.card.title, "I'm Mom")
    }

    func testBlankPhraseReturnsNoTranslation() {
        let translator = PhraseTranslator()

        XCTAssertNil(translator.translate("   ", cards: sampleCards()))
    }

    private func sampleCards() -> [SoundCard] {
        [
            SoundCard(
                id: "come_here",
                title: "Come Here",
                category: .comeHere,
                tier: .free,
                safetyTag: .gentle,
                assetName: "come_here.m4a",
                sortOrder: 1,
                contentVersion: 1
            ),
            SoundCard(
                id: "im_mom",
                title: "I'm Mom",
                category: .affection,
                tier: .free,
                safetyTag: .gentle,
                assetName: "im_mom.m4a",
                sortOrder: 2,
                contentVersion: 1
            )
        ]
    }
}
