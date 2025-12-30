import SwiftUI
import PhotosUI
import Combine

struct ImportView: View {
    @EnvironmentObject var appModel: AppViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var showScanner = false
    @State private var showPDFPicker = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if appModel.isLoading {
                    ProgressView("處理中…")
                }
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label("從照片匯入", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .onChange(of: selectedItem) { _, newItem in
                    guard let item = newItem else { return }
                    Task { await handlePhoto(item: item) }
                }

                Button {
                    showScanner = true
                } label: {
                    Label("掃描紙本文件", systemImage: "doc.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showPDFPicker = true
                } label: {
                    Label("匯入 PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("匯入")
            .sheet(isPresented: $showScanner) {
                DocumentScannerView {
                    images in
                    Task { await appModel.importFromScan(images: images) }
                    showScanner = false
                } onCancel: {
                    showScanner = false
                }
            }
            .sheet(isPresented: $showPDFPicker) {
                PDFPicker { url in
                    Task { await appModel.importFromPDF(url) }
                    showPDFPicker = false
                } onCancel: {
                    showPDFPicker = false
                }
            }
            .onReceive(appModel.$errorMessage.compactMap { $0 }) { _ in
                showError = true
            }
            .alert("錯誤", isPresented: $showError) {
                Button("關閉") { appModel.clearError() }
            } message: {
                Text(appModel.errorMessage ?? "")
            }
        }
    }

    private func handlePhoto(item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            guard let image = UIImage(data: data) else { return }
            await appModel.importFromImage(image, source: .image)
        } catch {
            appModel.errorMessage = "載入圖片失敗：\(error.localizedDescription)"
        }
    }
}
