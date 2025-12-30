import Foundation

struct SupabaseConfig {
    let url: URL
    let anonKey: String
}

enum SupabaseError: Error {
    case invalidResponse
    case missingConfig
}

struct SupabaseAuthResponse: Codable {
    let access_token: String
    let user: SupabaseAuthUser
}

struct SupabaseAuthUser: Codable {
    let id: UUID
    let email: String?
}

struct RemoteNote: Codable {
    var id: UUID
    var userId: UUID
    var title: String
    var sourceType: String
    var rawText: String
    var summary: String
    var keyPoints: [String]
    var keywords: [String]
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case sourceType = "source_type"
        case rawText = "raw_text"
        case summary
        case keyPoints = "key_points"
        case keywords
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(note: Note, userId: UUID) {
        self.id = note.id
        self.userId = userId
        self.title = note.title
        self.sourceType = note.sourceType.rawValue
        self.rawText = note.rawText
        self.summary = note.summary
        self.keyPoints = note.keyPoints
        self.keywords = note.keywords
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
    }

    func toNote() -> Note? {
        guard let source = NoteSourceType(rawValue: sourceType) else { return nil }
        return Note(
            id: id,
            title: title,
            sourceType: source,
            rawText: rawText,
            summary: summary,
            keyPoints: keyPoints,
            keywords: keywords,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct RemoteQuiz: Codable {
    var id: UUID
    var noteId: UUID
    var userId: UUID
    var questions: [Question]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case noteId = "note_id"
        case userId = "user_id"
        case questions
        case createdAt = "created_at"
    }

    init(quiz: Quiz, userId: UUID) {
        self.id = quiz.id
        self.noteId = quiz.noteId
        self.userId = userId
        self.questions = quiz.questions
        self.createdAt = quiz.createdAt
    }

    func toQuiz() -> Quiz {
        Quiz(id: id, noteId: noteId, questions: questions, createdAt: createdAt)
    }
}

final class SupabaseService {
    private let config: SupabaseConfig
    private let session: URLSession
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(config: SupabaseConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func signUp(email: String, password: String) async throws -> SupabaseUser {
        let payload = ["email": email, "password": password]
        let request = try makeRequest(path: "/auth/v1/signup", method: "POST", body: payload, includeAuth: false)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
        let auth = try decoder.decode(SupabaseAuthResponse.self, from: data)
        return SupabaseUser(id: auth.user.id, email: auth.user.email ?? email, accessToken: auth.access_token)
    }

    func signIn(email: String, password: String) async throws -> SupabaseUser {
        let payload = ["email": email, "password": password]
        let request = try makeRequest(path: "/auth/v1/token?grant_type=password", method: "POST", body: payload, includeAuth: false)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
        let auth = try decoder.decode(SupabaseAuthResponse.self, from: data)
        return SupabaseUser(id: auth.user.id, email: auth.user.email ?? email, accessToken: auth.access_token)
    }

    func fetchNotes(user: SupabaseUser) async throws -> [Note] {
        let request = try makeRequest(path: "/rest/v1/notes?select=*", method: "GET", includeAuth: true, token: user.accessToken)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
        let remoteNotes = try decoder.decode([RemoteNote].self, from: data)
        return remoteNotes.compactMap { $0.toNote() }
    }

    func upload(notes: [Note], user: SupabaseUser) async throws {
        let remote = notes.map { RemoteNote(note: $0, userId: user.id) }
        let request = try makeRequest(path: "/rest/v1/notes", method: "POST", body: remote, includeAuth: true, token: user.accessToken, additionalHeaders: [
            "Prefer": "resolution=merge-duplicates"
        ])
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
    }

    func fetchQuizzes(user: SupabaseUser) async throws -> [Quiz] {
        let request = try makeRequest(path: "/rest/v1/quizzes?select=*", method: "GET", includeAuth: true, token: user.accessToken)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
        let remote = try decoder.decode([RemoteQuiz].self, from: data)
        return remote.map { $0.toQuiz() }
    }

    func upload(quizzes: [Quiz], user: SupabaseUser) async throws {
        let remote = quizzes.map { RemoteQuiz(quiz: $0, userId: user.id) }
        let request = try makeRequest(path: "/rest/v1/quizzes", method: "POST", body: remote, includeAuth: true, token: user.accessToken, additionalHeaders: [
            "Prefer": "resolution=merge-duplicates"
        ])
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 else {
            throw SupabaseError.invalidResponse
        }
    }

    // MARK: - Helpers

    private func makeRequest<T: Encodable>(
        path: String,
        method: String,
        body: T,
        includeAuth: Bool,
        token: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) throws -> URLRequest {
        var request = try makeRequest(path: path, method: method, includeAuth: includeAuth, token: token, additionalHeaders: additionalHeaders)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func makeRequest(
        path: String,
        method: String,
        includeAuth: Bool,
        token: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: config.url) else {
            throw SupabaseError.missingConfig
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        if includeAuth, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        additionalHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}
