import SwiftUI

struct ServiceRecordSearchView: View {
    @State private var keyword = ""
    @State private var records: [ServiceRecordDto] = []
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("Search") {
                TextField("Customer, machine, issue...", text: $keyword)
                    .disableAutocorrection(true)

                Button {
                    Task { await search() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Search Records")
                    }
                }
                .disabled(isLoading || keyword.trimmed.isEmpty)
            }

            if !records.isEmpty {
                Section("Results") {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.customer ?? "Unknown customer")
                                    .font(.headline)
                                Spacer()
                                Text(record.date ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let machineNo = record.machineNo, !machineNo.isEmpty {
                                Text(machineNo)
                                    .font(.subheadline.weight(.semibold))
                            }

                            if let issue = record.issue, !issue.isEmpty {
                                Text(issue)
                            }

                            if let solution = record.solution, !solution.isEmpty {
                                Text(solution)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
        .navigationTitle("Service Records")
    }

    private func search() async {
        isLoading = true
        errorMessage = ""
        records = []

        do {
            records = try await APIClient.shared.searchServiceRecords(keyword: keyword.trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}


