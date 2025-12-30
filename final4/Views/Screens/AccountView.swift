import SwiftUI
import Combine

struct AccountView: View {
    @EnvironmentObject var appModel: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("帳號")) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                    HStack {
                        Button("登入") {
                            Task { await appModel.signIn(email: email, password: password) }
                        }
                        Spacer()
                        Button("註冊") {
                            Task { await appModel.signUp(email: email, password: password) }
                        }
                    }
                }

                Section(header: Text("狀態")) {
                    if let user = appModel.user {
                        Text("已登入：\(user.email)")
                        Button("登出") { appModel.signOut() }
                    } else {
                        Text("未登入").foregroundStyle(.secondary)
                    }
                    if appModel.isLoading {
                        ProgressView()
                    }
                    if let syncStatus = appModel.syncStatus {
                        Text(syncStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("同步")) {
                    Button {
                        Task { await appModel.sync() }
                    } label: {
                        Label("立即同步", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .navigationTitle("帳號 / 同步")
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
}
