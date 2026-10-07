import SwiftData
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var entitlements: EntitlementStore
    @Query(sort: \FavoriteEntry.createdAt, order: .reverse) private var favorites: [FavoriteEntry]
    @State private var selectedCard: SoundCard?
    @State private var isShowingPaywall = false
    @State private var section = SavedSection.favorites

    private enum SavedSection: String, CaseIterable, Identifiable {
        case favorites = "Favorites"
        case playlists = "Playlists"
        var id: String { rawValue }
    }

    private var cards: [SoundCard] {
        favorites.compactMap { catalog.card(withID: $0.soundID) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Saved section", selection: $section) {
                    ForEach(SavedSection.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if section == .playlists {
                    PlaylistsView(onPremiumRequired: { isShowingPaywall = true })
                } else {
                    Group {
                        if cards.isEmpty {
                            ContentUnavailableView(
                                "No favorites yet",
                                systemImage: "heart",
                                description: Text("Save the sounds your cat responds to most.")
                            )
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                                    ForEach(cards) { card in
                                        SoundCardTile(card: card, isLocked: card.isPremium && !entitlements.hasPremium) {
                                            if card.isPremium && !entitlements.hasPremium {
                                                isShowingPaywall = true
                                            } else {
                                                selectedCard = card
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .sheet(item: $selectedCard) { card in
                SoundDetailView(card: card)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingPaywall) { PaywallView() }
        }
    }
}
