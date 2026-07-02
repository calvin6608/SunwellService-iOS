import SwiftUI
import UIKit

private enum PartSuggestMode: String {
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

private struct PartFileLink {
    let title: String
    let url: String
}

struct PartSearchView: View {
    @State private var keyword = ""
    @State private var suggestMode: PartSuggestMode = .start
    @State private var suggestions: [String] = []
    @State private var resultText = "請輸入料號或品名並按搜尋。"
    @State private var imageUrl: String?
    @State private var fileLink: PartFileLink?
    @State private var isLoading = false
    @State private var suggestionTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.14, blue: 0.13)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("零件 / BOM 查詢")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.86, green: 0.96, blue: 0.94))
                        .padding(.top, 18)

                    HStack(spacing: 12) {
                        modeButton(.start)
                        modeButton(.any)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("料號 / 品名")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                        TextField("料號 / 品名", text: Binding(
                            get: { keyword },
                            set: { value in
                                keyword = value.uppercased()
                                scheduleSuggestions()
                            }
                        ))
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .font(.title2)
                            .foregroundColor(Color(red: 0.88, green: 0.96, blue: 0.94))
                            .padding(16)
                            .background(Color(red: 0.08, green: 0.18, blue: 0.17))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                            )
                    }

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
                                            .foregroundColor(Color(red: 0.88, green: 0.96, blue: 0.94))
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

                    HStack(spacing: 12) {
                        secondaryButton("貼上") {
                            if let text = UIPasteboard.general.string, !text.trimmed.isEmpty {
                                keyword = text.trimmed.uppercased()
                                suggestions = []
                                hideKeyboard()
                            }
                        }

                        secondaryButton("複製") {
                            UIPasteboard.general.string = keyword.trimmed
                        }
                        .disabled(keyword.trimmed.isEmpty)
                        .opacity(keyword.trimmed.isEmpty ? 0.45 : 1.0)

                        actionButton("搜尋") {
                            Task { await searchPart() }
                        }

                        actionButton("清除") {
                            clear()
                        }
                    }

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            actionButton("CAD 圖片") {
                                Task { await searchImage() }
                            }
                            actionButton("Creo 參數") {
                                Task { await searchPnc() }
                            }
                        }

                        HStack(spacing: 8) {
                            smallActionButton("ERP BOM") {
                                Task { await searchBom(isUp: false) }
                            }
                            smallActionButton("Creo BOM") {
                                Task { await searchCreoBom() }
                            }
                            smallActionButton("上階 BOM") {
                                Task { await searchBom(isUp: true) }
                            }
                        }

                        HStack(spacing: 8) {
                            smallActionButton("父階清單") {
                                Task { await searchBtm(mode: 1) }
                            }
                            smallActionButton("略過節點") {
                                Task { await searchBtm(mode: 2) }
                            }
                            smallActionButton("真實用量") {
                                Task { await searchBtm(mode: 3) }
                            }
                        }

                        HStack(spacing: 8) {
                            actionButton("常用五金(手冊用)") {
                                Task { await searchBtm(mode: 4) }
                            }
                            actionButton("五金 + 料號過濾 (手冊)") {
                                Task { await searchBtm(mode: 5) }
                            }
                        }
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.31, green: 0.90, blue: 0.84)))
                            Spacer()
                        }
                    }

                    resultPanel

                    if let imageUrl = imageUrl, !imageUrl.isEmpty {
                        imagePanel(imageUrl)
                    }

                    if let fileLink = fileLink, !fileLink.url.isEmpty {
                        filePanel(fileLink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("零件 / BOM 查詢")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            suggestionTask?.cancel()
        }
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
        .background(Color(red: 0.11, green: 0.24, blue: 0.22))
        .cornerRadius(14)
    }

    private func imagePanel(_ urlText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: urlText)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 160)
            }
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)

            HStack(spacing: 12) {
                actionButton("開啟圖片") {
                    openURL(urlText)
                }
                actionButton("複製連結") {
                    UIPasteboard.general.string = urlText
                }
            }
        }
    }

    private func filePanel(_ link: PartFileLink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(link.title)
                .font(.headline)
                .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))

            HStack(spacing: 12) {
                actionButton("開啟 PDF") {
                    openURL(link.url)
                }
                actionButton("複製連結") {
                    UIPasteboard.general.string = link.url
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.11, green: 0.24, blue: 0.22))
        .cornerRadius(14)
    }

    private func modeButton(_ mode: PartSuggestMode) -> some View {
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
                .background(Color(red: 0.28, green: 0.87, blue: 0.81))
                .cornerRadius(28)
        }
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
                .background(Color(red: 0.28, green: 0.87, blue: 0.81))
                .cornerRadius(28)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.65 : 1.0)
    }

    private func smallActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.28, green: 0.87, blue: 0.81))
                .cornerRadius(24)
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

        let key = keyword.trimmed
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
                let result = try await APIClient.shared.suggestParts(keyword: key, mode: mode)
                if Task.isCancelled { return }

                await MainActor.run {
                    if keyword.trimmed == key && suggestMode.rawValue == mode {
                        suggestions = result
                    }
                }
            } catch {
                await MainActor.run {
                    if keyword.trimmed == key && suggestMode.rawValue == mode {
                        suggestions = []
                    }
                }
            }
        }
    }

    @MainActor
    private func searchPart() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired()
            return
        }

        beginSearch("搜尋零件...")

        do {
            let result = try await APIClient.shared.getPart(keyword: key, includeImage: false, mode: suggestMode.rawValue)
            let searchMode = result.isPartNumber == true ? "料號搜尋" : "品名搜尋"
            resultText = "關鍵字: \(result.partNo)\n" +
                "模式: \(searchMode)\n\n" +
                (result.name ?? "")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchImage() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired(partOnly: true)
            return
        }

        beginSearch("搜尋 CAD 圖片...")

        do {
            let result = try await APIClient.shared.getImage(partNo: key)
            resultText = "料號: \(result.partNo)\n" +
                "成功: \(yesNo(result.success))\n" +
                "訊息: \(translateServerMessage(result.message))"
            imageUrl = result.imageUrl
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchPnc() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired(partOnly: true)
            return
        }

        beginSearch("查詢 Creo 參數...")

        do {
            let result = try await APIClient.shared.getPnc(partNo: key)
            resultText = "料號: \(result.partNo)\n" +
                "成功: \(yesNo(result.success))\n" +
                "訊息: \(translateServerMessage(result.message))\n\n" +
                (result.result ?? "")
            imageUrl = result.imageUrl
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchCreoBom() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired(partOnly: true)
            return
        }

        beginSearch("產生 Creo BOM PDF...\n可能需要一段時間。")

        do {
            let result = try await APIClient.shared.getCreoBom(partNo: key)
            resultText = "料號: \(result.partNo)\n" +
                "成功: \(yesNo(result.success))\n" +
                "訊息: \(translateServerMessage(result.message))"

            if let pdfUrl = result.pdfUrl, !pdfUrl.isEmpty {
                fileLink = PartFileLink(title: "Creo BOM PDF", url: pdfUrl)
            }
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchBom(isUp: Bool) async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired(partOnly: true)
            return
        }

        beginSearch(isUp ? "搜尋上階 BOM..." : "搜尋 ERP BOM...")

        do {
            let result: BomDto
            if isUp {
                result = try await APIClient.shared.getBomUp(partNo: key)
            } else {
                result = try await APIClient.shared.getBomDown(partNo: key)
            }

            let title = result.direction.lowercased() == "up" ? "上階 BOM / 使用處" : "ERP BOM / 下階零件"
            resultText = title + "\n" +
                "料號: \(result.partNo)\n\n" +
                result.paths.joined(separator: "\n")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchBtm(mode: Int) async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            showInputRequired(partOnly: true)
            return
        }

        beginSearch("執行 \(btmModeName(mode))...")

        do {
            let result = try await APIClient.shared.getBtm(mode: mode, partNo: key)
            resultText = "料號: \(result.partNo)\n" +
                "模式: \(btmModeName(mode))\n" +
                "成功: \(yesNo(result.success))\n\n" +
                (result.result ?? "")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func beginSearch(_ text: String) {
        hideKeyboard()
        suggestions = []
        imageUrl = nil
        fileLink = nil
        isLoading = true
        resultText = text
    }

    private func showInputRequired(partOnly: Bool = false) {
        resultText = partOnly ? "請輸入料號。" : "請輸入料號或品名。"
        imageUrl = nil
        fileLink = nil
    }

    private func clear() {
        suggestionTask?.cancel()
        keyword = ""
        suggestions = []
        imageUrl = nil
        fileLink = nil
        resultText = "請輸入料號或品名並按搜尋。"
        hideKeyboard()
    }

    private func btmModeName(_ mode: Int) -> String {
        switch mode {
        case 1:
            return "父階清單"
        case 2:
            return "略過節點"
        case 3:
            return "真實用量"
        case 4:
            return "常用五金"
        case 5:
            return "五金 + 料號過濾"
        default:
            return "BTM\(mode)"
        }
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

    private func yesNo(_ value: Bool) -> String {
        return value ? "是" : "否"
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

    private func openURL(_ urlText: String) {
        guard let url = URL(string: urlText) else { return }
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

