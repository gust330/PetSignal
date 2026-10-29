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
                        // Privacy-by-Default 300m Approximate Area Circle (Tactical Radar Pulse)
                        MapCircle(center: report.location.coordinate, radius: 300)
                            .foregroundStyle(report.kind.tint.opacity(selectedReportID == report.id ? 0.30 : 0.16))
                            .stroke(
                                report.kind.tint,
                                lineWidth: selectedReportID == report.id ? 3 : 1.5
                            )
                            .mapOverlayLevel(level: .aboveRoads)

                        // 3. Custom PetPinMarker with Avatar, Semantic Ring & Radar Wave
                        Annotation(
                            report.displayName,
                            coordinate: report.location.coordinate,
                            anchor: .bottom
                        ) {
                            Button {
                                selectedReportID = report.id
                            } label: {
                                PetPinMarker(
                                    report: report,
                                    isSelected: selectedReportID == report.id
                                )
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

                // 4. Floating GlassNavigationHUD Top Header
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
                        "No Active Radar Signals",
                        systemImage: "dot.radiowaves.left.and.right",
                        description: Text(emptyStateText)
                    )
                    .padding(20)
                    .glassHUD(cornerRadius: PetSignalTheme.cardRadius)
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

    // MARK: - 4. Floating GlassNavigationHUD Header

    private var topFloatingHeader: some View {
        VStack(spacing: 8) {
            // Main Glass Navigation Bar
            HStack(spacing: 12) {
                SignalMark(size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("PETSIGNAL")
                            .font(.system(size: 14, weight: .black))
                            .tracking(0.6)
                            .foregroundStyle(.primary)

                        Text("RADAR")
                            .font(.system(size: 10, weight: .bold).monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PetSignalTheme.coral.opacity(0.15))
                            .foregroundStyle(PetSignalTheme.coral)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(PetSignalTheme.coral)
                            .frame(width: 5, height: 5)
                        Text("\(visibleReports.count) ACTIVE SIGNALS • ~300m MESH")
                            .font(.system(size: 10, weight: .bold).monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                // Primary Brand Broadcast CTA Button
                Button(action: onCreateReport) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("Broadcast")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(PetSignalTheme.coralGradient, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: PetSignalTheme.coral.opacity(0.35), radius: 8, y: 2)
                }
                .frame(minHeight: 44)
                .accessibilityHint("Opens the report creation form")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassHUD(cornerRadius: 22)

            // Scrollable Quick Filter Chips Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(
                        title: "ALL (\(visibleReports.count))",
                        isSelected: kindFilter == nil && speciesFilter == nil
                    ) {
                        kindFilter = nil
                        speciesFilter = nil
                    }

                    ForEach(ReportKind.allCases) { kind in
                        filterChip(
                            title: kind == .missing ? "LOST" : "SIGHTINGS",
                            isSelected: kindFilter == kind
                        ) {
                            kindFilter = (kindFilter == kind) ? nil : kind
                        }
                    }

                    ForEach(AnimalSpecies.allCases) { species in
                        filterChip(
                            title: species.rawValue.uppercased(),
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
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(PetSignalTheme.coral)
                        : AnyShapeStyle(PetSignalTheme.elevatedGlassHUD),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? PetSignalTheme.coral : PetSignalTheme.cardBorder,
                        lineWidth: 1
                    )
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Selected Report Floating Dock (Modal Sheet Radius 28px)

    private func selectedReportDock(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Drag grab handle
            RoundedRectangle(cornerRadius: 99, style: .continuous)
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "crosshair")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PetSignalTheme.coral)
                    Text("ACTIVE RADAR INTEL")
                        .font(.system(size: 10, weight: .bold).monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Tap for details")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            let matchCount = ReportMatcher().candidates(for: report, among: reportStore.reports).count
            NavigationLink(value: report.id) {
                ReportCard(
                    report: report,
                    isSaved: reportStore.savedReportIDs.contains(report.id),
                    candidateMatchCount: matchCount,
                    isSelected: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens full report details, safety guidance, and follow-ups")
        }
        .padding(12)
        .glassHUD(cornerRadius: PetSignalTheme.modalRadius)
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
