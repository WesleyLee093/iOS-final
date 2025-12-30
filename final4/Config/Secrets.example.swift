import Foundation

enum SecretsExample {
    static let supabaseConfig = SupabaseConfig(
        url: URL(string: "https://your-project.supabase.co")!,
        anonKey: "YOUR_SUPABASE_ANON_KEY"
    )
}
