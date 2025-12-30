import Foundation

struct QuizGenerator {
    func generateQuiz(for noteId: UUID, summary: SummaryResult) -> Quiz {
        let now = Date()
        let sentences = summary.keyPoints
        let keywords = summary.keywords

        let questions: [Question] = (0..<10).map { index in
            makeQuestion(
                index: index,
                sentences: sentences,
                keywords: keywords,
                fallbackSummary: summary.summary
            )
        }

        return Quiz(
            id: UUID(),
            noteId: noteId,
            questions: questions,
            createdAt: now
        )
    }

    private func makeQuestion(index: Int, sentences: [String], keywords: [String], fallbackSummary: String) -> Question {
        let promptBase = sentences.isEmpty ? fallbackSummary : sentences[index % max(1, sentences.count)]
        let prompt = "根據筆記，以下哪個選項最符合：「\(promptBase.prefix(80))」？"
        let correct = keywords.isEmpty ? "重點" : keywords[index % max(1, keywords.count)]

        var distractors = keywords.shuffled().filter { $0 != correct }.prefix(3)
        while distractors.count < 3 {
            distractors.append("相關但不正確的敘述 \(distractors.count + 1)")
        }

        let choices = ([correct] + distractors).shuffled()
        let answerIndex = choices.firstIndex(of: correct) ?? 0

        return Question(
            id: UUID(),
            prompt: prompt,
            choices: choices,
            answerIndex: answerIndex,
            explanation: "正確答案來自摘要或關鍵字：\(correct)"
        )
    }
}
