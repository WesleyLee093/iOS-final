import SwiftUI

struct NotesView: View {
    @EnvironmentObject var appModel: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(appModel.notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(note.title).font(.headline)
                            Text(note.summary).font(.subheadline).lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("筆記列表")
        }
    }
}
