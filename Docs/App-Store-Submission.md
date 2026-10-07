# App Store submission checklist

## Positioning

- Name and subtitle describe a cat soundboard or playful interaction app, not a literal translator.
- Cat Translator is described as a playful phrase-to-sound suggestion feature, never as accurate animal-language translation.
- Description and screenshots show real screens and state that results vary by cat.
- Do not use “your cat understands,” “scientifically proven,” “guaranteed,” diagnostic, treatment, or training-effect claims.
- Review notes explain that all cards are playful human intent labels attached to licensed sounds, not translations.

## Subscription disclosure

- Monthly: `com.meowplay.premium.monthly`.
- Annual: `com.meowplay.premium.annual`, with a 7-day trial configured in App Store Connect.
- Confirm localized prices and eligibility are returned by StoreKit in a production-signed TestFlight build.
- Paywall visibly includes trial duration, post-trial localized price and period, auto-renewal, cancelation path, Restore Purchases, Privacy, and Terms.
- Upload an App Review screenshot and add precise review instructions for reaching the paywall and restoring purchases.

## Privacy and safety

- App Privacy answers: no developer-collected data, subject to final code and SDK audit.
- No `NSMicrophoneUsageDescription`, camera, location, contacts, tracking prompt, IDFA, or background audio mode.
- Host the final Privacy Policy, Terms, and Support pages on publisher-controlled HTTPS URLs.
- Verify `PrivacyInfo.xcprivacy` against Xcode's privacy report before archiving.
- Confirm every production sound has completed rights and safety records.

## Product quality

- Supply a final 1024×1024 App Icon and complete screenshots for every required iPhone size.
- Test VoiceOver, Dynamic Type, dark mode, silent mode, headphones, Bluetooth route changes, phone-call interruptions, airplane mode, and fresh installs.
- Exercise monthly and annual purchase, new-customer annual trial, ineligible annual purchase, pending approval, cancelation, expiration, grace period, billing retry, refund/revocation, and Restore Purchases.
- Ensure free playback works without purchase or connectivity and that the paywall is not forced at launch.
