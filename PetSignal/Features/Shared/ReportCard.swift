import SwiftUI
import UIKit

struct ReportCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: AnimalReport
    var isSaved = false
    var candidateMatchCount: Int = 0

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
                        .frame(width: 84, height: 84)
                    reportInformation
                }
            }
        }
        .petSignalCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to open full report, safety guidance, and possible matches.")
    }

    private var reportInformation: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                StatusPillBadge(kind: report.kind, status: report.status)
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(report.lastSeenAt, style: .relative)
                }
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
            }

            Text(report.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            Label("\(report.location.approximateAreaDescription) (~300m zone)", systemImage: "shield.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if candidateMatchCount > 0 {
                Label("\(candidateMatchCount) Possible Match\(candidateMatchCount == 1 ? "" : "es")", systemImage: "sparkle.magnifyingglass")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PetSignalTheme.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(PetSignalTheme.teal.opacity(0.35), lineWidth: 1)
                    )
                    .foregroundStyle(PetSignalTheme.teal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityDescription: String {
        let statusText = report.status != .active ? report.status.displayName : report.kind.rawValue
        let savedText = isSaved ? ", Saved" : ""
        let matchesText = candidateMatchCount > 0 ? ", \(candidateMatchCount) possible candidate matches" : ""
        return "\(statusText). \(report.displayName). \(report.summary). Area: \(report.location.approximateAreaDescription)\(savedText)\(matchesText)."
    }
}

struct ReportThumbnail: View {
    let report: AnimalReport
    var isSaved: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PetSignalTheme.subtleSurface)
                .overlay {
                    if let imageData = report.imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: report.species.systemImage)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(report.status != .active ? PetSignalTheme.green : report.kind.tint)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if isSaved {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(PetSignalTheme.green))
                    .offset(x: -4, y: -4)
            }
        }
        .accessibilityHidden(true)
    }
}
