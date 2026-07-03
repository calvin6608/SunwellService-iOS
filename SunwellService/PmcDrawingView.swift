import SwiftUI
import UIKit

struct PmcDrawingView: View {
    @State private var keyword = ""
    @State private var filePath = ""
    @State private var resultText = "請輸入關鍵字並搜尋 PMC 圖檔。"
    @State private var fileUrl: String?
    @State private var fileLongUrl: String?
    @State private var fileName: String?
    @State private var isLoading = false

    private let serverBaseURL = URL(string: "https://linebot.sunwell.work/")!
    private let pageBackground = Color(red: 0.07, green: 0.14, blue: 0.13)
    private let panelBackground = Color(red: 0.11, green: 0.24, blue: 0.22)
    private let fieldBackground = Color(red: 0.08, green: 0.18, blue: 0.17)
    private let accent = Color(red: 0.28, green: 0.87, blue: 0.81)
    private let textColor = Color(red: 0.86, green: 0.96, blue: 0.94)

    var body: some View {
        ZStack {
            pageBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("PMC 圖檔")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .padding(.top, 18)

                    searchSection

                    HStack(spacing: 12) {
                        actionButton("搜尋") {
                            Task { await search() }
                        }
                        secondaryButton("清除") {
                            clear()
                        }
                    }

                    fileLinkSection

                    HStack(spacing: 12) {
                        secondaryButton("複製結果") {
                            UIPasteboard.general.string = resultText
                        }
                        secondaryButton("複製連結") {
                            UIPasteboard.general.string = fileUrl ?? fileLongUrl ?? ""
                        }
                        .disabled((fileUrl ?? fileLongUrl ?? "").isEmpty)
                        .opacity((fileUrl ?? fileLongUrl ?? "").isEmpty ? 0.45 : 1.0)
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accent))
                            Spacer()
                        }
                    }

                    linkPanel

                    resultPanel
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("PMC 圖檔")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("關鍵字")
                .font(.headline)
                .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

            TextField("例如 105-835", text: $keyword)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .font(.title2)
                .foregroundColor(textColor)
                .padding(16)
                .background(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                )
        }
    }

    private var fileLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("檔案下載連結")
                .font(.title2.weight(.bold))
                .foregroundColor(textColor)

            TextField("\\\\192.168.100.xx\\folder\\file.pdf", text: $filePath)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.body)
                .foregroundColor(textColor)
                .padding(16)
                .background(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                )

            HStack(spacing: 12) {
                actionButton("取得連結") {
                    Task { await getFileLink() }
                }
                actionButton("開啟檔案") {
                    openBestFileURL()
                }
                .disabled((fileLongUrl ?? fileUrl ?? "").isEmpty)
                .opacity((fileLongUrl ?? fileUrl ?? "").isEmpty ? 0.45 : 1.0)
            }
        }
        .padding(14)
        .background(panelBackground)
        .cornerRadius(14)
    }

    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical) {
                Text(resultText)
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
            }
        }
        .frame(minHeight: 180)
        .background(panelBackground)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var linkPanel: some View {
        if let urlText = fileUrl, !urlText.trimmed.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(fileName ?? "File Link")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))

                Text(urlText)
                    .font(.footnote)
                    .foregroundColor(Color(red: 0.68, green: 0.82, blue: 0.79))
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
            .padding(14)
            .background(panelBackground)
            .cornerRadius(14)
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(accent)
                .cornerRadius(28)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.65 : 1.0)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.16, green: 0.34, blue: 0.31), lineWidth: 1.5)
                )
        }
        .disabled(isLoading)
    }

    @MainActor
    private func search() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入關鍵字。"
            return
        }

        hideKeyboard()
        isLoading = true
        resultText = "搜尋 PMC 圖檔..."

        do {
            let result = try await APIClient.shared.searchPmcDrawing(keyword: key)
            let successText = result.success ? "是" : "否"
            resultText = "關鍵字: \(result.keyword)\n" +
                "成功: \(successText)\n\n" +
                (result.result ?? "")
        } catch {
            resultText = errorText(error, forbiddenText: "權限不足。\nPMC 圖檔僅開放授權使用者。")
        }

        isLoading = false
    }

    @MainActor
    private func getFileLink() async {
        let path = filePath.trimmed
        guard !path.isEmpty else {
            resultText = "請輸入檔案路徑。"
            fileUrl = nil
            fileLongUrl = nil
            fileName = nil
            return
        }

        hideKeyboard()
        isLoading = true
        resultText = "上傳檔案並產生連結..."
        fileUrl = nil
        fileLongUrl = nil
        fileName = nil

        do {
            let result = try await APIClient.shared.getPmcFileLink(path: path)
            let successText = result.success ? "是" : "否"
            let messageText = translateServerMessage(result.message)
            let nameText = result.fileName ?? ""
            resultText = "成功: \(successText)\n" +
                "檔案: \(nameText)\n" +
                "訊息: \(messageText)\n\n" +
                "連結:\n" +
                (result.url ?? "")
            fileUrl = result.url
            fileLongUrl = result.longUrl
            fileName = result.fileName
        } catch {
            fileUrl = nil
            fileLongUrl = nil
            fileName = nil
            resultText = errorText(error, forbiddenText: "權限不足。\n無法存取 PMC 圖檔檔案。")
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        filePath = ""
        fileUrl = nil
        fileLongUrl = nil
        fileName = nil
        resultText = "請輸入關鍵字並搜尋 PMC 圖檔。"
        hideKeyboard()
    }

    private func translateServerMessage(_ message: String?) -> String {
        guard let message = message, !message.trimmed.isEmpty else {
            return ""
        }

        if message.trimmed == "File not found." {
            return "找不到檔案。"
        }
        if message.trimmed == "Approval permission denied." {
            return "權限不足。"
        }

        return message
    }

    private func resolvedURL(_ urlText: String) -> URL? {
        let value = urlText.trimmed
        if let absolute = URL(string: value), absolute.scheme != nil {
            return absolute
        }

        if value.hasPrefix("/") {
            let path = String(value.dropFirst())
            return URL(string: path, relativeTo: serverBaseURL)?.absoluteURL
        }

        return URL(string: value, relativeTo: serverBaseURL)?.absoluteURL
    }

    private func openBestFileURL() {
        let urlText = fileLongUrl ?? fileUrl ?? ""
        guard let url = resolvedURL(urlText) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func errorText(_ error: Error, forbiddenText: String) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .server(let status, let message):
                if status == 401 {
                    return "登入已過期。\n請登出後重新登入。"
                }
                if status == 403 {
                    return forbiddenText
                }
                return "伺服器錯誤: HTTP \(status)\n\(message)"
            default:
                return apiError.localizedDescription
            }
        }

        return "錯誤:\n\(error.localizedDescription)"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

