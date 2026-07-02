import SwiftUI
import UIKit

struct ErpSearchView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var partNo = ""
    @State private var resultText = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.14, blue: 0.13)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("ERP")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.86, green: 0.96, blue: 0.94))
                        .padding(.top, 18)

                    HStack(spacing: 16) {
                        actionButton("返回") {
                            presentationMode.wrappedValue.dismiss()
                        }

                        secondaryButton("清除") {
                            clear()
                        }
                    }

                    TextField("零件料號", text: Binding(
                        get: { partNo },
                        set: { partNo = $0.uppercased() }
                    ))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .font(.title2)
                        .foregroundColor(Color(red: 0.88, green: 0.96, blue: 0.94))
                        .padding(18)
                        .background(Color(red: 0.08, green: 0.18, blue: 0.17))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.38, green: 0.93, blue: 0.88), lineWidth: 1.5)
                        )

                    actionButton(isLoading ? "查詢中..." : "庫存異動") {
                        Task { await searchStockChange() }
                    }
                    .disabled(isLoading || partNo.trimmed.isEmpty)
                    .opacity((isLoading || partNo.trimmed.isEmpty) ? 0.55 : 1.0)

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
        .navigationTitle("ERP")
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
        .frame(minHeight: 520)
        .background(Color(red: 0.11, green: 0.24, blue: 0.22))
        .cornerRadius(14)
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
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color(red: 0.16, green: 0.34, blue: 0.31), lineWidth: 1.5)
                )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.55 : 1.0)
    }

    @MainActor
    private func searchStockChange() async {
        let key = partNo.trimmed
        guard !key.isEmpty else {
            resultText = "請輸入零件料號。"
            return
        }

        hideKeyboard()
        isLoading = true
        resultText = "正在查詢庫存異動..."

        do {
            let response = try await APIClient.shared.getErpStockChange(partNo: key)
            resultText = formatResponse(response)
        } catch {
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func formatResponse(_ response: ErpStockChangeResponse) -> String {
        if !response.success {
            return response.message.isEmpty ? "庫存異動查詢失敗" : response.message
        }

        var text = "查詢料號: \(response.partNo)\n"
        text += "異動筆數: \(response.count)\n\n"

        if response.items.isEmpty {
            text += "查無庫存異動資料\n"
            return text
        }

        for index in response.items.indices {
            let item = response.items[index]
            text += "──────── \(index + 1) ────────\n"
            text += "單據: \(item.documentNo)\n"
            text += "生產工令: \(item.salesNo)\n"
            text += "料號: \(item.partNo)\n"
            text += "時間: \(item.changeTime)\n"
            text += "\(item.documentType)  \(item.direction)  \(formatQuantity(item.quantity))\n"

            if let plan = item.planMaster {
                text += "\n生產計劃主檔資料\n"

                if let numCase = plan.numCase, !numCase.isEmpty {
                    text += "案號: \(numCase)\n"
                }
                if let codItem = plan.codItem, !codItem.isEmpty {
                    text += "主件料號: \(codItem)\n"
                }
                if let namItem = plan.namItem, !namItem.isEmpty {
                    text += "品名: \(namItem)\n"
                }
                if let qty = plan.qtyPcs {
                    text += "計劃數量: \(formatQuantity(qty))\n"
                }
                if let dateOrder = plan.dateOrder, !dateOrder.isEmpty {
                    text += "訂單日期: \(formatDate(dateOrder))\n"
                }
                if let datePlanEnd = plan.datePlanEnd, !datePlanEnd.isEmpty {
                    text += "計劃完成日: \(formatDate(datePlanEnd))\n"
                }
                if let dateClose = plan.dateClose, !dateClose.isEmpty {
                    text += "結案日期: \(formatDate(dateClose))\n"
                }
                if let statusCode = plan.statusCode, !statusCode.isEmpty {
                    text += "狀態碼: \(statusCode)\n"
                }
                if let spec = plan.spec, !spec.isEmpty {
                    text += "規格: \(spec)\n"
                }
            } else if !item.salesNo.isEmpty {
                text += "\n生產工令主檔: 查無對應資料\n"
            }

            text += "\n"
        }

        return text
    }

    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return String(Int64(value))
        }

        return String(value)
    }

    private func formatDate(_ value: String?) -> String {
        let text = value?.trimmed ?? ""
        let isEightDigitDate = text.count == 8 && text.allSatisfy { $0 >= "0" && $0 <= "9" }

        if isEightDigitDate {
            let year = String(text.prefix(4))
            let monthStart = text.index(text.startIndex, offsetBy: 4)
            let monthEnd = text.index(text.startIndex, offsetBy: 6)
            let dayStart = monthEnd
            let month = String(text[monthStart..<monthEnd])
            let day = String(text[dayStart..<text.endIndex])
            return "\(year)-\(month)-\(day)"
        }

        return text
    }

    private func clear() {
        partNo = ""
        resultText = ""
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
                return "庫存異動查詢錯誤: HTTP \(status)\n\(message)"
            default:
                return apiError.localizedDescription
            }
        }

        return "庫存異動查詢錯誤：\(error.localizedDescription)"
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
