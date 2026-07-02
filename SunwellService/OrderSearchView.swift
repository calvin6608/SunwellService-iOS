import SwiftUI

struct OrderSearchView: View {
    @State private var orderNo = ""
    @State private var result: OrderDto?
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Search") {
                TextField("Order number", text: $orderNo)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button {
                    Task { await search() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Search Order")
                    }
                }
                .disabled(isLoading || orderNo.trimmed.isEmpty)
            }

            if let result {
                Section("Result") {
                    LabeledContent("Order No", value: result.orderNo)
                    if let text = result.result, !text.isEmpty {
                        Text(text)
                            .font(.body.monospaced())
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
        .navigationTitle("Order")
    }

    private func search() async {
        isLoading = true
        errorMessage = ""
        result = nil

        do {
            result = try await APIClient.shared.getOrder(orderNo: orderNo.trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
