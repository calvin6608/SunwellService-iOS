import SwiftUI
import UIKit

private enum RemoteServiceSortMode: String, CaseIterable {
    case caseId
    case openDate
    case status
    case problem

    var title: String {
        switch self {
        case .caseId:
            return "Case ID"
        case .openDate:
            return "Open Date"
        case .status:
            return "Status"
        case .problem:
            return "Problem"
        }
    }
}

struct RemoteServiceRecordView: View {
    @State private var keyword = ""
    @State private var cases: [RemoteServiceCaseDto] = []
    @State private var selectedCase: RemoteServiceCaseDto?
    @State private var resultText = "Input keyword and press Search"
    @State private var isLoading = false
    @State private var sortMode: RemoteServiceSortMode = .caseId

    private let pageBackground = Color(red: 0.07, green: 0.14, blue: 0.13)
    private let panelBackground = Color(red: 0.11, green: 0.24, blue: 0.22)
    private let fieldBackground = Color(red: 0.04, green: 0.12, blue: 0.11)
    private let accent = Color(red: 0.28, green: 0.87, blue: 0.81)
    private let textColor = Color(red: 0.86, green: 0.96, blue: 0.94)

    private var sortedCases: [RemoteServiceCaseDto] {
        switch sortMode {
        case .caseId:
            return cases.sorted { $0.id > $1.id }
        case .openDate:
            return cases.sorted {
                if ($0.openDate ?? "") == ($1.openDate ?? "") {
                    return $0.id > $1.id
                }
                return ($0.openDate ?? "") > ($1.openDate ?? "")
            }
        case .status:
            return cases.sorted {
                if ($0.status ?? "") == ($1.status ?? "") {
                    return $0.id > $1.id
                }
                return ($0.status ?? "") < ($1.status ?? "")
            }
        case .problem:
            return cases.sorted {
                if ($0.problemCategory ?? "") == ($1.problemCategory ?? "") {
                    return $0.id > $1.id
                }
                return ($0.problemCategory ?? "") < ($1.problemCategory ?? "")
            }
        }
    }

    var body: some View {
        ZStack {
            pageBackground
                .edgesIgnoringSafeArea(.all)

            if let item = selectedCase {
                detailContent(item)
            } else {
                listContent
            }
        }
        .navigationTitle("遠端服務紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cases.isEmpty && resultText == "Input keyword and press Search" {
                Task { await search() }
            }
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    Text("遠端服務紀錄")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer()
                }
                .padding(.top, 18)

                searchField

                HStack(spacing: 12) {
                    actionButton("Search") {
                        Task { await search() }
                    }
                    actionButton("Clear") {
                        clear()
                    }
                }

                Text("Sort by")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

                sortButtons

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: accent))
                        Spacer()
                    }
                }

                resultPanel

                ForEach(sortedCases) { item in
                    Button(action: {
                        Task { await openCase(item) }
                    }) {
                        caseCard(item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search keyword")
                .font(.headline)
                .foregroundColor(Color(red: 0.78, green: 0.92, blue: 0.89))

            TextField("Customer / SalesNo / Model / Issue", text: $keyword)
                .autocapitalization(.words)
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

    private var sortButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                sortButton(.caseId)
                sortButton(.openDate)
            }
            HStack(spacing: 12) {
                sortButton(.status)
                sortButton(.problem)
            }
        }
    }

    private var resultPanel: some View {
        Text(resultText)
            .font(.system(size: 18, weight: .regular, design: .monospaced))
            .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(18)
            .background(panelBackground)
            .cornerRadius(14)
    }

    private func caseCard(_ item: RemoteServiceCaseDto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Case #\(caseNumberText(item))  \(nonEmpty(item.customer, fallback: ""))")
                .font(.title2.weight(.bold))
                .foregroundColor(textColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            fieldLine("SalesNo", item.salesNo)
            fieldLine("Model", item.model)
            fieldLine("OpenDate", item.openDate)
            fieldLine("Problem", item.problemCategory)
            fieldLine("Status", statusText(item))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(panelBackground)
        .cornerRadius(14)
    }

    private func detailContent(_ item: RemoteServiceCaseDto) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Case #\(caseNumberText(item))")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                    .padding(.top, 18)

                HStack(spacing: 12) {
                    actionButton("Back") {
                        selectedCase = nil
                    }
                    actionButton("Copy") {
                        UIPasteboard.general.string = formatCaseDetail(item)
                    }
                }

                Text(formatCaseDetail(item))
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(18)
                    .background(panelBackground)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(Color(red: 0.05, green: 0.18, blue: 0.17))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(accent)
                .cornerRadius(28)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.65 : 1.0)
    }

    private func sortButton(_ mode: RemoteServiceSortMode) -> some View {
        Button(action: { sortMode = mode }) {
            HStack {
                Text(mode.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if sortMode == mode {
                    Text("↓")
                        .font(.headline)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(sortMode == mode ? panelBackground : fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.10, green: 0.27, blue: 0.24), lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }

    private func fieldLine(_ title: String, _ value: String?) -> some View {
        Text("\(title): \(value ?? "")")
            .font(.title3)
            .foregroundColor(Color(red: 0.83, green: 0.93, blue: 0.90))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    @MainActor
    private func search() async {
        hideKeyboard()
        isLoading = true
        selectedCase = nil
        resultText = "Searching..."

        do {
            let result = try await APIClient.shared.searchRemoteServiceCases(keyword: keyword.trimmed)
            cases = result
            if result.isEmpty {
                resultText = "No service case found."
            } else {
                resultText = "\(result.count) case(s) found."
            }
        } catch {
            cases = []
            selectedCase = nil
            resultText = errorText(error)
        }

        isLoading = false
    }

    @MainActor
    private func openCase(_ item: RemoteServiceCaseDto) async {
        isLoading = true
        resultText = "Loading case..."

        do {
            selectedCase = try await APIClient.shared.getRemoteServiceCase(id: item.id)
            resultText = "Case loaded."
        } catch {
            selectedCase = item
            resultText = errorText(error)
        }

        isLoading = false
    }

    private func clear() {
        keyword = ""
        cases = []
        selectedCase = nil
        resultText = "Input keyword and press Search"
        hideKeyboard()
    }

    private func caseNumberText(_ item: RemoteServiceCaseDto) -> String {
        if let caseNo = item.caseNo, caseNo > 0 {
            return "\(caseNo)"
        }
        return "\(item.id)"
    }

    private func statusText(_ item: RemoteServiceCaseDto) -> String {
        if item.isClosed == 1 {
            return "已結案"
        }
        return item.status ?? ""
    }

    private func nonEmpty(_ value: String?, fallback: String) -> String {
        guard let value = value else {
            return fallback
        }

        let cleaned = value.trimmed
        return cleaned.isEmpty ? fallback : cleaned
    }

    private func formatCaseDetail(_ item: RemoteServiceCaseDto) -> String {
        return """
Case No: \(caseNumberText(item))
Customer: \(item.customer ?? "")
Sales No: \(item.salesNo ?? "")
Model: \(item.model ?? "")
Machine Serial No: \(item.machineSerialNo ?? "")
Country: \(item.customerCountry ?? "")

Shipment Date: \(item.shipmentDate ?? "")
Warranty Status: \(item.warrantyStatus ?? "")
Open Date: \(item.openDate ?? "")

Problem Category: \(item.problemCategory ?? "")
Contact Method: \(item.contactMethod ?? "")
Remote Tool: \(item.remoteTool ?? "")
Remote ID: \(item.remoteId ?? "")

Handler1: \(item.handler1 ?? "")
Handler2: \(item.handler2 ?? "")
Customer Contact: \(item.customerContact ?? "")
Urgency: \(item.urgency ?? "")
Root Cause: \(item.rootCause ?? "")
Status: \(item.status ?? "")
Is Closed: \(item.isClosed == 1 ? "Yes" : "No")
Close Date: \(item.closeDate ?? "")

Need Follow Up: \(item.needFollowUp == 1 ? "Yes" : "No")
Follow Up Date: \(item.followUpDate ?? "")
Work Hours: \(item.workHours ?? 0)

Customer Issue:
\(item.customerIssue ?? "")

Solution:
\(item.solution ?? "")

Attachment Path:
\(item.attachmentPath ?? "")

Created At: \(item.createdAt ?? "")
Updated At: \(item.updatedAt ?? "")
"""
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
