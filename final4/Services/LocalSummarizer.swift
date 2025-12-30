import Foundation

protocol LocalSummarizerProtocol {
    func summarize(text: String, maxSentences: Int) -> SummaryResult
}

/// Simple heuristic summarizer that scores sentences by word frequency (TF) and surfaces keywords.
struct HeuristicSummarizer: LocalSummarizerProtocol {
    private let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "is", "of", "in", "to", "for", "on", "with",
        "我", "的", "了", "在", "是", "有", "和", "或"
    ]

    func summarize(text: String, maxSentences: Int = 3) -> SummaryResult {
        let sentences = splitSentences(text)
        let tokens = tokenize(text)
        let frequency = tokens.reduce(into: [String: Int]()) { partial, word in
            partial[word, default: 0] += 1
        }

        let scored = sentences.map { sentence -> (String, Int) in
            let score = tokenize(sentence).reduce(0) { $0 + (frequency[$1] ?? 0) }
            return (sentence, score)
        }
        let topSentences = Array(scored.sorted { $0.1 > $1.1 }.map(\.0).prefix(maxSentences))
        let summary = topSentences.joined(separator: " ")

        let keyPoints = Array(sentences.prefix(max(1, min(5, sentences.count))))
        let keywords = frequency
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
            .filter { !$0.key.isEmpty }
            .prefix(8)
            .map(\.key)

        return SummaryResult(
            summary: summary.isEmpty ? String(sentences.prefix(2).joined(separator: " ")) : summary,
            keyPoints: keyPoints,
            keywords: keywords
        )
    }

    private func splitSentences(_ text: String) -> [String] {
        let delimiters = CharacterSet(charactersIn: ".。！？!?")
        return text
            .components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func tokenize(_ text: String) -> [String] {
        return text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.count > 1 }
    }
}
