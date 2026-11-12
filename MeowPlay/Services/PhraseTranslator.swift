import Foundation

struct PhraseTranslation {
    let phrase: String
    let card: SoundCard
    let mood: String
}

struct PhraseTranslator {
    /// Maps a short human phrase to a playful, clearly non-literal sound choice.
    ///
    /// - Parameter prefersFreeCards: pass `true` for free users. Intent matching
    ///   then runs against the free library first, so the suggested result is
    ///   normally playable. If the free library has no card for that intent,
    ///   the full library is used and the UI presents the locked Premium result.
    func translate(
        _ phrase: String,
        cards: [SoundCard],
        prefersFreeCards: Bool = false
    ) -> PhraseTranslation? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !cards.isEmpty else { return nil }

        let normalized = trimmed.lowercased()
        var pools: [[SoundCard]] = [cards]
        if prefersFreeCards {
            let freeCards = cards.filter { !$0.isPremium }
            if !freeCards.isEmpty {
                pools.insert(freeCards, at: 0)
            }
        }

        for pool in pools {
            if let match = matchedIntent(for: normalized, in: pool) {
                return PhraseTranslation(phrase: trimmed, card: match.card, mood: match.mood)
            }
        }

        guard let fallback = gentleFallback(in: cards) else { return nil }
        return PhraseTranslation(phrase: trimmed, card: fallback, mood: "a gentle cat-sound guess")
    }

    private func matchedIntent(
        for normalized: String,
        in cards: [SoundCard]
    ) -> (card: SoundCard, mood: String)? {
        let rules: [(words: [String], category: SoundCategory, mood: String)] = [
            (["come", "here", "follow", "join", "过来", "跟我", "来这里"], .comeHere, "a friendly invitation"),
            (["play", "fun", "toy", "玩", "游戏", "玩耍"], .playTime, "a playful hello"),
            (["food", "eat", "dinner", "snack", "饭", "吃", "饿", "零食"], .foodTime, "a hopeful food-time sound"),
            (["love", "cute", "hug", "cuddle", "爱", "可爱", "抱", "摸"], .affection, "a soft affectionate sound"),
            (["look", "listen", "hear", "attention", "看", "听", "注意"], .attention, "a gentle attention call"),
            (["what", "who", "curious", "什么", "谁", "好奇"], .curiousAndSocial, "a curious social sound")
        ]

        guard let matchedRule = rules.first(where: { rule in
            rule.words.contains { normalized.contains($0) }
        }) else { return nil }

        // Returning nil here lets the caller try the wider library instead of
        // substituting an unrelated sound for a matched intent.
        guard let card = cards
            .filter({ $0.category == matchedRule.category })
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .first else { return nil }

        return (card, matchedRule.mood)
    }

    private func gentleFallback(in cards: [SoundCard]) -> SoundCard? {
        let safeCards = cards.filter { $0.safetyTag == .gentle || $0.safetyTag == .neutral }
        let pool = safeCards.isEmpty ? cards : safeCards
        return pool.sorted { $0.sortOrder < $1.sortOrder }.first
    }
}
