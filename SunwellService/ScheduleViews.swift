import SwiftUI
import UIKit

private struct ScheduleColors {
    static let pageBackground = Color(red: 0.07, green: 0.14, blue: 0.13)
    static let panelBackground = Color(red: 0.11, green: 0.24, blue: 0.22)
    static let fieldBackground = Color(red: 0.08, green: 0.18, blue: 0.17)
    static let accent = Color(red: 0.28, green: 0.87, blue: 0.81)
    static let textColor = Color(red: 0.86, green: 0.96, blue: 0.94)
    static let secondaryText = Color(red: 0.78, green: 0.92, blue: 0.89)
}

struct ProductionScheduleView: View {
    @State private var resultText = "請選擇要產生的生管進度 PDF。"
    @State private var pdfUrl: String?
    @State private var isLoading = false

    private let serverBaseURL = URL(string: "https://linebot.sunwell.work/")!

    var body: some View {
        ZStack {
            ScheduleColors.pageBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title("生管進度")

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            actionButton("專案甘特圖") {
                                Task { await generateProjectGantt() }
                            }
                            actionButton("更新資料") {
                                Task { await updateData() }
                            }
                        }

                        Text("依製程產生甘特圖")
                            .font(.headline)
                            .foregroundColor(ScheduleColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            actionButton("組立") {
                                Task { await generateGantt(mode: 3, name: "組立") }
                            }
                            actionButton("配線") {
                                Task { await generateGantt(mode: 2, name: "配線") }
                            }
                        }

                        HStack(spacing: 12) {
                            actionButton("電氣測試") {
                                Task { await generateGantt(mode: 1, name: "電氣測試") }
                            }
                            actionButton("試車") {
                                Task { await generateGantt(mode: 4, name: "試車") }
                            }
                        }

                        HStack(spacing: 12) {
                            secondaryButton("開啟 PDF") {
                                openPdf()
                            }
                            .disabled(pdfUrl == nil)
                            .opacity(pdfUrl == nil ? 0.45 : 1.0)

                            secondaryButton("複製結果") {
                                UIPasteboard.general.string = resultText
                            }
                        }
                    }

                    loadingView
                    resultPanel(resultText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("生管進度")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func generateProjectGantt() async {
        isLoading = true
        pdfUrl = nil
        resultText = "產生專案甘特圖 PDF..."

        do {
            let result = try await APIClient.shared.getProjectGanttPdf()
            pdfUrl = result.pdfUrl
            resultText = pdfResultText(title: "專案甘特圖", success: result.success, message: result.message, url: result.pdfUrl)
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func generateGantt(mode: Int, name: String) async {
        isLoading = true
        pdfUrl = nil
        resultText = "產生 \(name) 甘特圖 PDF..."

        do {
            let result = try await APIClient.shared.getGanttPdf(mode: mode)
            pdfUrl = result.pdfUrl
            resultText = pdfResultText(title: name, success: result.success, message: result.message, url: result.pdfUrl)
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func updateData() async {
        isLoading = true
        pdfUrl = nil
        resultText = "更新生管排程資料..."

        do {
            let result = try await APIClient.shared.updateGeData()
            resultText = "功能: 更新資料\n成功: \(result.success ? "是" : "否")\n訊息: \(result.message ?? "")"
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func openPdf() {
        guard let text = pdfUrl, let url = resolvedURL(text, baseURL: serverBaseURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func pdfResultText(title: String, success: Bool, message: String?, url: String?) -> String {
        return "模式: \(title)\n成功: \(success ? "是" : "否")\n訊息: \(message ?? "")\n\nPDF:\n\(url ?? "")"
    }

    private var loadingView: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ScheduleColors.accent))
                    Spacer()
                }
            }
        }
    }

    private func actionButton(_ text: String, action: @escaping () -> Void) -> some View {
        scheduleActionButton(text, isLoading: isLoading, action: action)
    }

    private func secondaryButton(_ text: String, action: @escaping () -> Void) -> some View {
        scheduleSecondaryButton(text, isLoading: isLoading, action: action)
    }
}

private struct ProjectCommand {
    let command: String
    let title: String
    let isPdf: Bool
}

struct ProjectDatesView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入專案關鍵字，選擇日期報表。"
    @State private var pdfUrl: String?
    @State private var isLoading = false
    @State private var suggestions: [String] = []
    @State private var suggestMode = "start"
    @State private var suggestionTask: Task<Void, Never>?

    private let serverBaseURL = URL(string: "https://linebot.sunwell.work/")!

    private let commands = [
        ProjectCommand(command: "rpt1", title: "專案 PDF", isPdf: true),
        ProjectCommand(command: "rpt", title: "專案文字", isPdf: false),
        ProjectCommand(command: "rpte1", title: "電氣 PDF", isPdf: true),
        ProjectCommand(command: "rpte", title: "電氣文字", isPdf: false)
    ]

    var body: some View {
        ZStack {
            ScheduleColors.pageBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title("現有專案日期")

                    HStack(spacing: 12) {
                        toggleButton("開始符合", selected: suggestMode == "start") {
                            suggestMode = "start"
                            scheduleSuggestions()
                        }
                        toggleButton("任意位置", selected: suggestMode == "any") {
                            suggestMode = "any"
                            scheduleSuggestions()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("關鍵字 / 過濾")
                            .font(.headline)
                            .foregroundColor(ScheduleColors.secondaryText)

                        TextField("例如 F26003 / MT / MCS / -關鍵字", text: Binding(
                            get: { keyword },
                            set: { value in
                                keyword = value.uppercased()
                                scheduleSuggestions()
                            }
                        ))
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .font(.title2)
                            .foregroundColor(ScheduleColors.textColor)
                            .padding(16)
                            .background(ScheduleColors.fieldBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                            )
                    }

                    suggestionList

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            commandButton(commands[0])
                            commandButton(commands[1])
                        }
                        HStack(spacing: 12) {
                            commandButton(commands[2])
                            commandButton(commands[3])
                        }
                        HStack(spacing: 12) {
                            scheduleActionButton("清除", isLoading: isLoading) {
                                clear()
                            }
                            scheduleSecondaryButton("複製結果", isLoading: isLoading) {
                                UIPasteboard.general.string = resultText
                            }
                        }
                        HStack(spacing: 12) {
                            scheduleSecondaryButton("開啟 PDF", isLoading: isLoading) {
                                openPdf()
                            }
                            .disabled(pdfUrl == nil)
                            .opacity(pdfUrl == nil ? 0.45 : 1.0)
                            scheduleSecondaryButton("複製 PDF", isLoading: isLoading) {
                                UIPasteboard.general.string = pdfUrl ?? ""
                            }
                            .disabled(pdfUrl == nil)
                            .opacity(pdfUrl == nil ? 0.45 : 1.0)
                        }
                    }

                    loadingView
                    resultPanel(resultText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("現有專案日期")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            suggestionTask?.cancel()
        }
    }

    private var suggestionList: some View {
        Group {
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.prefix(8)), id: \.self) { item in
                        Button(action: {
                            keyword = item.uppercased()
                            suggestions = []
                            hideKeyboard()
                        }) {
                            HStack {
                                Text(item)
                                    .foregroundColor(ScheduleColors.textColor)
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
        }
    }

    private func commandButton(_ command: ProjectCommand) -> some View {
        scheduleActionButton(command.title, isLoading: isLoading) {
            Task { await run(command) }
        }
    }

    private func toggleButton(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(selected ? "✓ \(text)" : text)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(selected ? Color(red: 0.05, green: 0.18, blue: 0.17) : ScheduleColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(selected ? ScheduleColors.accent : ScheduleColors.fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.16, green: 0.34, blue: 0.31), lineWidth: 1.5)
                )
                .cornerRadius(24)
        }
    }

    @MainActor
    private func run(_ command: ProjectCommand) async {
        hideKeyboard()
        suggestions = []
        isLoading = true
        pdfUrl = nil
        resultText = "查詢 \(command.title)..."

        do {
            if command.isPdf {
                let result = try await APIClient.shared.getGePdf(command: command.command, keyword: keyword.trimmed)
                pdfUrl = result.pdfUrl
                resultText = "報表: \(command.title)\n成功: \(result.success ? "是" : "否")\n訊息: \(result.message ?? "")\n\nPDF:\n\(result.pdfUrl ?? "")"
            } else {
                let result = try await APIClient.shared.getGeText(command: command.command, keyword: keyword.trimmed)
                resultText = "報表: \(command.title)\n成功: \(result.success ? "是" : "否")\n\n" + (result.result ?? "")
            }
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func scheduleSuggestions() {
        suggestionTask?.cancel()

        let key = keyword.trimmed
        if key.count < 1 {
            suggestions = []
            return
        }

        let mode = suggestMode
        suggestionTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }

            do {
                let result = try await APIClient.shared.suggestProjects(keyword: key, mode: mode)
                if Task.isCancelled { return }
                await MainActor.run {
                    if keyword.trimmed == key && suggestMode == mode {
                        suggestions = result
                    }
                }
            } catch {
                await MainActor.run {
                    if keyword.trimmed == key && suggestMode == mode {
                        suggestions = []
                    }
                }
            }
        }
    }

    private func openPdf() {
        guard let text = pdfUrl, let url = resolvedURL(text, baseURL: serverBaseURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func clear() {
        keyword = ""
        suggestions = []
        pdfUrl = nil
        resultText = "請輸入專案關鍵字，選擇日期報表。"
        hideKeyboard()
    }

    private var loadingView: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ScheduleColors.accent))
                    Spacer()
                }
            }
        }
    }
}

struct AiProductionScheduleView: View {
    @State private var question = ""
    @State private var resultText = "選擇或輸入問題，然後按 ASK。"
    @State private var isLoading = false

    private let presets = [
        "FZ023 目前進度如何？",
        "哪些專案快到交期？",
        "請列出生管進度落後的專案。",
        "請查詢 MCS 專案目前排程。",
        "請整理本週需要注意的生管項目。"
    ]

    var body: some View {
        ZStack {
            ScheduleColors.pageBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    title("AI生管進度")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("預設問題")
                            .font(.headline)
                            .foregroundColor(ScheduleColors.secondaryText)

                        ForEach(presets, id: \.self) { item in
                            Button(action: {
                                question = item
                                hideKeyboard()
                            }) {
                                Text(item)
                                    .font(.body)
                                    .foregroundColor(ScheduleColors.textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(ScheduleColors.panelBackground)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                            .foregroundColor(ScheduleColors.secondaryText)

                        TextEditor(text: $question)
                            .font(.title3)
                            .foregroundColor(ScheduleColors.textColor)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(ScheduleColors.fieldBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                            )
                    }

                    HStack(spacing: 12) {
                        scheduleActionButton("ASK Gemini", isLoading: isLoading) {
                            Task { await ask(command: "geg", title: "Gemini") }
                        }
                        scheduleActionButton("ASK ChatGPT", isLoading: isLoading) {
                            Task { await ask(command: "ge", title: "ChatGPT") }
                        }
                    }

                    HStack(spacing: 12) {
                        scheduleActionButton("清除", isLoading: isLoading) {
                            clear()
                        }
                        scheduleSecondaryButton("複製", isLoading: isLoading) {
                            UIPasteboard.general.string = resultText
                        }
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ScheduleColors.accent))
                            Spacer()
                        }
                    }

                    resultPanel(resultText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("AI生管進度")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func ask(command: String, title: String) async {
        let key = question.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入問題。"
            return
        }

        hideKeyboard()
        isLoading = true
        resultText = "詢問 \(title)..."

        do {
            let result = try await APIClient.shared.askScheduleAi(command: command, question: key)
            resultText = "Command: \(result.command ?? command)\nSuccess: \(result.success ? "true" : "false")\n\n" + (result.answer ?? "")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func clear() {
        question = ""
        resultText = "選擇或輸入問題，然後按 ASK。"
        hideKeyboard()
    }
}

private func title(_ text: String) -> some View {
    Text(text)
        .font(.largeTitle)
        .fontWeight(.semibold)
        .foregroundColor(ScheduleColors.textColor)
        .padding(.top, 18)
}

private func resultPanel(_ text: String) -> some View {
    VStack(alignment: .leading, spacing: 0) {
        ScrollView(.vertical) {
            Text(text)
                .font(.system(size: 18, weight: .regular, design: .monospaced))
                .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(18)
        }
    }
    .frame(minHeight: 160)
    .background(ScheduleColors.panelBackground)
    .cornerRadius(14)
}

private func scheduleActionButton(_ text: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.70)
            .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(ScheduleColors.accent)
            .cornerRadius(28)
    }
    .disabled(isLoading)
    .opacity(isLoading ? 0.65 : 1.0)
}

private func scheduleSecondaryButton(_ text: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(text)
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundColor(ScheduleColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 0.16, green: 0.34, blue: 0.31), lineWidth: 1.5)
            )
    }
    .disabled(isLoading)
}

private func resolvedURL(_ text: String, baseURL: URL) -> URL? {
    let value = text.trimmed
    if let url = URL(string: value), url.scheme != nil {
        return url
    }

    if value.hasPrefix("/") {
        let path = String(value.dropFirst())
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }

    return URL(string: value, relativeTo: baseURL)?.absoluteURL
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

private func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
