import SwiftUI

extension BlogPost {
    var gradientColors: [Color] {
        coverGradient.compactMap(Color.init(hex:))
    }

    var publishLabel: String {
        publishDate.formatted(.dateTime.month(.abbreviated).day())
    }
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
