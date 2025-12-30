import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var appModel: AppViewModel
    @State private var searchText = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                if appModel.isLoading {
                    ProgressView("載入中…")
                        .padding()
                }
                if filteredNotes.isEmpty {
                    VStack(spacing: 12) {
                        Text("目前沒有筆記")
                            .font(.headline)
                        Text("前往「匯入」標籤新增，或使用示範資料。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("載入示範資料") {
                            Task { await appModel.seedDemoData() }
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NavigationLink {
                                NoteDetailView(note: note)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(note.title).font(.headline)
                                        Spacer()
                                        Text(note.sourceType.rawValue.uppercased())
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    Text(note.summary)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    if let firstKeyword = note.keywords.first {
                                        Text("關鍵字：\(firstKeyword)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    let note = filteredNotes[index]
                                    await appModel.delete(note: note)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("StudySnap")
            .onReceive(appModel.$errorMessage.compactMap { $0 }) { _ in
                showError = true
            }
            .alert("錯誤", isPresented: $showError) {
                Button("關閉") { appModel.clearError() }
            } message: {
                Text(appModel.errorMessage ?? "")
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("搜尋標題或關鍵字", text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }

    private var filteredNotes: [Note] {
        guard !searchText.isEmpty else { return appModel.notes }
        return appModel.notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.keywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
}
