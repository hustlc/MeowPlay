import SwiftData
import SwiftUI

struct SoundDetailView: View {
    let card: SoundCard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var entitlements: EntitlementStore
    @Query private var favorites: [FavoriteEntry]
    @AppStorage("didAcknowledgeSoundSafety") private var didAcknowledgeSafety = false
    @AppStorage("successfulPlayCount") private var successfulPlayCount = 0
    @State private var isShowingSafetyAlert = false
    @State private var isShowingPlaylistPicker = false
    @State private var isShowingPaywall = false
    @State private var canRecordReaction = false
    @State private var localError: String?

    private var isFavorite: Bool {
        favorites.contains { $0.soundID == card.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: card.category.systemImage)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.purple)
                        .frame(width: 110, height: 110)
                        .background(.purple.opacity(0.12), in: Circle())
                        .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text(card.title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("A playful \(card.category.rawValue.lowercased()) intent")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        requestPlay()
                    } label: {
                        Label(playButtonTitle, systemImage: audioPlayer.playingSoundID == card.id ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(audioPlayer.cooldownSoundID == card.id && audioPlayer.playingSoundID != card.id)
                    .accessibilityHint("Plays once and never loops")

                    Button {
                        toggleFavorite()
                    } label: {
                        Label(isFavorite ? "Remove Favorite" : "Add to Favorites", systemImage: isFavorite ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        if entitlements.hasPremium {
                            isShowingPlaylistPicker = true
                        } else {
                            isShowingPaywall = true
                        }
                    } label: {
                        Label("Add to Playlist", systemImage: "text.badge.plus")
                    }
                    .buttonStyle(.bordered)

                    if canRecordReaction {
                        reactionPicker
                    }

                    Text(AppConfiguration.disclaimer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .navigationTitle("Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Start at low volume", isPresented: $isShowingSafetyAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Play Once") {
                    didAcknowledgeSafety = true
                    performPlay()
                }
            } message: {
                Text("Your cat may react differently. Stop playback if they move away, flatten their ears, or seem uncomfortable.")
            }
            .alert("Couldn’t complete that action", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localError ?? "Please try again.")
            }
            .sheet(isPresented: $isShowingPlaylistPicker) {
                PlaylistPickerView(soundID: card.id)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    private var playButtonTitle: String {
        if audioPlayer.playingSoundID == card.id { return "Stop" }
        if audioPlayer.cooldownSoundID == card.id { return "Wait a moment" }
        return "Play Once"
    }

    private var reactionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did your cat respond?")
                .font(.headline)
            ForEach(CatReaction.allCases) { reaction in
                Button {
                    record(reaction)
                } label: {
                    Label(reaction.rawValue, systemImage: reaction.systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )
    }

    private func requestPlay() {
        if audioPlayer.playingSoundID == card.id {
            audioPlayer.stop()
            return
        }
        if didAcknowledgeSafety {
            performPlay()
        } else {
            isShowingSafetyAlert = true
        }
    }

    private func performPlay() {
        guard audioPlayer.play(card) else {
            localError = audioPlayer.errorMessage ?? "The audio could not be played."
            return
        }
        modelContext.insert(PlaybackEntry(soundID: card.id))
        saveContext()
        successfulPlayCount += 1
        canRecordReaction = true
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.soundID == card.id }) {
            modelContext.delete(existing)
            saveContext()
            return
        }
        if !entitlements.hasPremium && favorites.count >= 3 {
            isShowingPaywall = true
            return
        }
        modelContext.insert(FavoriteEntry(soundID: card.id))
        saveContext()
    }

    private func record(_ reaction: CatReaction) {
        modelContext.insert(ReactionEntry(soundID: card.id, reaction: reaction))
        saveContext()
        canRecordReaction = false
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            localError = "Your local journal could not be saved."
        }
    }
}
