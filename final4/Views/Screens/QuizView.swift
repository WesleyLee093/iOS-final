import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel: QuizViewModel

    init(quiz: Quiz) {
        _viewModel = StateObject(wrappedValue: QuizViewModel(quiz: quiz))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.quiz.questions) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.prompt)
                            .font(.headline)
                        ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                            Button {
                                viewModel.select(question: question, choice: index)
                            } label: {
                                HStack {
                                    Image(systemName: selectionState(for: question, index: index))
                                    Text(choice)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(backgroundColor(question: question, index: index))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        if viewModel.submitted, let explanation = question.explanation {
                            Text("解析：\(explanation)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: viewModel.submit) {
                    Label("提交答案", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if viewModel.submitted {
                    Text("得分：\(viewModel.score)/\(viewModel.quiz.questions.count)")
                        .font(.title2.bold())
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("測驗")
    }

    private func selectionState(for question: Question, index: Int) -> String {
        if let selected = viewModel.selections[question.id], selected == index {
            return "largecircle.fill.circle"
        } else {
            return "circle"
        }
    }

    private func backgroundColor(question: Question, index: Int) -> Color {
        guard viewModel.submitted else {
            return Color(.systemBackground)
        }
        if index == question.answerIndex {
            return Color.green.opacity(0.2)
        }
        if viewModel.selections[question.id] == index {
            return Color.red.opacity(0.2)
        }
        return Color(.systemBackground)
    }
}
