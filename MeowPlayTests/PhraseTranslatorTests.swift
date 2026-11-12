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

        XCTAssertEqual(result?.card.title, "Come Here")
        XCTAssertEqual(result?.mood, "a gentle cat-sound guess")
    }

    func testBlankPhraseReturnsNoTranslation() {
        let translator = PhraseTranslator()

        XCTAssertNil(translator.translate("   ", cards: sampleCards()))
    }

    func testEmptyCatalogReturnsNoTranslation() {
        let translator = PhraseTranslator()

        XCTAssertNil(translator.translate("过来", cards: [], prefersFreeCards: true))
    }

    func testFreeUserPrefersPlayableFreeCard() {
        let cards = [
            card(id: "premium_attention", title: "Premium Attention", category: .attention, tier: .premium, sortOrder: 1),
            card(id: "free_attention", title: "Free Attention", category: .attention, tier: .free, sortOrder: 2)
        ]
        let result = PhraseTranslator().translate("look at me", cards: cards, prefersFreeCards: true)

        XCTAssertEqual(result?.card.id, "free_attention")
        XCTAssertFalse(result?.card.isPremium ?? true)
    }

    func testPremiumUserUsesFullLibrary() {
        let cards = [
            card(id: "premium_attention", title: "Premium Attention", category: .attention, tier: .premium, sortOrder: 1),
            card(id: "free_attention", title: "Free Attention", category: .attention, tier: .free, sortOrder: 2)
        ]
        let result = PhraseTranslator().translate("look at me", cards: cards, prefersFreeCards: false)

        XCTAssertEqual(result?.card.id, "premium_attention")
        XCTAssertTrue(result?.card.isPremium ?? false)
    }

    func testFreeUserFallsBackToLockedCardWhenCategoryHasNoFreeSound() {
        let cards = [
            card(id: "free_play", title: "Play With Me", category: .playTime, tier: .free, sortOrder: 1),
            card(id: "premium_food", title: "Dinner Is Ready", category: .foodTime, tier: .premium, sortOrder: 2)
        ]
        let result = PhraseTranslator().translate("dinner time", cards: cards, prefersFreeCards: true)

        XCTAssertEqual(result?.card.id, "premium_food")
        XCTAssertEqual(result?.card.category, .foodTime)
        XCTAssertTrue(result?.card.isPremium ?? false)
    }

    func testFreeUserWithNoFreeLibraryStillGetsAResult() {
        let cards = [
            card(id: "premium_attention", title: "Premium Attention", category: .attention, tier: .premium, sortOrder: 1)
        ]
        let result = PhraseTranslator().translate("look at me", cards: cards, prefersFreeCards: true)

        XCTAssertEqual(result?.card.id, "premium_attention")
    }

    func testMatchedIntentWithoutMatchingCardUsesGentleFallback() {
        let cards = [
            card(id: "free_play", title: "Play With Me", category: .playTime, tier: .free, sortOrder: 1)
        ]
        let result = PhraseTranslator().translate("dinner time", cards: cards, prefersFreeCards: true)

        XCTAssertEqual(result?.card.id, "free_play")
        XCTAssertEqual(result?.mood, "a gentle cat-sound guess")
    }

    func testFirstMatchingRuleWinsForMixedPhrase() {
        let cards = [
            card(id: "free_come", title: "Come Here", category: .comeHere, tier: .free, sortOrder: 1),
            card(id: "free_play", title: "Play With Me", category: .playTime, tier: .free, sortOrder: 2)
        ]
        let result = PhraseTranslator().translate("过来陪我玩", cards: cards, prefersFreeCards: true)

        XCTAssertEqual(result?.card.id, "free_come")
        XCTAssertEqual(result?.mood, "a friendly invitation")
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

    private func card(
        id: String,
        title: String,
        category: SoundCategory,
        tier: AccessTier,
        sortOrder: Int
    ) -> SoundCard {
        SoundCard(
            id: id,
            title: title,
            category: category,
            tier: tier,
            safetyTag: .gentle,
            assetName: "\(id).m4a",
            sortOrder: sortOrder,
            contentVersion: 1
        )
    }
}
