import SwiftUI
import UIKit

private enum OrderSearchMode: String {
    case all = "ALL"
    case summary = "O"
    case salesNo = "A"
    case nameplate = "S"

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .summary:
            return "彙整表"
        case .salesNo:
            return "業務號"
        case .nameplate:
            return "銘牌"
        }
    }
}

struct OrderSearchView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入關鍵字，選擇搜尋方式。"
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    @State private var suggestionTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.14, blue: 0.13)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("訂單資料查詢")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.86, green: 0.96, blue: 0.94))
                        .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("關鍵字")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                        TextField("例如：F26030 / SWO113026 / SWM1150 / 客戶", text: Binding(
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

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            actionButton("Oracle") {
                                Task { await searchOracle() }
                            }
                            actionButton("彙整表") {
                                Task { await searchOrder(.summary) }
                            }
                        }

                        HStack(spacing: 12) {
                            actionButton("業務號") {
                                Task { await searchOrder(.salesNo) }
                            }
                            actionButton("銘牌") {
                                Task { await searchOrder(.nameplate) }
                            }
                        }

                        HStack(spacing: 12) {
                            actionButton("清除") {
                                clear()
                            }
                            actionButton("複製結果") {
                                UIPasteboard.general.string = resultText
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
                    .frame(minHeight: 320)
                    .background(Color(red: 0.11, green: 0.24, blue: 0.22))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("訂單資料查詢")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            suggestionTask?.cancel()
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color(red: 0.28, green: 0.87, blue: 0.81))
                .cornerRadius(28)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.65 : 1.0)
    }

    private func scheduleSuggestions() {
        suggestionTask?.cancel()

        let key = keyword.trimmed
        if key.count < 2 {
            suggestions = []
            return
        }

        suggestionTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }

            do {
                let result = try await APIClient.shared.suggestOrders(keyword: key)
                if Task.isCancelled { return }

                await MainActor.run {
                    if keyword.trimmed == key {
                        suggestions = result
                    }
                }
            } catch {
                await MainActor.run {
                    if keyword.trimmed == key {
                        suggestions = []
                    }
                }
            }
        }
    }

    @MainActor
    private func searchOrder(_ mode: OrderSearchMode) async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入關鍵字。"
            return
        }

        hideKeyboard()
        suggestions = []
        isLoading = true
        resultText = "搜尋中..."

        do {
            let result: OrderDto
            if mode == .all {
                result = try await APIClient.shared.getOrder(orderNo: key)
            } else {
                result = try await APIClient.shared.searchOrder(mode: mode.rawValue, keyword: key)
            }

            resultText = "搜尋類型: \(mode.title)\n" +
                "關鍵字: \(result.orderNo.isEmpty ? key : result.orderNo)\n\n" +
                (result.result ?? "")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func searchOracle() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入關鍵字。"
            return
        }

        hideKeyboard()
        suggestions = []
        isLoading = true
        resultText = "搜尋 Oracle..."

        do {
            let result = try await APIClient.shared.searchOracleOrder(keyword: key)
            resultText = formatOracleResult(result, keyword: key)
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func clear() {
        suggestionTask?.cancel()
        keyword = ""
        suggestions = []
        resultText = "請輸入關鍵字，選擇搜尋方式。"
        hideKeyboard()
    }

    private func formatOracleResult(_ result: OracleSearchResponse, keyword: String) -> String {
        let success = result.success ?? false
        let resultKeyword = result.keyword ?? keyword
        let count = result.count ?? 0

        if !success {
            return "搜尋類型: Oracle\n" +
                "關鍵字: \(resultKeyword)\n\n" +
                "Oracle 搜尋失敗:\n\(result.error ?? "未知錯誤")"
        }

        let cards = result.cards ?? []
        if cards.isEmpty {
            return "搜尋類型: Oracle\n" +
                "關鍵字: \(resultKeyword)\n" +
                "筆數: \(count)\n\n" +
                "查無資料。"
        }

        var text = "搜尋類型: Oracle\n"
        text += "關鍵字: \(resultKeyword)\n"
        text += "筆數: \(count)\n\n"

        for index in cards.indices {
            let card = cards[index]
            text += "========== \(index + 1) ==========\n"

            if let title = card.title, !title.isEmpty {
                text += "\(title)\n"
            }

            if let subtitle = card.subtitle, !subtitle.isEmpty {
                text += "\(subtitle)\n"
            }

            let badges = card.badges ?? []
            if !badges.isEmpty {
                text += badges.joined(separator: " / ") + "\n"
            }

            for row in card.rows ?? [] {
                let label = row.label ?? ""
                let value = row.value ?? ""

                if !label.isEmpty || !value.isEmpty {
                    if value.contains("\n") {
                        text += "\(label):\n\(value)\n"
                    } else {
                        text += "\(label): \(value)\n"
                    }
                }
            }

            text += "\n"
        }

        return text
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
}


