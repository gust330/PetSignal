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
    @State private var isShowingDetail = false
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
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                mapHeader
            }
            .safeAreaInset(edge: .bottom, spacing: 10) {
                if let selectedReportID,
                   let report = reportStore.report(withID: selectedReportID) {
                    selectedReportCard(report)
                        .padding(.horizontal, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $isShowingDetail, onDismiss: {
                selectedReportID = nil
            }) {
                if let selectedReportID {
                    NavigationStack {
                        ReportDetailView(reportID: selectedReportID)
                    }
                    .presentationDetents([.large])
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(.snappy, value: selectedReportID)
        }
    }

    private var mapHeader: some View {
        VStack(spacing: 10) {
            HStack {
                SignalMark(size: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text("PetSignal")
                        .font(.headline.weight(.bold))
                    Text("\(visibleReports.count) active nearby")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(Color.petSignalGreen).frame(width: 7, height: 7)
                    Text("Community live")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(.thinMaterial, in: Capsule())
            }

            HStack(spacing: 8) {
                filterButton("All", systemImage: "map.fill", value: nil)
                ForEach(ReportKind.allCases) { kind in
                    filterButton(kind.rawValue, systemImage: kind.systemImage, value: kind)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func selectedReportCard(_ report: AnimalReport) -> some View {
        HStack(spacing: 12) {
            ReportImage(report: report)
                .frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 4) {
                TypePill(kind: report.kind)
                Text(report.displayName)
                    .font(.headline)
                Text(report.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button {
                isShowingDetail = true
            } label: {
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.petSignalGreen, in: Circle())
            }
            .accessibilityLabel("View \(report.displayName)")
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(filter == value ? .white : .primary)
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(
                    filter == value ? Color.petSignalGreen : Color(uiColor: .tertiarySystemFill),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
