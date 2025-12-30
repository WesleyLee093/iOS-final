import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let note: Note
    @State private var showShare = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                section(title: "摘要", content: note.summary)
                section(title: "重點", content: note.keyPoints.joined(separator: "\n• "))
                section(title: "關鍵字", content: note.keywords.joined(separator: ", "))
                section(title: "原文", content: note.rawText)

                if let quiz = appModel.quiz(for: note.id) {
                    NavigationLink {
                        QuizView(quiz: quiz)
                    } label: {
                        Label("開始測驗", systemImage: "questionmark.circle")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: "\(note.title)\n\(note.summary)\n關鍵字：\(note.keywords.joined(separator: ", "))",
                    preview: SharePreview(note.title)
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("刪除筆記？", isPresented: $showDeleteAlert) {
            Button("刪除", role: .destructive) {
                Task {
                    await appModel.delete(note: note)
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("刪除筆記會同時移除相關題庫。此動作無法復原。")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.title.bold())
            Text("來源：\(note.sourceType.rawValue.uppercased())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("更新：\(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
