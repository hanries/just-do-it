import SwiftUI

// MARK: - Circular Progress

struct CircularProgressView: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemBackground), lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color("AccentTeal"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: fraction)
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color("AccentTeal"))
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview helpers

#Preview("Circular Progress") {
    HStack(spacing: 20) {
        CircularProgressView(fraction: 0.25)
            .frame(width: 50, height: 50)
        CircularProgressView(fraction: 0.6)
            .frame(width: 50, height: 50)
        CircularProgressView(fraction: 1.0)
            .frame(width: 50, height: 50)
    }
    .padding()
}
