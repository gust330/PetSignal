import MapKit
import SwiftUI

struct ReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReportStore.self) private var reportStore
    let reportID: UUID

    @State private var isShowingFollowUp = false
    @State private var isShowingResolveConfirmation = false
    @State private var isShowingDeleteConfirmation = false

    private var report: AnimalReport? {
        reportStore.report(withID: reportID)
    }

    var body: some View {
        Group {
            if let report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero(report)
                        summaryCard(report)
                        SafetyBanner(kind: report.kind)
                        locationCard(report)

                        if let linkedReportID = report.linkedReportID,
                           let linkedReport = reportStore.report(withID: linkedReportID) {
                            connectedReport(linkedReport)
                        }

                        matchesSection(report)

                        if reportStore.createdReportIDs.contains(report.id) {
                            managementSection(report)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, report.status == .active ? 100 : 28)
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .safeAreaInset(edge: .bottom) {
                    if report.status == .active {
                        actionBar(report)
                    }
                }
                .navigationTitle("Report details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(item: shareText(for: report)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button {
                            reportStore.toggleSaved(report.id)
                        } label: {
                            Image(systemName: reportStore.savedReportIDs.contains(report.id)
                                  ? "bookmark.fill" : "bookmark")
                        }
                        .accessibilityLabel(reportStore.savedReportIDs.contains(report.id)
                            ? "Remove saved report" : "Save report")
                        .accessibilityHint("Changes whether this report appears in Saved")
                    }
                }
                .sheet(isPresented: $isShowingFollowUp) {
                    NewReportView(followingUpOn: report)
                }
                .alert(resolveTitle(for: report), isPresented: $isShowingResolveConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button(resolveActionTitle(for: report)) {
                        reportStore.updateStatus(resolveStatus(for: report), for: report.id)
                    }
                } message: {
                    Text("This removes the report from the active map but keeps the outcome in Community.")
                }
                .alert("Delete this report?", isPresented: $isShowingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        reportStore.delete(report.id)
                        dismiss()
                    }
                } message: {
                    Text("This cannot be undone on this device.")
                }
            } else {
                ContentUnavailableView(
                    "Report unavailable",
                    systemImage: "exclamationmark.circle",
                    description: Text("It may have been removed or is no longer available.")
                )
            }
        }
    }

    private func hero(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportImage(report: report)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .accessibilityHidden(true)

            HStack {
                TypePill(kind: report.kind)
                StatusPill(status: report.status)
            }
            Text(report.displayName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.top, 8)
    }

    private func summaryCard(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(report.summary)
                .font(.title3.weight(.bold))
            if !report.details.isEmpty {
                Text(report.details)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    Label(report.species.rawValue, systemImage: report.species.systemImage)
                    Label(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label(report.species.rawValue, systemImage: report.species.systemImage)
                    Label(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .petSignalCard()
    }

    private func locationCard(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Approximate area")
                        .font(.headline)
                        Text("Shown on a roughly 300-metre privacy grid.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.petSignalGreen)
            }

            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: report.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                ),
                interactionModes: []
            ) {
                MapCircle(center: report.location.coordinate, radius: 220)
                    .foregroundStyle(report.kind.tint.opacity(0.22))
                    .stroke(report.kind.tint, lineWidth: 2)
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .petSignalCard()
    }

    @ViewBuilder
    private func matchesSection(_ report: AnimalReport) -> some View {
        let matches = ReportMatcher().candidates(for: report, among: reportStore.reports)
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SignalMark(size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Possible matches")
                            .font(.title3.weight(.bold))
                        Text("Suggestions, not identity confirmations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(matches) { match in
                    NavigationLink {
                        ReportDetailView(reportID: match.report.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text(match.report.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(match.strengthLabel)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.petSignalGreen)
                            }
                            HStack(spacing: 12) {
                                Label(
                                    "\(match.distanceKilometers, format: .number.precision(.fractionLength(1))) km",
                                    systemImage: "location.fill"
                                )
                                Label(timeGapText(match.hoursApart), systemImage: "clock.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            if !match.sharedTraits.isEmpty {
                                Text("Shared details: \(match.sharedTraits.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.petSignalGreen.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .petSignalCard()
        }
    }

    private func connectedReport(_ report: AnimalReport) -> some View {
        NavigationLink {
            ReportDetailView(reportID: report.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.petSignalGreen)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Connected report")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(report.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .petSignalCard()
        }
        .buttonStyle(.plain)
    }

    private func managementSection(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manage your report")
                .font(.headline)
            if report.status == .active {
                Button {
                    isShowingResolveConfirmation = true
                } label: {
                    Label(resolveActionTitle(for: report), systemImage: resolveStatus(for: report).systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                Button {
                    reportStore.updateStatus(.closed, for: report.id)
                } label: {
                    Label("Close report", systemImage: "archivebox")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete report", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
        }
        .petSignalCard()
    }

    private func actionBar(_ report: AnimalReport) -> some View {
        Button {
            isShowingFollowUp = true
        } label: {
            Label(
                report.kind == .missing ? "I saw this animal" : "This may be my pet",
                systemImage: report.kind == .missing ? "eye.fill" : "heart.fill"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.petSignalGreen, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func resolveStatus(for report: AnimalReport) -> ReportStatus {
        report.kind == .missing ? .reunited : .safe
    }

    private func resolveActionTitle(for report: AnimalReport) -> String {
        report.kind == .missing ? "Mark as reunited" : "Mark as safe"
    }

    private func resolveTitle(for report: AnimalReport) -> String {
        report.kind == .missing ? "Reunited with family?" : "Animal now safe?"
    }

    private func timeGapText(_ hours: Double) -> String {
        if hours < 1 { return "under 1 hr" }
        if hours < 24 { return "\(Int(hours.rounded())) hr apart" }
        return "\(Int((hours / 24).rounded())) d apart"
    }

    private func shareText(for report: AnimalReport) -> String {
        "\(report.kind.rawValue): \(report.displayName). \(report.summary) Last seen \(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened)). Shared via PetSignal."
    }
}
