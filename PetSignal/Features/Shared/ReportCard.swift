import SwiftUI
import UIKit

// MARK: - 5. SignalCard (ReportCard)
/// Standardized pet alert card featuring 1:1 or 16:10 thumbnail, overlaid status pill,
/// distance telemetry in monospace, breed/trait tags, and dual-action footer.

struct ReportCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: AnimalReport
    var isSaved = false
    var candidateMatchCount: Int = 0
    var isSelected: Bool = false
    var onReportSighting: (() -> Void)? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    ReportThumbnail(report: report, isSaved: isSaved)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    reportInformation
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    ReportThumbnail(report: report, isSaved: isSaved)
                        .frame(width: 88, height: 88)
                    reportInformation
                }
            }
        }
        .petSignalCard(isSelected: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to open full report, radar telemetry, and possible matches.")
    }

    private var reportInformation: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row: Status Badge & Telemetry Monospace Time
            HStack(alignment: .center, spacing: 6) {
                SignalStatusBadge(kind: report.kind, status: report.status, size: .small)

                Spacer(minLength: 4)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(report.lastSeenAt, style: .relative)
                }
                .font(.system(size: 11, weight: .medium).monospaced())
                .foregroundStyle(.secondary)
            }

            // Signal Name with Tight Tracking & Monospace Telemetry ID
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(report.displayName)
                    .font(.headline.weight(.bold))
                    .tracking(-0.3)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(report.signalID)
                    .font(.system(size: 10, weight: .bold).monospaced())
                    .foregroundStyle(.secondary)
            }

            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            // Approximate Radar Area Telemetry
            HStack(spacing: 4) {
                Image(systemName: "dot.scope")
                    .font(.caption2)
                    .foregroundStyle(PetSignalTheme.coral)
                Text("\(report.location.approximateAreaDescription) • ~300m mesh")
                    .font(.system(size: 11, weight: .medium).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // AI Match Confidence Pill (if candidate matches exist)
            if candidateMatchCount > 0 {
                AIMatchConfidencePill(score: 85 + min(candidateMatchCount * 5, 14))
                    .padding(.top, 2)
            }

            // Dual-action footer preview
            HStack(spacing: 12) {
                Label(report.species.rawValue, systemImage: report.species.systemImage)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(PetSignalTheme.subtleSurface)
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                HStack(spacing: 3) {
                    Text("Details")
                        .font(.caption2.weight(.bold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(PetSignalTheme.coral)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityDescription: String {
        let statusText = report.status != .active ? report.status.displayName : report.kind.rawValue
        let savedText = isSaved ? ", Saved" : ""
        let matchesText = candidateMatchCount > 0 ? ", \(candidateMatchCount) possible candidate matches" : ""
        return "\(statusText). Signal \(report.signalID). \(report.displayName). \(report.summary). Area: \(report.location.approximateAreaDescription)\(savedText)\(matchesText)."
    }
}

// MARK: - Thumbnail with Radar Border

struct ReportThumbnail: View {
    let report: AnimalReport
    var isSaved: Bool = false

    private var borderColor: Color {
        if report.status != .active {
            return PetSignalTheme.emerald
        }
        return report.kind == .missing ? PetSignalTheme.coral : PetSignalTheme.amber
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                .fill(PetSignalTheme.subtleSurface)
                .overlay {
                    if let imageData = report.imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(borderColor.opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: report.species.systemImage)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(borderColor)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                        .strokeBorder(borderColor.opacity(0.35), lineWidth: 1.5)
                )

            if isSaved {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(PetSignalTheme.coral))
                    .offset(x: -4, y: -4)
            }
        }
        .accessibilityHidden(true)
    }
}
