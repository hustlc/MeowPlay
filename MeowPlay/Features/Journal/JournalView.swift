import SwiftData
import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var entitlements: EntitlementStore
    @Query(sort: \PlaybackEntry.playedAt, order: .reverse) private var playbacks: [PlaybackEntry]
    @Query(sort: \ReactionEntry.createdAt, order: .reverse) private var reactions: [ReactionEntry]
    @State private var isShowingPaywall = false

    private var visiblePlaybacks: [PlaybackEntry] {
        entitlements.hasPremium ? playbacks : Array(playbacks.prefix(7))
    }

    var body: some View {
        NavigationStack {
            List {
                if entitlements.hasPremium && !reactions.isEmpty {
                    Section("Top responses") {
                        ForEach(topReactionCounts, id: \.reaction.id) { item in
                            Label {
                                HStack {
                                    Text(item.reaction.rawValue)
                                    Spacer()
                                    Text("\(item.count)")
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: item.reaction.systemImage)
                            }
                        }
                    }
                }

                Section("Recent plays") {
                    if visiblePlaybacks.isEmpty {
                        Text("Play a sound to begin your private, on-device journal.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visiblePlaybacks) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(catalog.card(withID: entry.soundID)?.title ?? "Removed sound")
                                Text(entry.playedAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !entitlements.hasPremium {
                    Section {
                        Button("Unlock full history and response insights") {
                            isShowingPaywall = true
                        }
                    } footer: {
                        Text("Free users can see their seven most recent plays. Your older entries remain on this device.")
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(isPresented: $isShowingPaywall) { PaywallView() }
        }
    }

    private var topReactionCounts: [(reaction: CatReaction, count: Int)] {
        let grouped = Dictionary(grouping: reactions.compactMap(\.reaction), by: { $0 })
        return grouped
            .map { (reaction: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }
}

