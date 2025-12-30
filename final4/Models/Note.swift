import Foundation

enum NoteSourceType: String, Codable, CaseIterable, Identifiable {
    case image
    case scan
    case pdf

    var id: String { rawValue }
}

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var sourceType: NoteSourceType
    var rawText: String
    var summary: String
    var keyPoints: [String]
    var keywords: [String]
    var createdAt: Date
    var updatedAt: Date
}

struct SummaryResult: Codable, Equatable {
    var summary: String
    var keyPoints: [String]
    var keywords: [String]
}

struct Quiz: Identifiable, Codable, Equatable {
    var id: UUID
    var noteId: UUID
    var questions: [Question]
    var createdAt: Date
}

struct Question: Identifiable, Codable, Equatable {
    var id: UUID
    var prompt: String
    var choices: [String] // count = 4
    var answerIndex: Int // 0...3
    var explanation: String?
}

struct SupabaseUser: Codable, Equatable {
    var id: UUID
    var email: String
    var accessToken: String
}

enum DemoData {
    static let demoNote: Note = {
        let text = """
        SwiftUI 讓你用宣告式語法建立 iOS 介面，結合 async/await 可以簡化非同步流程。
        Vision 框架提供 OCR 功能，PDFKit 可以解析 PDF 文字。
        """
        let summary = "SwiftUI 可宣告式建立介面，搭配 async/await 簡化非同步；Vision 可做 OCR，PDFKit 解析 PDF。"
        let keyPoints = [
            "SwiftUI 使用宣告式語法建立介面",
            "async/await 簡化非同步呼叫",
            "Vision 可做本地 OCR",
            "PDFKit 可抽取 PDF 文字"
        ]
        let keywords = ["SwiftUI", "async/await", "Vision", "PDFKit"]
        let now = Date()
        return Note(
            id: UUID(),
            title: "範例筆記",
            sourceType: .image,
            rawText: text,
            summary: summary,
            keyPoints: keyPoints,
            keywords: keywords,
            createdAt: now,
            updatedAt: now
        )
    }()

    static let demoQuiz: Quiz = {
        let noteId = demoNote.id
        let questions = (1...10).map { index in
            Question(
                id: UUID(),
                prompt: "SwiftUI 與 async/await 可以帶來什麼好處？(\(index))",
                choices: [
                    "簡化非同步流程並提升可讀性",
                    "只用於資料庫連線",
                    "只能在 macOS 使用",
                    "需要伺服器端支援"
                ],
                answerIndex: 0,
                explanation: "SwiftUI 的宣告式語法與 async/await 讓 UI 更新與非同步呼叫更直覺。"
            )
        }
        return Quiz(id: UUID(), noteId: noteId, questions: questions, createdAt: Date())
    }()
}
