import SwiftData
import SwiftUI

struct PhraseTranslatorView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @EnvironmentObject private var entitlements: EntitlementStore
    @AppStorage("didAcknowledgeSoundSafety") private var didAcknowledgeSafety = false
    @AppStorage("successfulPlayCount") private var successfulPlayCount = 0
    @State private var phrase = ""
    @State private var translation: PhraseTranslation?
    @State private var localError: String?
    @State private var isShowingSafetyAlert = false
    @State private var isShowingPaywall = false

    private let translator = PhraseTranslator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    input
                    result
                    safetyNote
                }
                .padding()
            }
            .navigationTitle("Cat Translator")
            .alert("Start at low volume", isPresented: $isShowingSafetyAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Play Once") {
                    didAcknowledgeSafety = true
                    requestPlay()
                }
            } message: {
                Text("This is a playful sound choice, not a real translation. Stop playback if your cat seems uncomfortable.")
            }
            .alert("Couldn’t play that sound", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localError ?? "Please try again.")
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Just for fun", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.purple)
            Text("Turn human words into a cat-sound moment.")
                .font(.largeTitle.bold())
            Text("Type a phrase and MeowPlay will choose a playful sound based on its mood.")
                .foregroundStyle(.secondary)
        }
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What do you want to say?")
                .font(.headline)
            TextField("For example: Come here, little friend", text: $phrase, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.go)
                .onSubmit { translate() }
            Button {
                translate()
            } label: {
                Label("Make It Meow", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || catalog.cards.isEmpty)
        }
    }

    @ViewBuilder
    private var result: some View {
        if let translation {
            VStack(alignment: .leading, spacing: 14) {
                Text("Playful interpretation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
                    .textCase(.uppercase)
                Text("“\(translation.phrase)”")
                    .font(.headline)
                Text("becomes \(translation.mood):")
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(translation.card.title)
                            .font(.title3.bold())
                        Text(translation.card.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        requestPlay()
                    } label: {
                        Image(systemName: playButtonImage(for: translation.card))
                            .font(.title2)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(audioPlayer.cooldownSoundID == translation.card.id && audioPlayer.playingSoundID != translation.card.id)
                    .accessibilityLabel(playButtonLabel(for: translation.card))
                    .accessibilityHint("Plays once and never loops")
                }
                if translation.card.isPremium && !entitlements.hasPremium {
                    Label("Premium sound. Unlock MeowPlay Premium to play this result.", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.purple.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        } else {
            ContentUnavailableView(
                "Your result will appear here",
                systemImage: "waveform",
                description: Text("Try “过来陪我玩” or “I love you, cat.”")
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var safetyNote: some View {
        Label("Entertainment only. Cats may respond differently. Start quietly and stop if your cat seems uncomfortable.", systemImage: "speaker.wave.1.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )
    }

    private func translate() {
        translation = translator.translate(
            phrase,
            cards: catalog.cards,
            prefersFreeCards: !entitlements.hasPremium
        )
    }

    private func requestPlay() {
        guard let translation else { return }
        if audioPlayer.playingSoundID == translation.card.id {
            audioPlayer.stop()
        } else if audioPlayer.cooldownSoundID == translation.card.id {
            return
        } else if translation.card.isPremium && !entitlements.hasPremium {
            isShowingPaywall = true
        } else if didAcknowledgeSafety {
            playTranslation()
        } else {
            isShowingSafetyAlert = true
        }
    }

    private func playButtonImage(for card: SoundCard) -> String {
        if audioPlayer.playingSoundID == card.id {
            return "stop.fill"
        }
        return card.isPremium && !entitlements.hasPremium ? "lock.fill" : "play.fill"
    }

    private func playButtonLabel(for card: SoundCard) -> String {
        if audioPlayer.playingSoundID == card.id {
            return "Stop sound"
        }
        return card.isPremium && !entitlements.hasPremium
            ? "Unlock Premium to play sound"
            : "Play cat sound"
    }

    private func playTranslation() {
        guard let translation, audioPlayer.play(translation.card) else {
            localError = audioPlayer.errorMessage ?? "The audio could not be played."
            return
        }
        modelContext.insert(PlaybackEntry(soundID: translation.card.id))
        do {
            try modelContext.save()
        } catch {
            localError = "Your local journal could not be saved."
        }
        successfulPlayCount += 1
    }
}
