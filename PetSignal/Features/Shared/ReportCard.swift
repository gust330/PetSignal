import SwiftUI
import UIKit

struct ReportCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: AnimalReport
    var isSaved = false

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    ReportImage(report: report)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                    reportInformation
                }
            } else {
                HStack(spacing: 14) {
                    ReportImage(report: report)
                        .frame(width: 88, height: 104)
                    reportInformation
                }
            }
        }
        .petSignalCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens report details")
    }

    private var reportInformation: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                TypePill(kind: report.kind)
                Spacer()
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(Color.petSignalGreen)
                        .accessibilityLabel("Saved")
                }
            }

            Text(report.displayName)
                .font(.title3.weight(.bold))
            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            HStack(spacing: 5) {
                Label {
                    Text(report.lastSeenAt, style: .relative)
                } icon: {
                    Image(systemName: "clock")
                }
                if report.status != .active {
                    StatusPill(status: report.status)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReportImage: View {
    let report: AnimalReport

    var body: some View {
        Group {
            if let imageData = report.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    report.kind.tint.opacity(0.12)
                    Image(systemName: report.species.systemImage)
                        .font(.title)
                        .foregroundStyle(report.kind.tint)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(report.imageData == nil
            ? "No report photo for \(report.displayName)"
            : "Report photo for \(report.displayName)")
    }
}
