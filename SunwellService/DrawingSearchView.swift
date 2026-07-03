import SwiftUI
import UIKit

private enum DrawingSuggestMode: String {
    case start = "start"
    case any = "any"

    var title: String {
        switch self {
        case .start:
            return "起始符合"
        case .any:
            return "任意位置"
        }
    }
}

private enum DrawingLookupKind {
    case drawing
    case pdf

    var buttonTitle: String {
        switch self {
        case .drawing:
            return "CAD 圖片"
        case .pdf:
            return "PDF"
        }
    }

    var loadingText: String {
        switch self {
        case .drawing:
            return "搜尋 CAD 圖片...\n可能需要一段時間。"
        case .pdf:
            return "搜尋 PDF...\n可能需要一段時間。"
        }
    }
}

struct DrawingSearchView: View {
    @State private var partNo = ""
    @State private var suggestMode: DrawingSuggestMode = .start
    @State private var suggestions: [String] = []
    @State private var resultText = "請輸入料號並按 CAD 圖片或 PDF。"
    @State private var resultUrl: String?
    @State private var resultType: String?
    @State private var approvalRequired = false
    @State private var approvalRequestId: Int64?
    @State private var isLoading = false
    @State private var suggestionTask: Task<Void, Never>?

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
                    Text("CAD 圖檔查詢")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .padding(.top, 18)

                    HStack(spacing: 12) {
                        modeButton(.start)
                        modeButton(.any)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("料號")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                        TextField("例如 EX01520", text: Binding(
                            get: { partNo },
                            set: { value in
                                partNo = value.uppercased()
                                scheduleSuggestions()
                            }
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

                    if !suggestions.isEmpty {
                        suggestionPanel
                    }

                    HStack(spacing: 12) {
                        secondaryButton("貼上") {
                            if let text = UIPasteboard.general.string, !text.trimmed.isEmpty {
                                partNo = text.trimmed.uppercased()
                                suggestions = []
                                hideKeyboard()
                            }
                        }

                        secondaryButton("複製") {
                            UIPasteboard.general.string = partNo.trimmed
                        }
                        .disabled(partNo.trimmed.isEmpty)
                        .opacity(partNo.trimmed.isEmpty ? 0.45 : 1.0)

                        actionButton("清除") {
                            clear()
                        }
                    }

                    HStack(spacing: 12) {
                        actionButton(DrawingLookupKind.drawing.buttonTitle) {
                            Task { await search(kind: .drawing) }
                        }

                        actionButton(DrawingLookupKind.pdf.buttonTitle) {
                            Task { await search(kind: .pdf) }
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

                    resultPreview
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("CAD 圖檔查詢")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            suggestionTask?.cancel()
        }
    }

    private var suggestionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.prefix(8)), id: \.self) { item in
                Button(action: {
                    partNo = item.uppercased()
                    suggestions = []
                    hideKeyboard()
                }) {
                    HStack {
                        Text(item)
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }

                Divider()
                    .background(Color(red: 0.20, green: 0.34, blue: 0.32))
            }
        }
        .background(Color(red: 0.10, green: 0.23, blue: 0.21))
        .cornerRadius(10)
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
        .frame(minHeight: 120)
        .background(panelBackground)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var resultPreview: some View {
        if let urlText = resultUrl, !urlText.trimmed.isEmpty, let url = resolvedURL(urlText) {
            if resultType?.lowercased() == "image" || looksLikeImageURL(url) {
                imagePanel(url: url, originalText: urlText)
            } else {
                filePanel(url: url, originalText: urlText)
            }
        }
    }

    private func imagePanel(url: URL, originalText: String) -> some View {
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

    private func filePanel(url: URL, originalText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resultType?.lowercased() == "pdf" ? "PDF 檔案" : "伺服器檔案")
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

    private func modeButton(_ mode: DrawingSuggestMode) -> some View {
        Button(action: {
            suggestMode = mode
            scheduleSuggestions(delayNanoseconds: 0)
        }) {
            Text((suggestMode == mode ? "✓ " : "") + mode.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(accent)
                .cornerRadius(28)
        }
        .disabled(isLoading)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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

    private func scheduleSuggestions(delayNanoseconds: UInt64 = 300_000_000) {
        suggestionTask?.cancel()

        let key = partNo.trimmed
        let mode = suggestMode.rawValue
        if key.count < 2 {
            suggestions = []
            return
        }

        suggestionTask = Task {
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            if Task.isCancelled { return }

            do {
                let result = try await APIClient.shared.suggestDrawings(keyword: key, mode: mode)
                if Task.isCancelled { return }

                await MainActor.run {
                    if partNo.trimmed == key && suggestMode.rawValue == mode {
                        suggestions = result
                    }
                }
            } catch {
                await MainActor.run {
                    if partNo.trimmed == key && suggestMode.rawValue == mode {
                        suggestions = []
                    }
                }
            }
        }
    }

    @MainActor
    private func search(kind: DrawingLookupKind) async {
        let key = partNo.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入料號。"
            resultUrl = nil
            resultType = nil
            approvalRequired = false
            approvalRequestId = nil
            return
        }

        hideKeyboard()
        suggestions = []
        isLoading = true
        resultText = kind.loadingText
        resultUrl = nil
        resultType = nil
        approvalRequired = false
        approvalRequestId = nil

        do {
            let result: DrawingDto
            switch kind {
            case .drawing:
                result = try await APIClient.shared.getDrawing(partNo: key)
            case .pdf:
                result = try await APIClient.shared.getPdf(partNo: key)
            }

            approvalRequired = result.approvalRequired == true
            approvalRequestId = result.approvalRequestId

            if approvalRequired {
                resultText = "料號: \(result.partNo)\n" +
                    "狀態: 需要審核\n" +
                    requestIdText(approvalRequestId) +
                    "訊息: \(translateServerMessage(result.message))"
            } else {
                let successText = result.success ? "是" : "否"
                let typeText = result.resultType ?? ""
                let messageText = translateServerMessage(result.message)
                resultText = "料號: \(result.partNo)\n" +
                    "成功: \(successText)\n" +
                    "類型: \(typeText)\n" +
                    "訊息: \(messageText)"
                resultUrl = result.url
                resultType = result.resultType
            }
        } catch {
            resultText = errorText(error)
            resultUrl = nil
            resultType = nil
        }

        isLoading = false
    }

    private func requestIdText(_ id: Int64?) -> String {
        if let id = id {
            return "申請編號: \(id)\n"
        }
        return ""
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

    private func clear() {
        suggestionTask?.cancel()
        partNo = ""
        suggestions = []
        resultText = "請輸入料號並按 CAD 圖片或 PDF。"
        resultUrl = nil
        resultType = nil
        approvalRequired = false
        approvalRequestId = nil
        hideKeyboard()
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

