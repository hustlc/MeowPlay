import XCTest
@testable import MeowPlay

final class CatalogStoreTests: XCTestCase {
    func testBundledCatalogHasExpectedShape() throws {
        let cards = try CatalogStore.load(from: Bundle(for: CatalogStoreTests.self))

        XCTAssertEqual(cards.count, 19)
        XCTAssertEqual(Set(cards.map(\.id)).count, 19)
        XCTAssertEqual(cards.filter { $0.tier == .free }.count, 6)
        XCTAssertTrue(Set(cards.map(\.category)).isSubset(of: Set(SoundCategory.allCases)))
        XCTAssertTrue(cards.allSatisfy { $0.assetName.hasSuffix(".m4a") })
        XCTAssertNotNil(cards.first { $0.title == "I'm Mom" })
        XCTAssertNotNil(cards.first { $0.title == "You're Mom" })
        XCTAssertNotNil(cards.first { $0.title == "Come Here" })
    }

    func testDuplicateIDIsRejected() throws {
        var cards = sampleCards()
        cards[1] = SoundCard(
            id: cards[0].id,
            title: cards[1].title,
            category: cards[1].category,
            tier: cards[1].tier,
            safetyTag: cards[1].safetyTag,
            assetName: cards[1].assetName,
            sortOrder: cards[1].sortOrder,
            contentVersion: 1
        )

        XCTAssertThrowsError(try CatalogStore.decodeAndValidate(JSONEncoder().encode(cards))) { error in
            XCTAssertEqual(error as? CatalogError, .duplicateID(cards[0].id))
        }
    }

    func testWrongFreeCountIsRejected() throws {
        let cards = (0..<19).map { index in
            SoundCard(
                id: "sound_\(index)",
                title: "Sound \(index)",
                category: SoundCategory.allCases[index % SoundCategory.allCases.count],
                tier: .premium,
                safetyTag: .gentle,
                assetName: "sound_\(index).m4a",
                sortOrder: index,
                contentVersion: 1
            )
        }

        XCTAssertThrowsError(try CatalogStore.decodeAndValidate(JSONEncoder().encode(cards))) { error in
            XCTAssertEqual(error as? CatalogError, .invalidFreeCount(expected: 1, actual: 0))
        }
    }

    private func sampleCards() -> [SoundCard] {
        (0..<19).map { index in
            SoundCard(
                id: "sound_\(index)",
                title: "Sound \(index)",
                category: SoundCategory.allCases[index % SoundCategory.allCases.count],
                tier: index < 6 ? .free : .premium,
                safetyTag: .gentle,
                assetName: "sound_\(index).m4a",
                sortOrder: index,
                contentVersion: 1
            )
        }
    }
}


