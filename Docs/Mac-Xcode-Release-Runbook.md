# Mac/Xcode Release Runbook

This project is ready for Mac-side build, StoreKit testing, and App Store Connect setup. The Windows-side release asset check currently passes.

## Current Release Shape

- Catalog: 19 playable sounds.
- Free sounds: 6.
- Premium sounds: 13.
- Legal site: https://meowplay-official.pages.dev/
- Privacy: https://meowplay-official.pages.dev/privacy.html
- Terms: https://meowplay-official.pages.dev/terms.html
- Support: https://meowplay-official.pages.dev/support.html
- Publisher: vista intelligence.
- Support email: licong28@hotmail.com.

## Mac Prerequisites

- macOS with Xcode 15.3 or newer.
- XcodeGen 2.45.4 or newer.
- Apple Developer Program membership.
- An App Store Connect app record for MeowPlay.
- A unique bundle identifier. The placeholder is `com.meowplay.app`; change it if unavailable.
- Apple development team ID in `project.yml`.

## Windows + Xcode Cloud Path

A Mac is not required for the initial build if the project is connected to
Xcode Cloud. Push this repository to GitHub, create an Xcode Cloud workflow for
the `MeowPlay` scheme, and let `ci_scripts/ci_post_clone.sh` install XcodeGen
when needed and generate the Xcode project from `project.yml`. Use the iPhone
with TestFlight for the final real-device checks.

The repository must be a complete URL such as
`https://github.com/<account-or-organization>/<repository>.git`; a GitHub
username alone is not enough. Never place a GitHub password, personal access
token, signing certificate, or provisioning profile in the repository.

Install XcodeGen if needed:

```zsh
brew install xcodegen
```

## Generate and Build

From the project root on the Mac:

```zsh
xcodegen generate
open MeowPlay.xcodeproj
```

Recommended command-line checks:

```zsh
xcodebuild -project MeowPlay.xcodeproj -scheme MeowPlay -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project MeowPlay.xcodeproj -scheme MeowPlay -destination 'platform=iOS Simulator,name=iPhone 16' test
```

If the named simulator is unavailable, list installed devices:

```zsh
xcrun simctl list devices available
```

## StoreKit Local Test

`project.yml` attaches `MeowPlay/StoreKit/MeowPlay.storekit` to the scheme. In Xcode:

1. Select the MeowPlay scheme.
2. Confirm StoreKit Configuration is `MeowPlay.storekit`.
3. Run on an iOS 17+ simulator.
4. Open a locked Premium card or Settings > See Premium options.
5. Verify monthly and annual products load.
6. Test annual 7-day trial eligibility.
7. Test purchase, cancellation, expiration, billing retry, refund/revocation, pending approval, and Restore Purchases in StoreKit Transaction Manager.

## App Store Connect Products

Create one auto-renewable subscription group:

- Group name: `MeowPlay Premium`
- Monthly product ID: `com.meowplay.premium.monthly`
- Annual product ID: `com.meowplay.premium.annual`
- Annual introductory offer: 7-day free trial

Use the same product identifiers as `AppConfiguration.swift` and `MeowPlay.storekit`.

Apple requires the first in-app purchase or auto-renewable subscription of its type to be submitted with a new app version. Attach both subscriptions to the first app submission after their App Store Connect metadata is complete.

## App Store Connect Metadata

Use `Docs/App-Store-Metadata.md` as the draft source for:

- Name
- Subtitle
- Promotional text
- Description
- Keywords
- Review notes
- Screenshot sequence

In App Review notes, state clearly that MeowPlay is a playful soundboard, not an animal-language translator.

## App Privacy

Current intended answers:

- No account.
- No tracking.
- No developer-collected data.
- No microphone, camera, contacts, location, or advertising identifier permission.
- Purchase processing is handled by Apple StoreKit.

Before submission, verify this with Xcode's privacy report and the final dependency set.

## TestFlight Checklist

- Fresh install and first-run onboarding.
- Free playback without purchase.
- Locked Premium card opens paywall.
- Monthly purchase.
- Annual purchase with trial.
- Restore Purchases.
- Manage Subscription link.
- Offline launch after previous entitlement snapshot.
- Airplane mode free playback.
- Silent mode, headphones, Bluetooth route changes, phone-call interruption.
- VoiceOver and Dynamic Type.
- Dark mode.
- Legal links open the deployed Cloudflare Pages site.

## Current Known Blockers

- This Windows environment cannot run Xcode build or iOS simulator tests.
- `project.yml` still has an empty `DEVELOPMENT_TEAM`.
- Bundle ID `com.meowplay.app` must be reserved or replaced in App Store Connect.
- App Store screenshots still need to be captured from a real Xcode build.
- First subscriptions must be attached to the app version submission in App Store Connect.
