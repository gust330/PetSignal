import SwiftUI

struct ReportsScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @State private var filter = ReportFilter.active

    private var filteredReports: [AnimalReport] {
        reportStore.reports
            .filter { report in
                switch filter {
                case .active: report.status == .active
                case .missing: report.kind == .missing && report.status == .active
                case .sightings: report.kind == .sighting && report.status == .active
                }
            }
            .sorted { $0.lastSeenAt > $1.lastSeenAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredReports) { report in
                        NavigationLink(value: report) {
                            ReportCard(report: report)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .padding(.bottom, 72)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("Community reports")
            .navigationDestination(for: AnimalReport.self) { report in
                ReportDetailView(report: report)
            }
            .safeAreaInset(edge: .top) {
                Picker("Report filter", selection: $filter) {
                    ForEach(ReportFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }
}

private enum ReportFilter: String, CaseIterable, Identifiable {
    case active = "All"
    case missing = "Missing"
    case sightings = "Sightings"

    var id: Self { self }
}
