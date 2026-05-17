import SwiftUI



extension Color {
    init(hex: String) {
        let v = Int(hex, radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
