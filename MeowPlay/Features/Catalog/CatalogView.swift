import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var entitlements: EntitlementStore
    @AppStorage("successfulPlayCount") private var successfulPlayCount = 0
    @State private var searchText = ""
    @State private var selectedCategory: SoundCategory?
    @State private var selectedCard: SoundCard?
    @State private var isShowingPaywall = false

    private var filteredCards: [SoundCard] {
        catalog.cards.filter { card in
            let categoryMatches = selectedCategory == nil || card.category == selectedCategory
            let searchMatches = searchText.isEmpty || card.title.localizedCaseInsensitiveContains(searchText)
            return categoryMatches && searchMatches
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage = catalog.errorMessage {
                    ContentUnavailableView(
                        "Sounds unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            safetyBanner
                            categoryPicker
                            if successfulPlayCount >= 3 && !entitlements.hasPremium {
                                premiumBanner
                            }
                            soundGrid
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Cat Sounds")
            .searchable(text: $searchText, prompt: "Search playful intents")
            .sheet(item: $selectedCard) { card in
                SoundDetailView(card: card)
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    private var safetyBanner: some View {
        Label("Start at low volume. Stop if your cat moves away or seems uncomfortable.", systemImage: "speaker.wave.1.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(title: "All", systemImage: "square.grid.2x2.fill", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(SoundCategory.allCases) { category in
                    CategoryChip(title: category.rawValue, systemImage: category.systemImage, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var soundGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ForEach(filteredCards) { card in
                SoundCardTile(card: card, isLocked: card.isPremium && !entitlements.hasPremium) {
                    if card.isPremium && !entitlements.hasPremium {
                        isShowingPaywall = true
                    } else {
                        selectedCard = card
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var premiumBanner: some View {
        Button {
            isShowingPaywall = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Explore Premium sounds")
                        .font(.headline)
                    Text("Premium sounds, unlimited favorites, and reaction history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

private struct CategoryChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.purple : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SoundCardTile: View {
    let card: SoundCard
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: card.category.systemImage)
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Premium")
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .accessibilityHidden(true)
                    }
                }
                Text(card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(card.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(minHeight: 128)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.purple.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.title), \(isLocked ? "Premium" : "play sound")")
    }
}

