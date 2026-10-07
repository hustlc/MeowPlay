import Combine
import Foundation

enum CatalogError: LocalizedError, Equatable {
    case resourceMissing
    case decodingFailed(String)
    case invalidCount(expected: Int, actual: Int)
    case duplicateID(String)
    case duplicateAssetName(String)
    case duplicateSortOrder(Int)
    case invalidAssetName(String)
    case invalidCategoryCount(String, expected: Int, actual: Int)
    case invalidFreeCount(expected: Int, actual: Int)

    var errorDescription: String? {
        switch self {
        case .resourceMissing:
            "The sound catalog is missing from this build."
        case .decodingFailed(let detail):
            "The sound catalog could not be read: \(detail)"
        case .invalidCount(let expected, let actual):
            "Expected \(expected) sound cards but found \(actual)."
        case .duplicateID(let id):
            "The sound catalog contains a duplicate id: \(id)."
        case .duplicateAssetName(let name):
            "The sound catalog contains a duplicate audio asset: \(name)."
        case .duplicateSortOrder(let order):
            "The sound catalog contains a duplicate sort order: \(order)."
        case .invalidAssetName(let name):
            "The sound catalog contains an invalid .m4a asset name: \(name)."
        case .invalidCategoryCount(let category, let expected, let actual):
            "Expected \(expected) cards in \(category) but found \(actual)."
        case .invalidFreeCount(let expected, let actual):
            "Expected \(expected) free cards but found \(actual)."
        }
    }
}

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var cards: [SoundCard] = []
    @Published private(set) var errorMessage: String?

    init(bundle: Bundle = .main) {
        do {
            cards = try Self.load(from: bundle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func card(withID id: String) -> SoundCard? {
        cards.first { $0.id == id }
    }

    func cards(in category: SoundCategory) -> [SoundCard] {
        cards.filter { $0.category == category }.sorted { $0.sortOrder < $1.sortOrder }
    }

    nonisolated static func load(from bundle: Bundle) throws -> [SoundCard] {
        guard let url = bundle.url(forResource: "SoundCatalog", withExtension: "json") else {
            throw CatalogError.resourceMissing
        }
        do {
            return try decodeAndValidate(Data(contentsOf: url))
        } catch let error as CatalogError {
            throw error
        } catch {
            throw CatalogError.decodingFailed(error.localizedDescription)
        }
    }

    nonisolated static func decodeAndValidate(_ data: Data) throws -> [SoundCard] {
        let cards: [SoundCard]
        do {
            cards = try JSONDecoder().decode([SoundCard].self, from: data)
        } catch {
            throw CatalogError.decodingFailed(error.localizedDescription)
        }

        guard !cards.isEmpty else {
            throw CatalogError.invalidCount(expected: 1, actual: cards.count)
        }

        var ids = Set<String>()
        var assets = Set<String>()
        var sortOrders = Set<Int>()
        for card in cards {
            guard ids.insert(card.id).inserted else {
                throw CatalogError.duplicateID(card.id)
            }
            guard card.assetName.hasSuffix(".m4a"), !card.assetName.contains("/") else {
                throw CatalogError.invalidAssetName(card.assetName)
            }
            guard assets.insert(card.assetName).inserted else {
                throw CatalogError.duplicateAssetName(card.assetName)
            }
            guard sortOrders.insert(card.sortOrder).inserted else {
                throw CatalogError.duplicateSortOrder(card.sortOrder)
            }
        }

        let freeCount = cards.filter { $0.tier == .free }.count
        guard freeCount > 0 else {
            throw CatalogError.invalidFreeCount(expected: 1, actual: freeCount)
        }

        return cards.sorted { $0.sortOrder < $1.sortOrder }
    }
}
