import SwiftUI

struct DrawingSearchView: View {
    @State private var partNo = ""
    @State private var result: DrawingDto?
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Search") {
                TextField("Part number", text: $partNo)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button {
                    Task { await search() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Search Drawing")
                    }
                }
                .disabled(isLoading || partNo.trimmed.isEmpty)
            }

            if let result {
                Section("Result") {
                    LabeledContent("Part No", value: result.partNo)
                    LabeledContent("Success", value: result.success ? "Yes" : "No")
                    LabeledContent("Type", value: result.resultType ?? "-")
                    if let message = result.message, !message.isEmpty {
                        Text(message)
                    }
                    if let urlText = result.url, let url = URL(string: urlText) {
                        Link("Open Drawing", destination: url)
                    } else if let urlText = result.url, !urlText.isEmpty {
                        LabeledContent("URL", value: urlText)
                    }
                    if result.approvalRequired == true {
                        Label("Approval required", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("CAD Drawing")
    }

    private func search() async {
        isLoading = true
        errorMessage = ""
        result = nil

        do {
            result = try await APIClient.shared.getDrawing(partNo: partNo.trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
