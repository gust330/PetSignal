import SwiftUI

struct ReportsScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onCreateReport: () -> Void

    init(onCreateReport: @escaping () -> Void = {}) {
        self.onCreateReport = onCreateReport
    }

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
                            searchText.isEmpty ? "No Matching Reports" : "No Results Found",
                            systemImage: searchText.isEmpty ? "pawprint.circle" : "magnifyingglass",
                            description: Text(emptyDescription)
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredReports) { report in
                            let matchCount = ReportMatcher().candidates(for: report, among: reportStore.reports).count
                            NavigationLink(value: report.id) {
                                ReportCard(
                                    report: report,
                                    isSaved: reportStore.savedReportIDs.contains(report.id),
                                    candidateMatchCount: matchCount
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(PetSignalTheme.canvas)
            .navigationTitle("Community Reports")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onCreateReport) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(PetSignalTheme.green)
                    }
                    .accessibilityLabel("Create New Report")
                }
            }
            .navigationDestination(for: UUID.self) { reportID in
                ReportDetailView(reportID: reportID)
            }
            .searchable(text: $searchText, prompt: "Search breed, collar, trait, or area")
            .safeAreaInset(edge: .top, spacing: 0) {
                filterBar
            }
        }
    }

    private var communityHeader: some View {
        HStack(spacing: 14) {
            SignalMark(size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("Community Reports")
                    .font(.headline.weight(.bold))
                Text("\(activeReports.count) active \(activeReports.count == 1 ? "report" : "reports") • Snapped to 300m grid")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .petSignalCard()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReportFilter.allCases) { option in
                    Button {
                        if reduceMotion {
                            filter = option
                        } else {
                            withAnimation(.snappy) { filter = option }
                        }
                    } label: {
                        Label(option.rawValue, systemImage: option.systemImage)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                filter == option ? AnyShapeStyle(PetSignalTheme.green) : AnyShapeStyle(PetSignalTheme.surface),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    filter == option ? PetSignalTheme.green : PetSignalTheme.border.opacity(0.5),
                                    lineWidth: 1
                                )
                            )
                            .foregroundStyle(filter == option ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                    .accessibilityHint("Filters the community reports list")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .sensoryFeedback(.selection, trigger: filter)
    }

    private var emptyDescription: String {
        if !searchText.isEmpty {
            return "Try searching for a different breed, collar color, or trait."
        }
        switch filter {
        case .saved: return "Bookmark a report to keep track of its status here."
        case .resolved: return "Resolved and reunited animal reports will appear here."
        default: return "Try clearing a filter or checking back soon for new community signals."
        }
    }

    private func matchesFilter(_ report: AnimalReport) -> Bool {
        switch filter {
        case .active: return report.status == .active
        case .missing: return report.kind == .missing && report.status == .active
        case .sightings: return report.kind == .sighting && report.status == .active
        case .saved: return reportStore.savedReportIDs.contains(report.id)
        case .resolved: return report.status != .active
        }
    }
}

private enum ReportFilter: String, CaseIterable, Identifiable {
    case active = "All Active"
    case missing = "Missing"
    case sightings = "Sightings"
    case saved = "Saved ★"
    case resolved = "Reunited"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .active: return "dot.radiowaves.left.and.right"
        case .missing: return "magnifyingglass"
        case .sightings: return "eye.fill"
        case .saved: return "bookmark.fill"
        case .resolved: return "checkmark.seal.fill"
        }
    }
}
