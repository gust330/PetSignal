import SwiftUI
import UIKit

// MARK: - Semantic Theme & Design Tokens

enum PetSignalTheme {
    /// Dynamic Light/Dark semantic color helper
    static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    // MARK: - 1. Core Semantic Palette
    /// Primary Brand (Signal Coral): #FF5A36 (gradient to #FF2E54)
    /// Used for Lost Pet alerts, primary CTAs, and active radar pulses.
    static let coral = dynamicColor(
        light: UIColor(red: 1.0, green: 0.353, blue: 0.212, alpha: 1.0), // #FF5A36
        dark:  UIColor(red: 1.0, green: 0.392, blue: 0.255, alpha: 1.0)  // #FF6441
    )
    static let coralDark = Color(red: 1.0, green: 0.180, blue: 0.329) // #FF2E54
    static let coralGradient = LinearGradient(
        colors: [coral, coralDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sighting / Amber Alert: #F59E0B (amber-500)
    /// Used for unverified community sightings and AI potential matches.
    static let amber = dynamicColor(
        light: UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1.0), // #F59E0B
        dark:  UIColor(red: 0.984, green: 0.686, blue: 0.220, alpha: 1.0)  // #FBAF38
    )

    /// Safe / Reunited Emerald: #10B981 (emerald-500)
    /// Used for Found pets, verified microchips, and safe resolution states.
    static let emerald = dynamicColor(
        light: UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1.0), // #10B981
        dark:  UIColor(red: 0.204, green: 0.827, blue: 0.604, alpha: 1.0)  // #34D399
    )

    /// Vet / Safe Haven Indigo: #6366F1 (indigo-500)
    /// Used for 24/7 Vet clinics, shelters, and microchip scanning stations.
    static let indigo = dynamicColor(
        light: UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 1.0), // #6366F1
        dark:  UIColor(red: 0.506, green: 0.549, blue: 0.973, alpha: 1.0)  // #818CF8
    )

    // MARK: - 2. Surface Architecture
    /// Canvas Base: Light #F1F5F9, Dark #090D16
    static let canvas = dynamicColor(
        light: UIColor(red: 0.945, green: 0.961, blue: 0.976, alpha: 1.0), // #F1F5F9
        dark:  UIColor(red: 0.035, green: 0.051, blue: 0.086, alpha: 1.0)  // #090D16
    )

    /// Elevated Glass HUD: Light rgba(255, 255, 255, 0.85), Dark rgba(15, 23, 42, 0.78)
    static let elevatedGlassHUD = dynamicColor(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85),
        dark:  UIColor(red: 0.059, green: 0.090, blue: 0.165, alpha: 0.78) // #0F172A/78
    )

    /// Card Surface: Light #FFFFFF, Dark #131B2E
    static let cardSurface = dynamicColor(
        light: UIColor.white,
        dark:  UIColor(red: 0.075, green: 0.106, blue: 0.180, alpha: 1.0)  // #131B2E
    )

    /// Card Border: Light rgba(226, 232, 240, 0.80), Dark rgba(30, 41, 59, 0.80)
    static let cardBorder = dynamicColor(
        light: UIColor(red: 0.886, green: 0.910, blue: 0.941, alpha: 0.80), // #E2E8F0/80
        dark:  UIColor(red: 0.118, green: 0.161, blue: 0.231, alpha: 0.80)  // #1E293B/80
    )

    /// HUD Border: Light border-slate-200/80, Dark border-white/10
    static let hudBorder = dynamicColor(
        light: UIColor(red: 0.886, green: 0.910, blue: 0.941, alpha: 0.80),
        dark:  UIColor(white: 1.0, alpha: 0.10)
    )

    /// Subtle Surface (e.g. secondary containers, photo placeholder)
    static let subtleSurface = dynamicColor(
        light: UIColor(red: 0.973, green: 0.980, blue: 0.988, alpha: 1.0), // #F8FAFC
        dark:  UIColor(red: 0.102, green: 0.137, blue: 0.227, alpha: 1.0)  // #1A233A
    )

    // MARK: - Backward Compatibility Aliases
    static let green = emerald
    static let teal = indigo
    static let surface = cardSurface
    static let border = cardBorder
    static let onGreenForeground = Color.white
    static let onCoralForeground = Color.white

    // MARK: - 3. Corner Radii Tokens
    /// Cards: rounded-3xl (24px)
    static let cardRadius: CGFloat = 24.0
    /// Modals/Sheets: rounded-[28px] (28px)
    static let modalRadius: CGFloat = 28.0
    /// Buttons/Inputs: rounded-2xl (16px)
    static let buttonRadius: CGFloat = 16.0
    /// Status Pills: rounded-full (999px)
    static let pillRadius: CGFloat = 999.0
}

extension Color {
    static let petSignalCoral = PetSignalTheme.coral
    static let petSignalAmber = PetSignalTheme.amber
    static let petSignalEmerald = PetSignalTheme.emerald
    static let petSignalIndigo = PetSignalTheme.indigo
    static let petSignalGreen = PetSignalTheme.emerald
    static let petSignalTeal = PetSignalTheme.indigo
    static let petSignalCanvas = PetSignalTheme.canvas
    static let petSignalCream = PetSignalTheme.canvas
    static let petSignalDeepGreen = Color(red: 0.059, green: 0.090, blue: 0.165)
}

// MARK: - Brand Mark

struct SignalMark: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.059, green: 0.090, blue: 0.165),
                            Color(red: 0.075, green: 0.106, blue: 0.180)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .strokeBorder(PetSignalTheme.coral.opacity(0.35), lineWidth: 1)
                )

            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(PetSignalTheme.coralGradient)

            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: size * 0.76, weight: .light))
                .foregroundStyle(PetSignalTheme.coral.opacity(0.55))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - 1. SignalStatusBadge
/// Pill badge with live pulsing dot, uppercase tracking-wider text, semantic background tint (bg-opacity-15).

struct SignalStatusBadge: View {
    enum BadgeSize {
        case small
        case regular

        var font: Font {
            switch self {
            case .small: return .system(size: 10, weight: .bold)
            case .regular: return .system(size: 11, weight: .bold)
            }
        }

        var paddingH: CGFloat {
            switch self {
            case .small: return 8
            case .regular: return 10
            }
        }

        var paddingV: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 5
            }
        }

        var dotSize: CGFloat {
            switch self {
            case .small: return 5.5
            case .regular: return 6.5
            }
        }
    }

    let title: String
    let color: Color
    var size: BadgeSize = .regular

    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(title: String, color: Color, size: BadgeSize = .regular) {
        self.title = title
        self.color = color
        self.size = size
    }

    init(kind: ReportKind, status: ReportStatus, size: BadgeSize = .regular) {
        let isResolved = status != .active
        if isResolved {
            self.title = status.displayName.uppercased()
            self.color = PetSignalTheme.emerald
        } else {
            switch kind {
            case .missing:
                self.title = "LOST SIGNAL"
                self.color = PetSignalTheme.coral
            case .sighting:
                self.title = "AI SIGHTING"
                self.color = PetSignalTheme.amber
            }
        }
        self.size = size
    }

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                if !reduceMotion {
                    Circle()
                        .fill(color)
                        .scaleEffect(isPulsing ? 2.2 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }
                Circle()
                    .fill(color)
            }
            .frame(width: size.dotSize, height: size.dotSize)

            Text(title)
                .font(size.font)
                .tracking(0.8)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .padding(.horizontal, size.paddingH)
        .padding(.vertical, size.paddingV)
        .background(color.opacity(0.15))
        .overlay(
            Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1)
        )
        .clipShape(Capsule())
        .foregroundStyle(color)
        .onAppear {
            if !reduceMotion {
                isPulsing = true
            }
        }
    }
}

/// Backwards compatibility alias
typealias StatusPillBadge = SignalStatusBadge

struct StatusPill: View {
    let status: ReportStatus

    var body: some View {
        SignalStatusBadge(
            title: status.displayName.uppercased(),
            color: status.tint,
            size: .small
        )
    }
}

struct TypePill: View {
    let kind: ReportKind

    var body: some View {
        SignalStatusBadge(
            title: kind.rawValue.uppercased(),
            color: kind.tint,
            size: .small
        )
    }
}

// MARK: - 2. AIMatchConfidencePill
/// Gradient-bordered badge with Sparkles icon showing neural visual match score.

struct AIMatchConfidencePill: View {
    let score: Int

    var body: some View {
        HStack(spacing: 4.5) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(PetSignalTheme.coral)

            Text("\(score)% AI MATCH")
                .font(.system(size: 11, weight: .bold).monospaced())
                .tracking(0.3)
                .foregroundStyle(PetSignalTheme.indigo)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4.5)
        .background(
            LinearGradient(
                colors: [
                    PetSignalTheme.indigo.opacity(0.12),
                    PetSignalTheme.coral.opacity(0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            PetSignalTheme.indigo.opacity(0.40),
                            PetSignalTheme.coral.opacity(0.35)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(Capsule())
    }
}

// MARK: - 3. PetPinMarker
/// Custom avatar marker with semantic border ring, directional pointer triangle, and animated outer radar wave.

struct PetPinMarker: View {
    let report: AnimalReport
    var isSelected: Bool = false
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pinColor: Color {
        if report.status != .active {
            return PetSignalTheme.emerald
        }
        return report.kind == .missing ? PetSignalTheme.coral : PetSignalTheme.amber
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Animated outer radar wave
                if (report.kind == .missing || isSelected) && !reduceMotion {
                    Circle()
                        .stroke(pinColor.opacity(0.45), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.85 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                        .frame(width: 44, height: 44)
                }

                // Avatar bubble with semantic ring
                Circle()
                    .fill(PetSignalTheme.cardSurface)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(pinColor, lineWidth: isSelected ? 3.5 : 2.5)
                    )
                    .shadow(
                        color: pinColor.opacity(isSelected ? 0.45 : 0.25),
                        radius: isSelected ? 8 : 4,
                        y: 2
                    )

                // Avatar Icon / Silhouette
                Image(systemName: report.species.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(pinColor)
            }
            .frame(width: 46, height: 46)

            // Directional pointer triangle
            PointerTriangle()
                .fill(pinColor)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .onAppear {
            if !reduceMotion {
                isPulsing = true
            }
        }
    }
}

struct PointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 4. GlassNavigationHUD Modifier
/// Floating glassmorphic HUD panel with backdrop-blur-xl, border-white/10, and high contrast.

struct GlassHUDModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(PetSignalTheme.elevatedGlassHUD)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(PetSignalTheme.hudBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassHUD(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassHUDModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Safety Advice Banner

struct SafetyBanner: View {
    let kind: ReportKind

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                .tracking(0.3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetSignalTheme.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PetSignalTheme.cardBorder, lineWidth: 1)
        )
    }
}

struct MatchReasonChip: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(PetSignalTheme.indigo.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(PetSignalTheme.indigo.opacity(0.35), lineWidth: 1))
            .foregroundStyle(PetSignalTheme.indigo)
    }
}

struct CandidateMatchBanner: View {
    let matchCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PetSignalTheme.coral)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(matchCount) Possible AI Sighting Match\(matchCount == 1 ? "" : "es")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Within ~300m privacy mesh • Neural trait alignment")
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
        .background(
            LinearGradient(
                colors: [
                    PetSignalTheme.indigo.opacity(0.12),
                    PetSignalTheme.coral.opacity(0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(PetSignalTheme.indigo.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Model Extensions

extension ReportKind {
    var tint: Color {
        switch self {
        case .missing: return PetSignalTheme.coral
        case .sighting: return PetSignalTheme.amber
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
        case .active: return PetSignalTheme.coral
        case .reunited, .safe: return PetSignalTheme.emerald
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

// MARK: - 5. SignalCard View Modifier
/// Generous, friendly, modern curves — Cards: rounded-3xl (24px) with subtle shadow & glow on active selection.

extension View {
    func petSignalCard(isSelected: Bool = false) -> some View {
        padding(14)
            .background(
                RoundedRectangle(cornerRadius: PetSignalTheme.cardRadius, style: .continuous)
                    .fill(PetSignalTheme.cardSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: PetSignalTheme.cardRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? PetSignalTheme.coral : PetSignalTheme.cardBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(
                color: isSelected
                    ? PetSignalTheme.coral.opacity(0.28)
                    : Color.black.opacity(0.06),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 4 : 2
            )
    }
}
