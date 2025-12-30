import Foundation

enum Secrets {
    /// TODO: 將此檔案填入實際 Supabase 專案 URL / anon key，並可改名避開版本控制
    static let supabaseConfig = SupabaseConfig(
        url: URL(string: "https://your-project.supabase.co")!,
        anonKey: "YOUR_SUPABASE_ANON_KEY"
    )
}
