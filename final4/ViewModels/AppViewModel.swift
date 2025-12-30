import Foundation
import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var quizzes: [UUID: Quiz] = [:] // keyed by noteId
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var user: SupabaseUser?
    @Published var syncStatus: String?

    private let localStore: LocalStore
    private let summarizer: LocalSummarizerProtocol
    private let quizGenerator: QuizGenerator
    private let ocrService: OCRService
    private let pdfExtractor: PDFTextExtractor
    private let syncService: SyncService
    private let supabase: SupabaseService

    init(
        localStore: LocalStore = JSONLocalStore(),
        summarizer: LocalSummarizerProtocol = HeuristicSummarizer(),
        quizGenerator: QuizGenerator = QuizGenerator(),
        ocrService: OCRService = OCRService(),
        pdfExtractor: PDFTextExtractor = PDFTextExtractor(),
        syncService: SyncService = SyncService(),
        supabase: SupabaseService
    ) {
        self.localStore = localStore
        self.summarizer = summarizer
        self.quizGenerator = quizGenerator
        self.ocrService = ocrService
        self.pdfExtractor = pdfExtractor
        self.syncService = syncService
        self.supabase = supabase
    }

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            notes = try await localStore.loadNotes()
            let storedQuizzes = try await localStore.loadQuizzes()
            quizzes = Dictionary(uniqueKeysWithValues: storedQuizzes.map { ($0.noteId, $0) })
            if notes.isEmpty {
                await seedDemoData()
            }
        } catch {
            errorMessage = "讀取本地資料失敗：\(error.localizedDescription)"
        }
    }

    func seedDemoData() async {
        let demoNote = DemoData.demoNote
        let demoQuiz = DemoData.demoQuiz
        notes = [demoNote]
        quizzes[demoNote.id] = demoQuiz
        do {
            try await localStore.save(notes: notes)
            try await localStore.save(quizzes: [demoQuiz])
        } catch {
            errorMessage = "無法儲存示範資料：\(error.localizedDescription)"
        }
    }

    func importFromImage(_ image: UIImage, source: NoteSourceType) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let text = try await ocrService.recognizeText(from: image)
            try await handleRawText(text, source: source)
        } catch {
            errorMessage = "OCR 失敗：\(error.localizedDescription)"
        }
    }

    func importFromPDF(_ url: URL) async {
        isLoading = true
        defer { isLoading = false }
        let text = pdfExtractor.extractText(from: url)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "PDF 無法抽取文字，請改用掃描功能。"
            return
        }
        do {
            try await handleRawText(text, source: .pdf)
        } catch {
            errorMessage = "處理 PDF 文字失敗：\(error.localizedDescription)"
        }
    }

    func importFromScan(images: [UIImage]) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var merged = ""
            for image in images {
                let text = try await ocrService.recognizeText(from: image)
                merged.append(text)
                merged.append("\n")
            }
            try await handleRawText(merged, source: .scan)
        } catch {
            errorMessage = "掃描 OCR 失敗：\(error.localizedDescription)"
        }
    }

    func handleRawText(_ text: String, source: NoteSourceType) async throws {
        let result = summarizer.summarize(text: text, maxSentences: 3)
        let note = Note(
            id: UUID(),
            title: makeTitle(from: text),
            sourceType: source,
            rawText: text,
            summary: result.summary,
            keyPoints: result.keyPoints,
            keywords: result.keywords,
            createdAt: Date(),
            updatedAt: Date()
        )
        let quiz = quizGenerator.generateQuiz(for: note.id, summary: result)
        await save(note: note, quiz: quiz)
    }

    func save(note: Note, quiz: Quiz) async {
        notes.insert(note, at: 0)
        quizzes[note.id] = quiz
        do {
            try await localStore.save(notes: notes)
            try await localStore.save(quizzes: Array(quizzes.values))
        } catch {
            errorMessage = "儲存本地資料失敗：\(error.localizedDescription)"
        }
    }

    func quiz(for noteId: UUID) -> Quiz? {
        quizzes[noteId]
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await supabase.signUp(email: email, password: password)
            self.user = user
            syncStatus = "註冊成功"
        } catch {
            errorMessage = "註冊失敗：\(error.localizedDescription)"
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await supabase.signIn(email: email, password: password)
            self.user = user
            syncStatus = "登入成功"
        } catch {
            errorMessage = "登入失敗：\(error.localizedDescription)"
        }
    }

    func signOut() {
        user = nil
    }

    func sync() async {
        guard let user else {
            errorMessage = "請先登入後再同步。"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let remoteNotes = try await supabase.fetchNotes(user: user)
            let remoteQuizzes = try await supabase.fetchQuizzes(user: user)
            let plan = syncService.plan(
                localNotes: notes,
                remoteNotes: remoteNotes,
                localQuizzes: Array(quizzes.values),
                remoteQuizzes: remoteQuizzes
            )
            if !plan.notesToUpload.isEmpty {
                try await supabase.upload(notes: plan.notesToUpload, user: user)
            }
            if !plan.quizzesToUpload.isEmpty {
                try await supabase.upload(quizzes: plan.quizzesToUpload, user: user)
            }

            notes = plan.mergedNotes.sorted { $0.updatedAt > $1.updatedAt }
            quizzes = Dictionary(uniqueKeysWithValues: plan.mergedQuizzes.map { ($0.noteId, $0) })
            try await localStore.save(notes: notes)
            try await localStore.save(quizzes: Array(quizzes.values))
            syncStatus = "同步完成，上傳 \(plan.notesToUpload.count) 筆，合併 \(plan.mergedNotes.count) 筆。"
        } catch {
            errorMessage = "同步失敗：\(error.localizedDescription)"
        }
    }

    func delete(note: Note) async {
        notes.removeAll { $0.id == note.id }
        quizzes.removeValue(forKey: note.id)
        do {
            try await localStore.save(notes: notes)
            try await localStore.save(quizzes: Array(quizzes.values))
        } catch {
            errorMessage = "刪除失敗：\(error.localizedDescription)"
        }
    }

    func deleteQuiz(for noteId: UUID) async {
        quizzes.removeValue(forKey: noteId)
        do {
            try await localStore.save(quizzes: Array(quizzes.values))
        } catch {
            errorMessage = "刪除題庫失敗：\(error.localizedDescription)"
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func makeTitle(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "新筆記" : String(trimmed.prefix(30))
    }
}
