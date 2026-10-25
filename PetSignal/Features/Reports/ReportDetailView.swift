import SwiftUI

struct ReportDetailView: View {
    @Environment(ReportStore.self) private var reportStore
    let report: AnimalReport

    private var matches: [MatchCandidate] {
        ReportMatcher().candidates(for: report, among: reportStore.reports)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReportImage(report: report)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)

                VStack(alignment: .leading, spacing: 10) {
                    Label(report.kind.rawValue, systemImage: report.kind.systemImage)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(report.kind.tint)
                    Text(report.displayName)
                        .font(.largeTitle.bold())
                    Text(report.summary)
                        .font(.title3.weight(.medium))
                    if !report.details.isEmpty {
                        Text(report.details)
                            .foregroundStyle(.secondary)
                    }
                    Label(
                        "Last seen \(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened))",
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                }

                if !matches.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Possible matches")
                            .font(.title2.bold())
                        Text("Suggestions combine distance, time, and description similarity. A person should always confirm the match.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        ForEach(matches) { match in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(match.report.displayName)
                                        .font(.headline)
                                    Text("\(match.distanceKilometers, format: .number.precision(.fractionLength(1))) km away")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(match.score, format: .percent.precision(.fractionLength(0)))
                                    .font(.headline)
                                    .foregroundStyle(.tint)
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Report details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
