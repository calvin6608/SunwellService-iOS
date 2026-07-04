import SwiftUI
import UIKit

private struct ElectricalColors {
    static let pageBackground = Color(red: 0.07, green: 0.14, blue: 0.13)
    static let panelBackground = Color(red: 0.11, green: 0.24, blue: 0.22)
    static let fieldBackground = Color(red: 0.08, green: 0.18, blue: 0.17)
    static let accent = Color(red: 0.28, green: 0.87, blue: 0.81)
    static let textColor = Color(red: 0.86, green: 0.96, blue: 0.94)
    static let secondaryText = Color(red: 0.78, green: 0.92, blue: 0.89)
}

struct BomPurchaseSearchView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入關鍵字並按搜尋。"
    @State private var isLoading = false

    var body: some View {
        electricalSearchShell(
            title: "電氣請購明細",
            fieldTitle: "關鍵字",
            placeholder: "例如 FL119 YASKAWA",
            keyword: $keyword,
            resultText: resultText,
            isLoading: isLoading,
            onSearch: { Task { await search() } },
            onClear: { clear() }
        )
        .navigationTitle("電氣請購明細")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func search() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入關鍵字。"
            return
        }

        electricalHideKeyboard()
        isLoading = true
        resultText = "搜尋電氣請購明細..."

        do {
            let result = try await APIClient.shared.searchBomPurchase(keyword: key)
            resultText = "成功: \(result.success ? "是" : "否")\n" +
                "關鍵字: \(result.keyword)\n\n" +
                (result.result ?? "")
        } catch {
            resultText = electricalErrorText(error)
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        resultText = "請輸入關鍵字並按搜尋。"
        electricalHideKeyboard()
    }
}

struct ElectEcSearchView: View {
    @State private var keyword = ""
    @State private var resultText = "請輸入生產批號並按搜尋。"
    @State private var isLoading = false

    var body: some View {
        electricalSearchShell(
            title: "-EC 料號查詢",
            fieldTitle: "生產批號",
            placeholder: "例如 FZ060",
            keyword: $keyword,
            resultText: resultText,
            isLoading: isLoading,
            onSearch: { Task { await search() } },
            onClear: { clear() }
        )
        .navigationTitle("-EC 料號查詢")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func search() async {
        let key = keyword.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入生產批號。"
            return
        }

        electricalHideKeyboard()
        isLoading = true
        resultText = "搜尋 -EC 料號..."

        do {
            let result = try await APIClient.shared.searchElectEc(keyword: key)
            resultText = "成功: \(result.success ? "是" : "否")\n" +
                "生產批號: \(result.keyword)\n\n" +
                (result.result ?? "")
        } catch {
            resultText = electricalErrorText(error)
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        resultText = "請輸入生產批號並按搜尋。"
        electricalHideKeyboard()
    }
}

private func electricalSearchShell(
    title: String,
    fieldTitle: String,
    placeholder: String,
    keyword: Binding<String>,
    resultText: String,
    isLoading: Bool,
    onSearch: @escaping () -> Void,
    onClear: @escaping () -> Void
) -> some View {
    ZStack {
        ElectricalColors.pageBackground
            .edgesIgnoringSafeArea(.all)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(ElectricalColors.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 8) {
                    Text(fieldTitle)
                        .font(.headline)
                        .foregroundColor(ElectricalColors.secondaryText)

                    TextField(placeholder, text: Binding(
                        get: { keyword.wrappedValue },
                        set: { value in keyword.wrappedValue = value.uppercased() }
                    ))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.title2)
                        .foregroundColor(ElectricalColors.textColor)
                        .padding(16)
                        .background(ElectricalColors.fieldBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                        )
                }

                HStack(spacing: 12) {
                    electricalActionButton("搜尋", isLoading: isLoading, action: onSearch)
                    electricalActionButton("清除", isLoading: isLoading, action: onClear)
                }

                electricalSecondaryButton("複製結果", isLoading: isLoading) {
                    UIPasteboard.general.string = resultText
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ElectricalColors.accent))
                        Spacer()
                    }
                }

                electricalResultPanel(resultText)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }
}

private func electricalActionButton(_ text: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.70)
            .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(ElectricalColors.accent)
            .cornerRadius(28)
    }
    .disabled(isLoading)
    .opacity(isLoading ? 0.65 : 1.0)
}

private func electricalSecondaryButton(_ text: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(text)
            .font(.headline)
            .foregroundColor(ElectricalColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(red: 0.16, green: 0.34, blue: 0.31), lineWidth: 1.5)
            )
    }
    .disabled(isLoading)
}

private func electricalResultPanel(_ text: String) -> some View {
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
    .frame(minHeight: 260)
    .background(ElectricalColors.panelBackground)
    .cornerRadius(14)
}

private func electricalErrorText(_ error: Error) -> String {
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

private func electricalHideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
