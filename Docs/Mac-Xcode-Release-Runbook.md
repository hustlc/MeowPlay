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

## No-Mac Path (Windows + GitHub Actions)

A local Mac is not required for either verification or release builds.
GitHub-hosted macOS runners provide Xcode, and everything is configured from
the browser.

1. `hustlc/MeowPlay` is already a public GitHub repository, so standard hosted
   runner minutes are free. Commit the working-tree changes and push to `main`.
2. `.github/workflows/ios-build.yml` then runs automatically: it installs
   XcodeGen, generates `MeowPlay.xcodeproj`, and builds plus runs all unit tests
   on an iOS Simulator with `CODE_SIGNING_ALLOWED=NO`. This is the first real
   Swift compile. Read the Actions log before going further.
3. For a TestFlight build, add a release workflow that archives with signing and
   uploads using an App Store Connect API key (`-allowProvisioningUpdates`), or
   a Distribution certificate plus provisioning profile stored as GitHub
   Secrets. Never commit certificates, private keys, or API keys.
4. Fill in `DEVELOPMENT_TEAM` in `project.yml` and reserve the bundle ID before
   attempting a signed archive.
5. Install TestFlight on the iPhone and work through the checklist below.

Apple Developer Program membership is still required for signing, TestFlight,
and App Store distribution. In mainland China an individual can enrol for
¥688/year from the Apple Developer app on the iPhone; no Mac is needed.

If you do not want to enrol yet, use the free route instead: `ios-build.yml`
now also produces an unsigned Release IPA and uploads it as the
`MeowPlay-unsigned-ipa` artifact. Download it from a successful Actions run and
use Sideloadly on Windows with a free Apple ID to sideload it onto your own
iPhone. Free-ID signing expires after 7 days, allows at most 3 apps, and
cannot use StoreKit purchases or push notifications. This is for personal
verification only; it does not publish to the App Store or TestFlight, and the
web soundboard plus Ko-fi remains the public release channel.

`ci_scripts/ci_post_clone.sh` is kept for a future Xcode Cloud setup, but Apple
requires the first Xcode Cloud workflow to be configured in Xcode on a Mac. It
is not the primary path on a Windows-only setup. If a Mac is borrowed or rented
briefly, Xcode Cloud (25 free compute hours/month) becomes an alternative.

Install XcodeGen if needed on the runner or on a Mac:

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
- Cat Translator returns a playable free sound for a free user.
- Cat Translator result locked to Premium shows a lock and opens the paywall.
- Cat Translator playback appears in the Journal and counts toward the Premium banner.
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

- Xcode cannot run locally on Windows. Real compilation and unit-test results now come from `.github/workflows/ios-build.yml` on a GitHub-hosted macOS runner; check the Actions tab before release.
- `project.yml` still has an empty `DEVELOPMENT_TEAM`.
- Bundle ID `com.meowplay.app` must be reserved or replaced in App Store Connect.
- App Store screenshots still need to be captured from a real Xcode build.
- First subscriptions must be attached to the app version submission in App Store Connect.
