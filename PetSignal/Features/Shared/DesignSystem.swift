import SwiftUI

extension Color {
    static let petSignalGreen = Color(red: 0.08, green: 0.40, blue: 0.32)
    static let petSignalDeepGreen = Color(red: 0.05, green: 0.20, blue: 0.17)
    static let petSignalCream = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let petSignalAmber = Color(red: 0.91, green: 0.57, blue: 0.15)
    static let petSignalTeal = Color(red: 0.08, green: 0.55, blue: 0.54)
}

struct SignalMark: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.petSignalGreen, .petSignalDeepGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: size * 0.78, weight: .light))
                .foregroundStyle(Color.petSignalAmber.opacity(0.8))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct TypePill: View {
    let kind: ReportKind

    var body: some View {
        Label(kind.rawValue, systemImage: kind.systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(kind.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(kind.tint.opacity(0.12), in: Capsule())
    }
}

struct StatusPill: View {
    let status: ReportStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

struct SafetyBanner: View {
    let kind: ReportKind

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(.petSignalGreen)
            VStack(alignment: .leading, spacing: 3) {
                Text("Approach with care")
                    .font(.subheadline.weight(.bold))
                Text(kind == .sighting
                     ? "Do not chase or corner the animal. Observe from a safe distance and update the location if it moves."
                     : "Check before approaching. A frightened pet may run even when called by name.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.petSignalGreen.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
    }
}

extension ReportKind {
    var tint: Color {
        switch self {
        case .missing: .petSignalAmber
        case .sighting: .petSignalTeal
        }
    }
}

extension ReportStatus {
    var tint: Color {
        switch self {
        case .active: .petSignalGreen
        case .reunited, .safe: .blue
        case .closed: .secondary
        }
    }

    var systemImage: String {
        switch self {
        case .active: "dot.radiowaves.left.and.right"
        case .reunited: "heart.fill"
        case .safe: "checkmark.shield.fill"
        case .closed: "archivebox.fill"
        }
    }
}

extension View {
    func petSignalCard() -> some View {
        padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: Color.petSignalDeepGreen.opacity(0.07), radius: 14, y: 6)
    }
}
