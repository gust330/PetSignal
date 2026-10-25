import SwiftUI
import UIKit

struct ReportCard: View {
    let report: AnimalReport
    var isSaved = false

    var body: some View {
        HStack(spacing: 15) {
            ReportImage(report: report)
                .frame(width: 94, height: 106)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    TypePill(kind: report.kind)
                    Spacer()
                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.petSignalGreen)
                    }
                }

                Text(report.displayName)
                    .font(.title3.weight(.bold))
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                    Text(report.lastSeenAt, style: .relative)
                    if report.status != .active {
                        Text("·")
                        StatusPill(status: report.status)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .petSignalCard()
        .accessibilityElement(children: .combine)
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
