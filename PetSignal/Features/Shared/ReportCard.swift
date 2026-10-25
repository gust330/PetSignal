import SwiftUI
import UIKit

struct ReportCard: View {
    let report: AnimalReport

    var body: some View {
        HStack(spacing: 14) {
            ReportImage(report: report)
                .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(report.kind.rawValue, systemImage: report.kind.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(report.kind.tint)
                    Spacer()
                    Text(report.lastSeenAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(report.displayName)
                    .font(.headline)
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
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

extension ReportKind {
    var tint: Color {
        switch self {
        case .missing: .orange
        case .sighting: .teal
        }
    }
}
