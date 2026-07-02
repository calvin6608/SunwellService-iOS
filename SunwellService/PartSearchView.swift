import SwiftUI

struct PartSearchView: View {
    @State private var keyword = ""
    @State private var mode = "start"
    @State private var includeImage = false
    @State private var result: PartDto?
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Search") {
                TextField("Part number or keyword", text: $keyword)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)

                Picker("Mode", selection: $mode) {
                    Text("Starts With").tag("start")
                    Text("Contains").tag("contains")
                    Text("Exact").tag("exact")
                }

                Toggle("Include image URL", isOn: $includeImage)

                Button {
                    Task { await search() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Search Part")
                    }
                }
                .disabled(isLoading || keyword.trimmed.isEmpty)
            }

            if let result = result {
                Section("Result") {
                    DetailRow("Part No", value: result.partNo)
                    DetailRow("Name", value: result.name ?? "-")
                    DetailRow("Part Number", value: yesNo(result.isPartNumber))
                    if let imageUrl = result.imageUrl, !imageUrl.isEmpty {
                        DetailRow("Image URL", value: imageUrl)
                    }
                }
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Part/BOM")
    }

    private func search() async {
        isLoading = true
        errorMessage = ""
        result = nil

        do {
            result = try await APIClient.shared.getPart(
                keyword: keyword.trimmed,
                includeImage: includeImage,
                mode: mode
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}



