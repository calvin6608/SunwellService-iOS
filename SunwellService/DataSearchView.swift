import SwiftUI
import UIKit

private struct DataSourceCommand {
    let command: String
    let title: String
}

struct DataSearchView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入關鍵字並選擇資料來源"
    @State private var isLoading = false

    private let rows: [[DataSourceCommand]] = [
        [
            DataSourceCommand(command: "lay", title: "配置圖"),
            DataSourceCommand(command: "svc", title: "裝機服務")
        ],
        [
            DataSourceCommand(command: "sch", title: "電氣資料"),
            DataSourceCommand(command: "man", title: "手冊")
        ],
        [
            DataSourceCommand(command: "con", title: "合約"),
            DataSourceCommand(command: "cat", title: "型錄")
        ],
        [
            DataSourceCommand(command: "ec", title: "設計變更"),
            DataSourceCommand(command: "hr", title: "人事分享區")
        ],
        [
            DataSourceCommand(command: "tst", title: "試機檔案"),
            DataSourceCommand(command: "trl", title: "試機問題")
        ],
        [
            DataSourceCommand(command: "trn", title: "教育訓練"),
            DataSourceCommand(command: "clear", title: "清除")
        ]
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.14, blue: 0.13)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("資料查詢")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.86, green: 0.96, blue: 0.94))
                        .padding(.top, 18)

                    TextField("關鍵字", text: $keyword)
                        .disableAutocorrection(true)
                        .font(.title2)
                        .foregroundColor(Color(red: 0.88, green: 0.96, blue: 0.94))
                        .padding(18)
                        .background(Color(red: 0.08, green: 0.18, blue: 0.17))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                        )

                    VStack(spacing: 14) {
                        ForEach(0..<rows.count, id: \.self) { rowIndex in
                            HStack(spacing: 16) {
                                ForEach(0..<rows[rowIndex].count, id: \.self) { columnIndex in
                                    let item = rows[rowIndex][columnIndex]
                                    dataButton(item.title) {
                                        if item.command == "clear" {
                                            clear()
                                        } else {
                                            Task { await search(item) }
                                        }
                                    }
                                }
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
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("資料查詢")
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
        .frame(minHeight: 120)
        .background(Color(red: 0.11, green: 0.24, blue: 0.22))
        .cornerRadius(14)
    }

    private func dataButton(_ title: String, action: @escaping () -> Void) -> some View {
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

    @MainActor
    private func search(_ source: DataSourceCommand) async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入關鍵字。"
            return
        }

        hideKeyboard()
        isLoading = true
        resultText = "搜尋 \(source.title)..."

        do {
            let result = try await APIClient.shared.dataSearch(command: source.command, keyword: key)
            resultText = "資料來源: \(source.title)\n" +
                "關鍵字: \(result.keyword)\n" +
                "成功: \(result.success ? "是" : "否")\n\n" +
                (result.result ?? "")
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        resultText = "請輸入關鍵字並選擇資料來源"
        hideKeyboard()
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
