import Foundation

protocol LocalStore {
    func loadNotes() async throws -> [Note]
    func loadQuizzes() async throws -> [Quiz]
    func save(notes: [Note]) async throws
    func save(quizzes: [Quiz]) async throws
}

actor JSONLocalStore: LocalStore {
    private let notesURL: URL
    private let quizzesURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filenamePrefix: String = "studysnap") {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.notesURL = base.appendingPathComponent("\(filenamePrefix)_notes.json")
        self.quizzesURL = base.appendingPathComponent("\(filenamePrefix)_quizzes.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadNotes() async throws -> [Note] {
        guard FileManager.default.fileExists(atPath: notesURL.path) else { return [] }
        let data = try Data(contentsOf: notesURL)
        return try decoder.decode([Note].self, from: data)
    }

    func loadQuizzes() async throws -> [Quiz] {
        guard FileManager.default.fileExists(atPath: quizzesURL.path) else { return [] }
        let data = try Data(contentsOf: quizzesURL)
        return try decoder.decode([Quiz].self, from: data)
    }

    func save(notes: [Note]) async throws {
        let data = try encoder.encode(notes)
        try data.write(to: notesURL, options: .atomic)
    }

    func save(quizzes: [Quiz]) async throws {
        let data = try encoder.encode(quizzes)
        try data.write(to: quizzesURL, options: .atomic)
    }
}
