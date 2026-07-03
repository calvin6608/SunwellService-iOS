import SwiftUI
import UIKit

private enum ToolCommand {
    case tel
    case mail
    case telLai
    case bnr
    case trip
    case serviceChart

    var title: String {
        switch self {
        case .tel:
            return "昇威電話"
        case .mail:
            return "昇威 Mail"
        case .telLai:
            return "裕昌電話"
        case .bnr:
            return "B&R License"
        case .trip:
            return "出差紀錄"
        case .serviceChart:
            return "服務圖表"
        }
    }

    var loadingText: String {
        switch self {
        case .tel:
            return "搜尋昇威電話..."
        case .mail:
            return "搜尋昇威 Mail..."
        case .telLai:
            return "載入裕昌電話..."
        case .bnr:
            return "取得 B&R License Trial Code...\n可能需要一段時間。"
        case .trip:
            return "搜尋出差紀錄..."
        case .serviceChart:
            return "產生服務圖表...\n可能需要一段時間。"
        }
    }
}

struct ToolsView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入關鍵字並選擇工具。"
    @State private var resultUrl: String?
    @State private var resultType: String?
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
                    Text("工具")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("關鍵字")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                        TextField("姓名 / 分機 / email / 服務", text: $keyword)
                            .autocapitalization(.none)
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

                    HStack(spacing: 12) {
                        actionButton(ToolCommand.tel.title) {
                            Task { await run(.tel) }
                        }
                        actionButton(ToolCommand.mail.title) {
                            Task { await run(.mail) }
                        }
                    }

                    HStack(spacing: 12) {
                        actionButton(ToolCommand.telLai.title) {
                            Task { await run(.telLai) }
                        }
                        actionButton(ToolCommand.trip.title) {
                            Task { await run(.trip) }
                        }
                    }

                    HStack(spacing: 12) {
                        actionButton(ToolCommand.serviceChart.title) {
                            Task { await run(.serviceChart) }
                        }
                        actionButton(ToolCommand.bnr.title) {
                            Task { await run(.bnr) }
                        }
                    }

                    HStack(spacing: 12) {
                        secondaryButton("清除") {
                            clear()
                        }
                        secondaryButton("複製結果") {
                            UIPasteboard.general.string = resultText
                        }
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accent))
                            Spacer()
                        }
                    }

                    resultPreview

                    resultPanel
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("工具")
        .navigationBarTitleDisplayMode(.inline)
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
        .frame(minHeight: 160)
        .background(panelBackground)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var resultPreview: some View {
        if let urlText = resultUrl, !urlText.trimmed.isEmpty, let url = resolvedURL(urlText) {
            if resultType?.lowercased() == "image" || looksLikeImageURL(url) {
                imagePanel(url: url)
            } else {
                filePanel(url: url)
            }
        }
    }

    private func imagePanel(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 220)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)

            HStack(spacing: 12) {
                actionButton("開啟圖片") {
                    openURL(url)
                }
                actionButton("複製連結") {
                    UIPasteboard.general.string = url.absoluteString
                }
            }
        }
        .padding(14)
        .background(panelBackground)
        .cornerRadius(14)
    }

    private func filePanel(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("伺服器檔案")
                .font(.headline)
                .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))

            Text(url.absoluteString)
                .font(.footnote)
                .foregroundColor(Color(red: 0.68, green: 0.82, blue: 0.79))
                .lineLimit(3)
                .textSelection(.enabled)

            HStack(spacing: 12) {
                actionButton("開啟") {
                    openURL(url)
                }
                actionButton("複製連結") {
                    UIPasteboard.general.string = url.absoluteString
                }
            }
        }
        .padding(14)
        .background(panelBackground)
        .cornerRadius(14)
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
    private func run(_ command: ToolCommand) async {
        hideKeyboard()
        isLoading = true
        resultUrl = nil
        resultType = nil
        resultText = command.loadingText

        do {
            switch command {
            case .tel:
                let result = try await APIClient.shared.searchTel(keyword: keyword.trimmed)
                showToolResult(result, title: command.title)

            case .mail:
                let result = try await APIClient.shared.searchMail(keyword: keyword.trimmed)
                showToolResult(result, title: command.title)

            case .telLai:
                let result = try await APIClient.shared.getTelLai()
                showToolResult(result, title: command.title)

            case .bnr:
                let result = try await APIClient.shared.getBnrLicense()
                showToolResult(result, title: command.title)

            case .trip:
                let result = try await APIClient.shared.searchTrip(keyword: keyword.trimmed)
                showToolResult(result, title: command.title)

            case .serviceChart:
                let result = try await APIClient.shared.getServiceChart(keyword: keyword.trimmed)
                showFileResult(result, title: command.title)
            }
        } catch {
            resultText = errorText(error)
            resultUrl = nil
            resultType = nil
        }

        isLoading = false
    }

    private func showToolResult(_ result: ToolDto, title: String) {
        let successText = result.success ? "是" : "否"
        resultText = "工具: \(title)\n" +
            "成功: \(successText)\n\n" +
            (result.result ?? "")
    }

    private func showFileResult(_ result: ToolFileDto, title: String) {
        let successText = result.success ? "是" : "否"
        let typeText = result.resultType ?? ""
        let messageText = translateServerMessage(result.message)
        resultText = "工具: \(title)\n" +
            "成功: \(successText)\n" +
            "類型: \(typeText)\n" +
            "訊息: \(messageText)"
        resultUrl = result.url
        resultType = result.resultType
    }

    private func clear() {
        keyword = ""
        resultUrl = nil
        resultType = nil
        resultText = "請輸入關鍵字並選擇工具。"
        hideKeyboard()
    }

    private func translateServerMessage(_ message: String?) -> String {
        guard let message = message, !message.trimmed.isEmpty else {
            return ""
        }

        if message.trimmed == "File not found." {
            return "找不到檔案。"
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

    private func looksLikeImageURL(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.hasSuffix(".png") ||
            path.hasSuffix(".jpg") ||
            path.hasSuffix(".jpeg") ||
            path.hasSuffix(".gif") ||
            path.hasSuffix(".webp")
    }

    private func errorText(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .server(let status, let message):
                if status == 401 {
                    return "登入已過期。\n請登出後重新登入。"
                }
                if status == 403 {
                    return "權限不足。"
                }
                return "伺服器錯誤: HTTP \(status)\n\(message)"
            default:
                return apiError.localizedDescription
            }
        }

        return "錯誤:\n\(error.localizedDescription)"
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

