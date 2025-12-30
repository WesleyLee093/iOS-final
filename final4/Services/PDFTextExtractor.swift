import Foundation
import PDFKit

struct PDFTextExtractor {
    func extractText(from url: URL) -> String {
        guard let document = PDFDocument(url: url) else { return "" }
        var result = ""
        for index in 0..<document.pageCount {
            if let page = document.page(at: index), let text = page.string {
                result.append(text)
                result.append("\n")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
