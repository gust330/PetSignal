import SwiftUI

struct ReportsScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @State private var filter = ReportFilter.active
    @State private var searchText = ""

    private var activeReports: [AnimalReport] {
        reportStore.reports.filter { $0.status == .active }
    }

    private var filteredReports: [AnimalReport] {
        reportStore.reports
            .filter(matchesFilter)
            .filter { report in
                searchText.isEmpty
                    || report.displayName.localizedCaseInsensitiveContains(searchText)
                    || report.summary.localizedCaseInsensitiveContains(searchText)
                    || report.details.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.lastSeenAt > $1.lastSeenAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    communityHeader

                    if filteredReports.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No reports here" : "No results",
                            systemImage: searchText.isEmpty ? "pawprint" : "magnifyingglass",
                            description: Text(emptyDescription)
                        )
                        .frame(minHeight: 280)
                    } else {
                        ForEach(filteredReports) { report in
                            NavigationLink(value: report.id) {
                                ReportCard(
                                    report: report,
                                    isSaved: reportStore.savedReportIDs.contains(report.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("Community")
            .navigationDestination(for: UUID.self) { reportID in
                ReportDetailView(reportID: reportID)
            }
            .searchable(text: $searchText, prompt: "Name, color, or identifying trait")
            .safeAreaInset(edge: .top, spacing: 0) {
                filterBar
            }
        }
    }

    private var communityHeader: some View {
        HStack(spacing: 16) {
            SignalMark(size: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("Signals near you")
                    .font(.title2.weight(.bold))
                Text("\(activeReports.count) active reports · community verified updates")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .petSignalCard()
        .padding(.top, 14)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReportFilter.allCases) { option in
                    Button {
                        withAnimation(.snappy) {
                            filter = option
                        }
                    } label: {
                        Label(option.rawValue, systemImage: option.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(filter == option ? .white : .primary)
                            .padding(.horizontal, 13)
                            .frame(height: 36)
                            .background(
                                filter == option ? Color.petSignalGreen : Color(uiColor: .tertiarySystemFill),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
        .background(.bar)
    }

    private var emptyDescription: String {
        if !searchText.isEmpty {
            return "Try a different name or identifying trait."
        }
        switch filter {
        case .saved: "Bookmark a report to keep it close."
        case .resolved: "Resolved reports will appear here."
        default: "New community reports will appear here."
        }
    }

    private func matchesFilter(_ report: AnimalReport) -> Bool {
        switch filter {
        case .active: report.status == .active
        case .missing: report.kind == .missing && report.status == .active
        case .sightings: report.kind == .sighting && report.status == .active
        case .saved: reportStore.savedReportIDs.contains(report.id)
        case .resolved: report.status != .active
        }
    }
}

private enum ReportFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case missing = "Missing"
    case sightings = "Sightings"
    case saved = "Saved"
    case resolved = "Resolved"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .active: "dot.radiowaves.left.and.right"
        case .missing: "magnifyingglass"
        case .sightings: "eye.fill"
        case .saved: "bookmark.fill"
        case .resolved: "checkmark.circle.fill"
        }
    }
}
