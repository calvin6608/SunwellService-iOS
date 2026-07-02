import SwiftUI

extension Color {
    static let sunwellBlue = Color(red: 0.054, green: 0.200, blue: 0.360)
}

extension View {
    func sunwellField() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

func yesNo(_ value: Bool?) -> String {
    guard let value else { return "-" }
    return value ? "Yes" : "No"
}
