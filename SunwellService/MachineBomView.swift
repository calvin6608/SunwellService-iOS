import SwiftUI
import UIKit

private enum MachineBomCommand {
    case mcsPdf
    case mtPdf
    case mcsPn
    case mtPn

    var title: String {
        switch self {
        case .mcsPdf:
            return "MCS PDF"
        case .mtPdf:
            return "MT PDF"
        case .mcsPn:
            return "MCS PN Text"
        case .mtPn:
            return "MT PN Text"
        }
    }

    var reportName: String {
        switch self {
        case .mcsPdf:
            return "MCS BOM"
        case .mtPdf:
            return "MT BOM"
        case .mcsPn:
            return "MCS Part Number List"
        case .mtPn:
            return "MT Part Number List"
        }
    }

    var loadingText: String {
        switch self {
        case .mcsPdf:
            return "產生 MCS BOM PDF...\n可能需要一段時間。"
        case .mtPdf:
            return "產生 MT BOM PDF...\n可能需要一段時間。"
        case .mcsPn:
            return "查詢 MCS Part Number List..."
        case .mtPn:
            return "查詢 MT Part Number List..."
        }
    }
}

struct MachineBomView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入關鍵字 / 篩選條件，然後選擇 MCS 或 MT 功能。"
    @State private var pdfUrl: String?
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
                    Text("MCS / MT 次組立")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("關鍵字 / 篩選")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                        TextField("MCS, MT, customer, part no.", text: Binding(
                            get: { keyword },
                            set: { keyword = $0.uppercased() }
                        ))
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

                    HStack(spacing: 12) {
                        actionButton(MachineBomCommand.mcsPdf.title) {
                            Task { await run(.mcsPdf) }
                        }
                        actionButton(MachineBomCommand.mtPdf.title) {
                            Task { await run(.mtPdf) }
                        }
                    }

                    HStack(spacing: 12) {
                        actionButton(MachineBomCommand.mcsPn.title) {
                            Task { await run(.mcsPn) }
                        }
                        actionButton(MachineBomCommand.mtPn.title) {
                            Task { await run(.mtPn) }
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

                    resultPanel

                    pdfPanel
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("MCS / MT 次組立")
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
        .frame(minHeight: 180)
        .background(panelBackground)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var pdfPanel: some View {
        if let urlText = pdfUrl, !urlText.trimmed.isEmpty, let url = resolvedURL(urlText) {
            VStack(alignment: .leading, spacing: 12) {
                Text("PDF 檔案")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))

                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundColor(Color(red: 0.68, green: 0.82, blue: 0.79))
                    .lineLimit(3)
                    .textSelection(.enabled)

                HStack(spacing: 12) {
                    actionButton("開啟 PDF") {
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
    private func run(_ command: MachineBomCommand) async {
        hideKeyboard()
        isLoading = true
        pdfUrl = nil
        resultText = command.loadingText

        do {
            switch command {
            case .mcsPdf:
                let result = try await APIClient.shared.getMcsBomPdf(keyword: keyword.trimmed)
                showPdfResult(result, reportName: command.reportName)

            case .mtPdf:
                let result = try await APIClient.shared.getMtBomPdf(keyword: keyword.trimmed)
                showPdfResult(result, reportName: command.reportName)

            case .mcsPn:
                let result = try await APIClient.shared.getMcsPnText(keyword: keyword.trimmed)
                showTextResult(result, reportName: command.reportName)

            case .mtPn:
                let result = try await APIClient.shared.getMtPnText(keyword: keyword.trimmed)
                showTextResult(result, reportName: command.reportName)
            }
        } catch {
            resultText = errorText(error)
            pdfUrl = nil
        }

        isLoading = false
    }

    private func showPdfResult(_ result: MachineBomPdfDto, reportName: String) {
        let successText = result.success ? "是" : "否"
        let messageText = translateServerMessage(result.message)
        resultText = "報表: \(reportName)\n" +
            "成功: \(successText)\n" +
            "訊息: \(messageText)"
        pdfUrl = result.pdfUrl
    }

    private func showTextResult(_ result: MachineBomTextDto, reportName: String) {
        let successText = result.success ? "是" : "否"
        resultText = "報表: \(reportName)\n" +
            "成功: \(successText)\n\n" +
            (result.result ?? "")
        pdfUrl = nil
    }

    private func clear() {
        keyword = ""
        pdfUrl = nil
        resultText = "請輸入關鍵字 / 篩選條件，然後選擇 MCS 或 MT 功能。"
        hideKeyboard()
    }

    private func translateServerMessage(_ message: String?) -> String {
        guard let message = message, !message.trimmed.isEmpty else {
            return ""
        }

        if message.trimmed == "File not found." {
            return "找不到檔案。"
        }
        if message.trimmed == "No matching data." {
            return "找不到符合資料。"
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
