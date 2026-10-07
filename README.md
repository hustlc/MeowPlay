# MeowPlay

An iOS 17 SwiftUI app for playful, clearly non-literal cat-sound interactions. The iPhone app is the primary product; the Cloudflare Pages site is a lightweight preview and discovery channel. The app is offline-first, has no account system, requests no sensitive permissions, and uses StoreKit 2 for Premium access.

## Requirements

- macOS with Xcode 15.3 or newer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- An Apple Developer account for device and subscription testing
- A GitHub or other supported Git repository for Xcode Cloud

## Open the project

1. Install XcodeGen on the Mac: `brew install xcodegen`.
2. Run `xcodegen generate` in this directory.
3. Open `MeowPlay.xcodeproj`.
4. Select the `MeowPlay` scheme and an iOS 17+ simulator.

## Xcode Cloud

The repository includes `ci_scripts/ci_post_clone.sh`. Xcode Cloud runs it after
cloning the repository so `project.yml` can generate `MeowPlay.xcodeproj` before
the build starts. In Xcode Cloud, select the `MeowPlay` scheme and use the
generated project for build and test workflows.

The `.xcodeproj` is generated and intentionally ignored. `project.yml` is the source of truth.

## Audio handoff

You do not need to prepare 40 finished files or rename anything. Put approximately 12–16 natural source recordings in `IncomingAudio/`, or attach them to the Codex conversation. WAV, M4A, and MP3 are accepted. Codex will review, normalize, map, and export approved production `.m4a` files into `MeowPlay/Resources/Audio/`. The launch catalog can ship with a smaller, curated set of sounds.

Until approved production files exist, cards show a clear “Audio coming soon” error instead of playing a fake cat sound. See `Docs/音频准备说明.md` for the exact recording checklist.

Before release, run:

```powershell
./Scripts/Validate-ReleaseAssets.ps1
```

For staged web-audio capture on Windows, see [`Docs/录音工作流.md`](Docs/录音工作流.md) and [`Scripts/Capture-WebAudio.ps1`](Scripts/Capture-WebAudio.ps1). Raw captures stay under `codex-cat-audio-stage/CapturedWebAudio/` until source rights and cat-safety review are complete.

`Docs/Audio-Rights-Register.csv` tracks the catalog outputs and their source status. The current launch catalog contains 19 playable sounds, including six free sounds; the remaining template rows are reserved for future sound packs and are not part of this release.

## StoreKit setup

Create one auto-renewable subscription group in App Store Connect with these product identifiers:

- `com.meowplay.premium.monthly` — US$4.99/month, no trial
- `com.meowplay.premium.annual` — US$29.99/year, 7-day introductory trial

The in-app price is always read from StoreKit; it is never hard-coded. Complete the subscription localization, review screenshot, Privacy Policy URL, Terms URL, and review notes before submission.

## Cat Translator

The native app includes a local `Cat Translator` tab. It maps common words and
phrases to a playful sound-card choice without claiming to translate animal
language. Input stays on the device; no speech, microphone, network, or AI
service is required.

## Release blockers

- The current launch audio rights and safety approvals are complete. Re-run the validation script after changing audio or catalog files.
- Support and legal URLs already point to the live MeowPlay Pages site; verify the deployment again before submission if the site changes.
- Set the bundle identifier and Apple development team.
- Generate the Xcode project, run unit/UI checks on macOS, and complete StoreKit sandbox plus TestFlight testing.

