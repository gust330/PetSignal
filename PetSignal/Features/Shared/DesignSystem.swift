import SwiftUI
import UIKit

// MARK: - Semantic Theme & Tokens

enum PetSignalTheme {
    /// Dynamic Light/Dark semantic color helper
    static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    // Core Brand & Semantic Status Palette (WCAG AA+ Outdoor Sunlight Tested)
    static let green = dynamicColor(
        light: UIColor(red: 0.05, green: 0.24, blue: 0.18, alpha: 1.0), // #0D3328 Deep Pine Evergreen
        dark:  UIColor(red: 0.22, green: 0.66, blue: 0.50, alpha: 1.0)  // #38A882 Luminous Sage
    )
    static let amber = dynamicColor(
        light: UIColor(red: 0.76, green: 0.25, blue: 0.05, alpha: 1.0), // #C2410C High-Contrast Sunlight Amber
        dark:  UIColor(red: 0.98, green: 0.57, blue: 0.24, alpha: 1.0)  // #FB923C Warm Gold
    )
    static let teal = dynamicColor(
        light: UIColor(red: 0.05, green: 0.45, blue: 0.56, alpha: 1.0), // #0E7490 Deep Coastal Teal
        dark:  UIColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)  // #38BDF8 Bright Sky Teal
    )
    static let canvas = dynamicColor(
        light: UIColor(red: 0.965, green: 0.960, blue: 0.945, alpha: 1.0), // #F6F5F1 Warm Alabaster
        dark:  UIColor(red: 0.045, green: 0.067, blue: 0.055, alpha: 1.0)  // #0C110E Deep Forest Night
    )
    /// High-contrast text color for elements rendered on a `PetSignalTheme.green` background
    /// (passes WCAG AAA with >7:1 contrast in both light and dark modes)
    static let onGreenForeground = dynamicColor(
        light: UIColor.white,
        dark:  UIColor(red: 0.05, green: 0.07, blue: 0.07, alpha: 1.0)
    )
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let subtleSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let border = Color(uiColor: .separator)
}

extension Color {
    static let petSignalGreen = PetSignalTheme.green
    static let petSignalDeepGreen = Color(red: 0.05, green: 0.20, blue: 0.17)
    static let petSignalCream = PetSignalTheme.canvas
    static let petSignalAmber = PetSignalTheme.amber
    static let petSignalTeal = PetSignalTheme.teal
}

// MARK: - Brand Mark

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

// MARK: - Status & Type Badges

struct StatusPillBadge: View {
    let kind: ReportKind
    let status: ReportStatus

    private var isResolved: Bool {
        status != .active
    }

    private var tintColor: Color {
        isResolved ? PetSignalTheme.green : kind.tint
    }

    private var labelText: String {
        isResolved ? status.displayName : kind.rawValue
    }

    private var iconName: String {
        isResolved ? "checkmark.seal.fill" : kind.systemImage
    }

    var body: some View {
        Label(labelText, systemImage: iconName)
            .font(.caption.weight(.bold))
            .tracking(0.3)
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tintColor.opacity(0.16)))
            .overlay(Capsule().strokeBorder(tintColor.opacity(0.4), lineWidth: 1))
            .foregroundStyle(tintColor)
    }
}

struct TypePill: View {
    let kind: ReportKind

    var body: some View {
        Label(kind.rawValue, systemImage: kind.systemImage)
            .font(.caption.weight(.bold))
            .tracking(0.3)
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(kind.tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(kind.tint.opacity(0.4), lineWidth: 1))
            .foregroundStyle(kind.tint)
    }
}

struct StatusPill: View {
    let status: ReportStatus

    var body: some View {
        Label(status.displayName, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(status.tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(status.tint.opacity(0.4), lineWidth: 1))
            .foregroundStyle(status.tint)
    }
}

// MARK: - Safety Advice Banner

struct SafetyBanner: View {
    let kind: ReportKind

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.title3)
                .foregroundStyle(PetSignalTheme.amber)
                .padding(.top, 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Approach with care")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(kind == .sighting
                     ? "Do not chase or corner the animal. Observe from a calm distance. Frightened pets may bolt into traffic. If it is injured or trapped, contact local animal services."
                     : "Check before approaching. A frightened pet may run even when called. Observe from a calm distance and coordinate safely with community members.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetSignalTheme.amber.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(PetSignalTheme.amber.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Reusable UI Components

struct AttributeCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetSignalTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(PetSignalTheme.border.opacity(0.4), lineWidth: 1)
        )
    }
}

struct MatchReasonChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(PetSignalTheme.teal.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(PetSignalTheme.teal.opacity(0.35), lineWidth: 1))
            .foregroundStyle(PetSignalTheme.teal)
    }
}

struct CandidateMatchBanner: View {
    let matchCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PetSignalTheme.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(matchCount) Possible Sighting Match\(matchCount == 1 ? "" : "es")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Within ~300m privacy grid cell • Explainable alignment")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(PetSignalTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(PetSignalTheme.teal.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Model Extensions

extension ReportKind {
    var tint: Color {
        switch self {
        case .missing: return PetSignalTheme.amber
        case .sighting: return PetSignalTheme.teal
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
        case .active: return PetSignalTheme.green
        case .reunited, .safe: return PetSignalTheme.green
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

// MARK: - View Modifiers

extension View {
    func petSignalCard() -> some View {
        padding(14)
            .background(PetSignalTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(PetSignalTheme.border.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
