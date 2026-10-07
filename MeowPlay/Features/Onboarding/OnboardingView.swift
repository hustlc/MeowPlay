import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                OnboardingPage(
                    icon: "cat.fill",
                    title: "Play. Watch. Connect.",
                    message: "Explore gentle cat sounds and see how your cat chooses to respond."
                )
                .tag(0)

                OnboardingPage(
                    icon: "speaker.wave.2.fill",
                    title: "Start Quietly",
                    message: "Lower your media volume before every session. Stop if your cat seems uncomfortable."
                )
                .tag(1)

                OnboardingPage(
                    icon: "hand.raised.fill",
                    title: "Playful, Not Literal",
                    message: "Turn a phrase into a playful cat-sound choice. It is entertainment, not a real animal-language translation."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == 2 ? "Start Playing" : "Continue") {
                if page == 2 {
                    onComplete()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .accessibilityHint(page == 2 ? "Opens the sound library" : "Shows the next introduction page")
        }
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.18), Color.orange.opacity(0.10), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.purple)
                .accessibilityHidden(true)
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
        }
    }
}
