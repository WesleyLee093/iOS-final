import Foundation
import Combine

@MainActor
final class QuizViewModel: ObservableObject {
    let quiz: Quiz
    @Published var selections: [UUID: Int] = [:]
    @Published var submitted = false
    @Published var score: Int = 0

    init(quiz: Quiz) {
        self.quiz = quiz
    }

    func select(question: Question, choice index: Int) {
        guard !submitted else { return }
        selections[question.id] = index
    }

    func submit() {
        submitted = true
        score = quiz.questions.reduce(into: 0) { result, question in
            if selections[question.id] == question.answerIndex { result += 1 }
        }
    }
}
