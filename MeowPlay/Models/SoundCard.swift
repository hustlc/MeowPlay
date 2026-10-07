import Foundation

enum SoundCategory: String, Codable, CaseIterable, Identifiable {
    case greeting = "Greeting"
    case affection = "Affection"
    case attention = "Attention"
    case comeHere = "Come Here"
    case foodTime = "Food Time"
    case playTime = "Play Time"
    case calmAndCozy = "Calm & Cozy"
    case curiousAndSocial = "Curious & Social"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .greeting: "hand.wave.fill"
        case .affection: "heart.fill"
        case .attention: "sparkles"
        case .comeHere: "figure.walk.motion"
        case .foodTime: "fork.knife"
        case .playTime: "balloon.2.fill"
        case .calmAndCozy: "moon.stars.fill"
        case .curiousAndSocial: "eyes"
        }
    }
}

enum AccessTier: String, Codable {
    case free
    case premium
}

enum SoundSafetyTag: String, Codable {
    case gentle
    case neutral
}

struct SoundCard: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let category: SoundCategory
    let tier: AccessTier
    let safetyTag: SoundSafetyTag
    let assetName: String
    let sortOrder: Int
    let contentVersion: Int

    var isPremium: Bool { tier == .premium }
}

