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
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(Color.petSignalDeepGreen)
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: size * 0.76, weight: .light))
                .foregroundStyle(Color.petSignalAmber)
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
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(kind.tint.opacity(0.16), in: Capsule())
    }
}

struct StatusPill: View {
    let status: ReportStatus

    var body: some View {
        Label(status.displayName, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(status.tint.opacity(0.16), in: Capsule())
    }
}

struct SafetyBanner: View {
    let kind: ReportKind

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(Color.petSignalGreen)
            VStack(alignment: .leading, spacing: 3) {
                Text("Approach with care")
                    .font(.subheadline.weight(.bold))
                Text(kind == .sighting
                     ? "Do not chase or corner the animal. Observe from a safe distance. If it is injured, trapped, aggressive, or in immediate danger, contact local animal or emergency services."
                     : "Check before approaching. A frightened pet may run even when called. If it is injured, trapped, aggressive, or in immediate danger, contact local animal or emergency services.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.petSignalGreen.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension ReportKind {
    var tint: Color {
        switch self {
        case .missing: return .petSignalAmber
        case .sighting: return .petSignalTeal
        }
    }
}

extension ReportStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .reunited: return "Reported reunited"
        case .safe: return "Reported safe"
        case .closed: return "Closed"
        }
    }

    var tint: Color {
        switch self {
        case .active: return .petSignalGreen
        case .reunited, .safe: return .blue
        case .closed: return .secondary
        }
    }

    var systemImage: String {
        switch self {
        case .active: return "dot.radiowaves.left.and.right"
        case .reunited: return "heart.fill"
        case .safe: return "checkmark.shield.fill"
        case .closed: return "archivebox.fill"
        }
    }
}

extension View {
    func petSignalCard() -> some View {
        padding(14)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }
}
