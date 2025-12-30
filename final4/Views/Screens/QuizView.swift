import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuizViewModel
    @State private var showDeleteAlert = false

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
                        if viewModel.submitted {
                            VStack(alignment: .leading, spacing: 4) {
                                let selectedIndex = viewModel.selections[question.id]
                                let selectedText = selectedIndex.flatMap { idx in
                                    question.choices.indices.contains(idx) ? question.choices[idx] : nil
                                } ?? "未選擇"
                                let correctText = question.choices[question.answerIndex]
                                let isCorrect = selectedIndex == question.answerIndex

                                Text(isCorrect ? "答對" : "答錯")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(isCorrect ? .green : .red)
                                Text("你的答案：\(selectedText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("正確答案：\(correctText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let explanation = question.explanation {
                                    Text("解析：\(explanation)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("刪除題庫？", isPresented: $showDeleteAlert) {
            Button("刪除", role: .destructive) {
                Task {
                    await appModel.deleteQuiz(for: viewModel.quiz.noteId)
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只會刪除此題庫，不會影響筆記內容。")
        }
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
