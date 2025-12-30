import SwiftUI

struct QuizListView: View {
    @EnvironmentObject var appModel: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(appModel.notes) { note in
                    if let quiz = appModel.quiz(for: note.id) {
                        NavigationLink {
                            QuizView(quiz: quiz)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(note.title).font(.headline)
                                Text("共有 \(quiz.questions.count) 題")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("題庫")
        }
    }
}
