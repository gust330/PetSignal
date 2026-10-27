import MapKit
import SwiftUI

struct MapScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var filter: ReportKind?

    private var visibleReports: [AnimalReport] {
        reportStore.reports.filter { report in
            report.status == .active && (filter == nil || report.kind == filter)
        }
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedReportID) {
                ForEach(visibleReports) { report in
                    Marker(
                        report.displayName,
                        systemImage: report.kind.systemImage,
                        coordinate: report.location.coordinate
                    )
                    .tint(report.kind.tint)
                    .tag(report.id)
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .top, spacing: 0) { mapHeader }
            .safeAreaInset(edge: .bottom, spacing: 8) {
                if let selectedReportID,
                   let report = reportStore.report(withID: selectedReportID) {
                    selectedReportStrip(report)
                        .padding(.horizontal, 12)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay {
                if visibleReports.isEmpty {
                    ContentUnavailableView(
                        "No active reports",
                        systemImage: "map",
                        description: Text(filter == nil
                            ? "Published active reports will appear on this map."
                            : "No active \(filter?.rawValue.lowercased() ?? "") reports match this filter.")
                    )
                    .padding(20)
                    .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(reduceMotion ? nil : .snappy, value: selectedReportID)
        }
    }

    private var mapHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                SignalMark(size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("PetSignal")
                        .font(.headline.weight(.bold))
                    Text("\(visibleReports.count) active \(visibleReports.count == 1 ? "report" : "reports") on map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onCreateReport) {
                    Label("New report", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens the report form")
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { filterControls }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) { filterControls }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private var filterControls: some View {
        filterButton("All", systemImage: "map.fill", value: nil)
        ForEach(ReportKind.allCases) { kind in
            filterButton(kind.rawValue, systemImage: kind.systemImage, value: kind)
        }
        Spacer(minLength: 0)
    }

    private func selectedReportStrip(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ReportImage(report: report)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    TypePill(kind: report.kind)
                    Text(report.displayName)
                        .font(.headline)
                    Text(report.lastSeenAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            NavigationLink {
                ReportDetailView(reportID: report.id)
            } label: {
                Text("View report")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.petSignalGreen, in: RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityHint("Opens details and safe follow-up actions")
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func filterButton(_ title: String, systemImage: String, value: ReportKind?) -> some View {
        Button {
            filter = value
            if let selectedReportID,
               !visibleReports.contains(where: { $0.id == selectedReportID }) {
                self.selectedReportID = nil
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(filter == value ? .white : .primary)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    filter == value ? Color.petSignalGreen : Color(uiColor: .tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == value ? .isSelected : [])
        .accessibilityHint("Filters reports shown on the map")
    }
}
