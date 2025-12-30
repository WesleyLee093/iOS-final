import Foundation
import Vision
import UIKit

final class OCRService {
    func recognizeText(from image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func recognizeText(from uiImage: UIImage) async throws -> String {
        guard let cgImage = uiImage.cgImage else {
            throw NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法取得 CGImage"])
        }
        return try await recognizeText(from: cgImage)
    }
}
