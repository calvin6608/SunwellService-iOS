import SwiftUI
import UIKit

struct ServiceRecordSearchView: View {
    @State private var keyword = ""
    @State private var records: [ServiceRecordDto] = []
    @State private var resultText = "請輸入客戶、機號或問題關鍵字。"
    @State private var isLoading = false

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
                    Text("服務紀錄查詢")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .padding(.top, 18)

                    searchField

                    HStack(spacing: 12) {
                        actionButton("搜尋") {
                            Task { await search() }
                        }
                        actionButton("清除") {
                            clear()
                        }
                    }

                    HStack(spacing: 12) {
                        secondaryButton("複製結果") {
                            UIPasteboard.general.string = resultText
                        }
                        secondaryButton("複製關鍵字") {
                            UIPasteboard.general.string = keyword
                        }
                        .disabled(keyword.trimmed.isEmpty)
                        .opacity(keyword.trimmed.isEmpty ? 0.45 : 1.0)
                    }

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: accent))
                            Spacer()
                        }
                    }

                    summaryPanel

                    if !records.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("搜尋結果")
                                .font(.title2.weight(.bold))
                                .foregroundColor(textColor)

                            ForEach(records) { record in
                                recordCard(record)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("服務紀錄查詢")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("關鍵字")
                .font(.headline)
                .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

            TextField("客戶 / 機號 / 問題", text: $keyword)
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

    private var summaryPanel: some View {
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
        .frame(minHeight: 150)
        .background(panelBackground)
        .cornerRadius(14)
    }

    private func recordCard(_ record: ServiceRecordDto) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nonEmpty(record.customer, fallback: "未填客戶"))
                        .font(.headline)
                        .foregroundColor(textColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.80)

                    Text(nonEmpty(record.machineNo, fallback: "未填機號"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(red: 0.63, green: 0.86, blue: 0.82))
                }

                Spacer()

                Text(nonEmpty(record.date, fallback: "-"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(red: 0.68, green: 0.82, blue: 0.79))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.08, green: 0.18, blue: 0.17))
                    .cornerRadius(12)
            }

            if let issue = clean(record.issue), !issue.isEmpty {
                infoBlock(title: "問題", value: issue)
            }

            if let solution = clean(record.solution), !solution.isEmpty {
                infoBlock(title: "處理", value: solution)
            }
        }
        .padding(14)
        .background(panelBackground)
        .cornerRadius(14)
    }

    private func infoBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(Color(red: 0.55, green: 0.76, blue: 0.72))

            Text(value)
                .font(.body)
                .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
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
            records = []
            return
        }

        hideKeyboard()
        isLoading = true
        records = []
        resultText = "搜尋服務紀錄..."

        do {
            let result = try await APIClient.shared.searchServiceRecords(keyword: key)
            records = result
            resultText = formatResult(result, keyword: key)
        } catch {
            records = []
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        records = []
        resultText = "請輸入客戶、機號或問題關鍵字。"
        hideKeyboard()
    }

    private func formatResult(_ records: [ServiceRecordDto], keyword: String) -> String {
        if records.isEmpty {
            return "關鍵字: \(keyword)\n\n找不到服務紀錄。"
        }

        let countText = "關鍵字: \(keyword)\n找到 \(records.count) 筆服務紀錄\n\n"
        let detailText = records.map { record in
            "日期: \(record.date ?? "")\n" +
                "客戶: \(record.customer ?? "")\n" +
                "機號: \(record.machineNo ?? "")\n" +
                "問題: \(record.issue ?? "")\n" +
                "處理: \(record.solution ?? "")"
        }.joined(separator: "\n\n------------------------------\n\n")

        return countText + detailText
    }

    private func clean(_ value: String?) -> String? {
        guard let value = value else {
            return nil
        }

        let cleaned = value.trimmed
        return cleaned.isEmpty ? nil : cleaned
    }

    private func nonEmpty(_ value: String?, fallback: String) -> String {
        if let cleaned = clean(value) {
            return cleaned
        }
        return fallback
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
