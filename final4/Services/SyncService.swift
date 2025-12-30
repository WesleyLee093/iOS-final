import Foundation

struct SyncPlan {
    let mergedNotes: [Note]
    let mergedQuizzes: [Quiz]
    let notesToUpload: [Note]
    let quizzesToUpload: [Quiz]
}

struct SyncService {
    func plan(localNotes: [Note], remoteNotes: [Note], localQuizzes: [Quiz], remoteQuizzes: [Quiz]) -> SyncPlan {
        let noteResult = mergeNotes(local: localNotes, remote: remoteNotes)
        let quizResult = mergeQuizzes(local: localQuizzes, remote: remoteQuizzes)
        return SyncPlan(
            mergedNotes: noteResult.merged,
            mergedQuizzes: quizResult.merged,
            notesToUpload: noteResult.toUpload,
            quizzesToUpload: quizResult.toUpload
        )
    }

    private func mergeNotes(local: [Note], remote: [Note]) -> (merged: [Note], toUpload: [Note]) {
        var merged: [UUID: Note] = [:]
        var toUpload: [Note] = []
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        let localDict = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let allIds = Set(remoteDict.keys).union(localDict.keys)

        for id in allIds {
            let localNote = localDict[id]
            let remoteNote = remoteDict[id]
            switch (localNote, remoteNote) {
            case let (l?, r?):
                if l.updatedAt >= r.updatedAt {
                    merged[id] = l
                    if l.updatedAt > r.updatedAt { toUpload.append(l) }
                } else {
                    merged[id] = r
                }
            case let (l?, nil):
                merged[id] = l
                toUpload.append(l)
            case let (nil, r?):
                merged[id] = r
            default:
                break
            }
        }
        return (Array(merged.values), toUpload)
    }

    private func mergeQuizzes(local: [Quiz], remote: [Quiz]) -> (merged: [Quiz], toUpload: [Quiz]) {
        var merged: [UUID: Quiz] = [:]
        var toUpload: [Quiz] = []
        let remoteDict = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        let localDict = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let allIds = Set(remoteDict.keys).union(localDict.keys)

        for id in allIds {
            let localQuiz = localDict[id]
            let remoteQuiz = remoteDict[id]
            switch (localQuiz, remoteQuiz) {
            case let (l?, r?):
                if l.createdAt >= r.createdAt {
                    merged[id] = l
                    if r.createdAt < l.createdAt { toUpload.append(l) }
                } else {
                    merged[id] = r
                }
            case let (l?, nil):
                merged[id] = l
                toUpload.append(l)
            case let (nil, r?):
                merged[id] = r
            default:
                break
            }
        }
        return (Array(merged.values), toUpload)
    }
}
