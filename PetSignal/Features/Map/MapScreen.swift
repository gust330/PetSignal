import MapKit
import SwiftUI

struct MapScreen: View {
    @Environment(ReportStore.self) private var reportStore
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var selectedReportID: UUID?
    @State private var selectedReport: AnimalReport?
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
            .mapStyle(.standard(elevation: .realistic))
            .safeAreaInset(edge: .top) {
                filterBar
            }
            .onChange(of: selectedReportID) { _, reportID in
                selectedReport = reportStore.reports.first { $0.id == reportID }
            }
            .sheet(item: $selectedReport, onDismiss: {
                selectedReportID = nil
            }) { report in
                NavigationStack {
                    ReportDetailView(report: report)
                }
                .presentationDetents([.medium, .large])
            }
            .navigationTitle("Nearby animals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterButton("All", value: nil)
            ForEach(ReportKind.allCases) { kind in
                filterButton(kind.rawValue, value: kind)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func filterButton(_ title: String, value: ReportKind?) -> some View {
        Button(title) {
            filter = value
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(filter == value ? .accentColor : .secondary)
    }
}
