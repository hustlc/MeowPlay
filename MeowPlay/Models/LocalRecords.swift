import Foundation
import SwiftData

enum CatReaction: String, CaseIterable, Identifiable {
    case cameCloser = "Came closer"
    case meowed = "Meowed"
    case looked = "Looked"
    case ignored = "Ignored"
    case movedAway = "Moved away"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .cameCloser: "arrow.down.left.and.arrow.up.right"
        case .meowed: "waveform"
        case .looked: "eye"
        case .ignored: "minus.circle"
        case .movedAway: "arrow.right"
        }
    }
}

@Model
final class FavoriteEntry {
    @Attribute(.unique) var soundID: String
    var createdAt: Date

    init(soundID: String, createdAt: Date = .now) {
        self.soundID = soundID
        self.createdAt = createdAt
    }
}

@Model
final class PlaybackEntry {
    var id: UUID
    var soundID: String
    var playedAt: Date

    init(soundID: String, playedAt: Date = .now) {
        self.id = UUID()
        self.soundID = soundID
        self.playedAt = playedAt
    }
}

@Model
final class ReactionEntry {
    var id: UUID
    var soundID: String
    var reactionRawValue: String
    var createdAt: Date

    var reaction: CatReaction? { CatReaction(rawValue: reactionRawValue) }

    init(soundID: String, reaction: CatReaction, createdAt: Date = .now) {
        self.id = UUID()
        self.soundID = soundID
        self.reactionRawValue = reaction.rawValue
        self.createdAt = createdAt
    }
}

@Model
final class SoundPlaylist {
    @Attribute(.unique) var id: UUID
    var name: String
    var soundIDsData: Data
    var createdAt: Date
    var updatedAt: Date

    var soundIDs: [String] {
        get { (try? JSONDecoder().decode([String].self, from: soundIDsData)) ?? [] }
        set {
            soundIDsData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8)
            updatedAt = .now
        }
    }

    init(name: String, soundIDs: [String] = [], createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.soundIDsData = (try? JSONEncoder().encode(soundIDs)) ?? Data("[]".utf8)
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    func toggle(soundID: String) {
        var next = soundIDs
        if let index = next.firstIndex(of: soundID) {
            next.remove(at: index)
        } else {
            next.append(soundID)
        }
        soundIDs = next
    }
}
