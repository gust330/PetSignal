import MapKit
import SwiftUI

struct MapScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var focusedReportID: UUID?
    let onCreateReport: () -> Void

    init(onCreateReport: @escaping () -> Void = {}) {
        self.onCreateReport = onCreateReport
    }

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var selectedReportID: UUID?
    @State private var kindFilter: ReportKind?
    @State private var speciesFilter: AnimalSpecies?

    private var visibleReports: [AnimalReport] {
        reportStore.reports.filter { report in
            report.status == .active
                && (kindFilter == nil || report.kind == kindFilter)
                && (speciesFilter == nil || report.species == speciesFilter)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition, selection: $selectedReportID) {
                    ForEach(visibleReports) { report in
                        // Privacy-by-Default 300m Approximate Area Circle
                        MapCircle(center: report.location.coordinate, radius: 300)
                            .foregroundStyle(report.kind.tint.opacity(selectedReportID == report.id ? 0.28 : 0.18))
                            .stroke(
                                report.kind.tint,
                                lineWidth: selectedReportID == report.id ? 3 : 1.5
                            )
                            .mapOverlayLevel(level: .aboveRoads)

                        // Center Zone Badge Annotation (Snapped to 300m Privacy Grid)
                        Annotation(
                            report.displayName,
                            coordinate: report.location.coordinate,
                            anchor: .center
                        ) {
                            Button {
                                selectedReportID = report.id
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: report.species.systemImage)
                                        .font(.caption2.weight(.bold))
                                    Text(report.kind == .missing ? "Missing" : "Sighting")
                                        .font(.caption2.weight(.bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(report.kind.tint)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Approximate 300m zone for \(report.kind.rawValue) \(report.species.rawValue): \(report.displayName)")
                            .accessibilityHint("Selects this report")
                        }
                        .tag(report.id)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .sensoryFeedback(.selection, trigger: selectedReportID)

                // Top Floating Glass Filter Header
                topFloatingHeader
            }
            .safeAreaInset(edge: .bottom, spacing: 8) {
                if let report = selectedVisibleReport {
                    selectedReportDock(report)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay {
                if visibleReports.isEmpty {
                    ContentUnavailableView(
                        "No active reports",
                        systemImage: "map",
                        description: Text(emptyStateText)
                    )
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(reduceMotion ? nil : .snappy, value: selectedReportID)
            .onChange(of: selectedReportID) { _, reportID in
                focusedReportID = reportID
            }
            .onChange(of: visibleReports.map(\.id)) { _, visibleIDs in
                if let selectedReportID, !visibleIDs.contains(selectedReportID) {
                    self.selectedReportID = nil
                }
            }
            .navigationDestination(for: UUID.self) { reportID in
                ReportDetailView(reportID: reportID)
            }
        }
    }

    private var selectedVisibleReport: AnimalReport? {
        guard let selectedReportID else { return nil }
        return visibleReports.first { $0.id == selectedReportID }
    }

    private var topFloatingHeader: some View {
        VStack(spacing: 8) {
            // Main App Header Bar
            HStack(spacing: 12) {
                SignalMark(size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PetSignal")
                        .font(.headline.weight(.bold))
                    Label("300m Privacy Grid Active", systemImage: "lock.shield.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: onCreateReport) {
                    Label("New report", systemImage: "plus")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(PetSignalTheme.green, in: Capsule())
                        .foregroundStyle(.white)
                }
                .frame(minHeight: 44)
                .accessibilityHint("Opens the report creation form")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(PetSignalTheme.border.opacity(0.4), lineWidth: 1)
            )

            // Scrollable Quick Filter Chips Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(
                        title: "All (\(visibleReports.count))",
                        isSelected: kindFilter == nil && speciesFilter == nil
                    ) {
                        kindFilter = nil
                        speciesFilter = nil
                    }

                    ForEach(ReportKind.allCases) { kind in
                        filterChip(
                            title: kind.rawValue,
                            isSelected: kindFilter == kind
                        ) {
                            kindFilter = (kindFilter == kind) ? nil : kind
                        }
                    }

                    ForEach(AnimalSpecies.allCases) { species in
                        filterChip(
                            title: species.rawValue,
                            isSelected: speciesFilter == species
                        ) {
                            speciesFilter = (speciesFilter == species) ? nil : species
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(PetSignalTheme.green) : AnyShapeStyle(.regularMaterial),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? PetSignalTheme.green : PetSignalTheme.border.opacity(0.5),
                        lineWidth: 1
                    )
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func selectedReportDock(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Selected 300m Privacy Zone", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Tap for details & safety")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            NavigationLink(value: report.id) {
                ReportCard(
                    report: report,
                    isSaved: reportStore.savedReportIDs.contains(report.id)
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens full report details, safety guidance, and follow-ups")
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(PetSignalTheme.border.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityFocused($focusedReportID, equals: report.id)
    }

    private var emptyStateText: String {
        if kindFilter != nil || speciesFilter != nil {
            return "No active reports match the selected filters."
        }
        return "Active missing-pet and sighting reports appear on this map."
    }
}
