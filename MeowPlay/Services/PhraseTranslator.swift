import Foundation

struct PhraseTranslation {
    let phrase: String
    let card: SoundCard
    let mood: String
}

struct PhraseTranslator {
    func translate(_ phrase: String, cards: [SoundCard]) -> PhraseTranslation? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !cards.isEmpty else { return nil }

        let normalized = trimmed.lowercased()
        let rules: [(words: [String], category: SoundCategory, mood: String)] = [
            (["come", "here", "follow", "join", "过来", "跟我", "来这里"], .comeHere, "a friendly invitation"),
            (["play", "fun", "toy", "玩", "游戏", "玩耍"], .playTime, "a playful hello"),
            (["food", "eat", "dinner", "snack", "饭", "吃", "饿", "零食"], .foodTime, "a hopeful food-time sound"),
            (["love", "cute", "hug", "cuddle", "爱", "可爱", "抱", "摸"], .affection, "a soft affectionate sound"),
            (["look", "listen", "hear", "attention", "看", "听", "注意"], .attention, "a gentle attention call"),
            (["what", "who", "curious", "什么", "谁", "好奇"], .curiousAndSocial, "a curious social sound")
        ]

        let matchedRule = rules.first { rule in
            rule.words.contains { normalized.contains($0) }
        }
        let candidates: [SoundCard]
        let mood: String
        if let matchedRule {
            candidates = cards.filter { $0.category == matchedRule.category }
            mood = matchedRule.mood
        } else {
            candidates = cards.filter { $0.safetyTag == .gentle || $0.safetyTag == .neutral }
            mood = "a gentle cat-sound guess"
        }

        guard let card = candidates.sorted(by: { $0.sortOrder < $1.sortOrder }).first ?? cards.first else {
            return nil
        }
        return PhraseTranslation(phrase: trimmed, card: card, mood: mood)
    }
}
