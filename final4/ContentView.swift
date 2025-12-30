import SwiftUI

struct ContentView: View {
    @StateObject private var appModel = AppViewModel(
        supabase: SupabaseService(config: Secrets.supabaseConfig)
    )

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            ImportView()
                .tabItem { Label("匯入", systemImage: "square.and.arrow.down") }
            NotesView()
                .tabItem { Label("筆記", systemImage: "note.text") }
            QuizListView()
                .tabItem { Label("測驗", systemImage: "checklist") }
            AccountView()
                .tabItem { Label("帳號", systemImage: "person.crop.circle") }
        }
        .environmentObject(appModel)
        .task {
            await appModel.loadInitialData()
        }
    }
}
