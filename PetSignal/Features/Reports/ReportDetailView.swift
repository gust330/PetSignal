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
                        // 1. Hero Image / Thumbnail + Privacy EXIF Badge
                        heroSection(report)

                        // 2. Status Banner: Reunited Celebration or Calm Safety Guidance
                        if report.status != .active {
                            resolvedBanner(report)
                        } else {
                            SafetyBanner(kind: report.kind)
                        }

                        // 3. Title, Timestamp & Summary
                        overviewSection(report)

                        // 4. Animal Attributes 2x2 Grid
                        attributesGrid(report)

                        // 5. Approximate Privacy Area Map Card
                        locationSection(report)

                        // 6. Connected / Linked Follow-Up Report (if applicable)
                        if let linkedReportID = report.linkedReportID,
                           let linkedReport = reportStore.report(withID: linkedReportID) {
                            connectedReportCard(linkedReport)
                        }

                        // 7. Explainable Candidate Matches
                        explainableMatchesSection(report)

                        // 8. Management Section (for device owner)
                        if reportStore.createdReportIDs.contains(report.id) {
                            managementSection(report)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, report.status == .active ? 80 : 20)
                }
                .background(PetSignalTheme.canvas)
                .safeAreaInset(edge: .bottom) {
                    if report.status == .active {
                        bottomActionBar(report)
                    }
                }
                .navigationTitle("Report Details")
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
                    }
                }
                .sheet(isPresented: $isShowingFollowUp) {
                    NewReportView(followingUpOn: report)
                }
                .confirmationDialog(resolveTitle(for: report), isPresented: $isShowingResolveConfirmation, titleVisibility: .visible) {
                    Button(resolveActionTitle(for: report)) {
                        reportStore.updateStatus(resolveStatus(for: report), for: report.id)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This updates the community report status so neighbors know the animal is safe.")
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
                    "Report Unavailable",
                    systemImage: "exclamationmark.circle",
                    description: Text("It may have been removed or is no longer available.")
                )
                .background(PetSignalTheme.canvas)
            }
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ report: AnimalReport) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(PetSignalTheme.subtleSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay {
                    if let imageData = report.imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: report.species.systemImage)
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundStyle(report.status != .active ? PetSignalTheme.green : report.kind.tint)
                            Text("EXIF Metadata Stripped • Community Verified")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(PetSignalTheme.border.opacity(0.4), lineWidth: 1)
                )

            HStack {
                StatusPillBadge(kind: report.kind, status: report.status)
                Spacer()
                Label("300m Privacy Area", systemImage: "lock.shield.fill")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(PetSignalTheme.border.opacity(0.5), lineWidth: 1))
            }
            .padding(14)
        }
    }

    // MARK: - Resolved Celebration Banner

    private func resolvedBanner(_ report: AnimalReport) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(PetSignalTheme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.status == .reunited ? "This pet has been reported reunited" : "This animal has been reported safe")
                    .font(.subheadline.weight(.bold))
                Text("Thank you to the neighbors who shared sightings and kept watch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetSignalTheme.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(PetSignalTheme.green.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Overview Section

    private func overviewSection(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(report.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Label {
                    Text(report.lastSeenAt, style: .relative)
                } icon: {
                    Image(systemName: "clock.fill")
                }
                Text("•")
                Label(report.location.approximateAreaDescription, systemImage: "mappin.and.ellipse")
            }
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)

            Text(report.summary)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.top, 2)

            if !report.details.isEmpty {
                Text(report.details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .petSignalCard()
    }

    // MARK: - 2x2 Attributes Grid

    private func attributesGrid(_ report: AnimalReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            AttributeCell(label: "SPECIES", value: report.species.rawValue)
            AttributeCell(label: "STATUS", value: report.status.displayName)
            AttributeCell(label: "CATEGORY", value: report.kind.rawValue)
            AttributeCell(label: "PRIVACY ZONE", value: "~300m Grid")
        }
    }

    // MARK: - Location Card

    private func locationSection(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Approximate Location", systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                Spacer()
                Text("Grid Snapped")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetSignalTheme.green)
            }

            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: report.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                )
            )) {
                MapCircle(center: report.location.coordinate, radius: 300)
                    .foregroundStyle(report.kind.tint.opacity(0.24))
                    .stroke(report.kind.tint, lineWidth: 2)
                    .mapOverlayLevel(level: .aboveRoads)

                Annotation(report.displayName, coordinate: report.location.coordinate) {
                    Circle()
                        .fill(report.kind.tint)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)

            Text("Public location is snapped to an approximate 300-meter grid centered around \(report.location.approximateAreaDescription). Private home addresses and precise coordinates are never published.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .petSignalCard()
    }

    // MARK: - Connected Report

    private func connectedReportCard(_ linked: AnimalReport) -> some View {
        NavigationLink {
            ReportDetailView(reportID: linked.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(PetSignalTheme.green)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Connected Sighting / Report")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(linked.displayName)
                        .font(.subheadline.weight(.bold))
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

    // MARK: - Explainable Candidate Matches

    private func explainableMatchesSection(_ report: AnimalReport) -> some View {
        let candidates = ReportMatcher().candidates(for: report, among: reportStore.reports)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Possible Related Reports")
                    .font(.headline)
                Spacer()
                Text("Suggestions • Not guaranteed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if candidates.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No candidate matches found nearby yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("When neighbors publish matching sightings or reports in this area, they will appear here with explainable alignment reasons.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PetSignalTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(PetSignalTheme.border.opacity(0.5), lineWidth: 1)
                )
            } else {
                ForEach(candidates) { match in
                    NavigationLink {
                        ReportDetailView(reportID: match.report.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .foregroundStyle(PetSignalTheme.teal)
                                Text(match.report.displayName)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Suggested")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(PetSignalTheme.teal.opacity(0.15), in: Capsule())
                                    .foregroundStyle(PetSignalTheme.teal)
                            }

                            Text("Why this is suggested:")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    MatchReasonChip(
                                        text: String(format: "~%.1fkm away", match.distanceKilometers),
                                        icon: "location.north.line.fill"
                                    )
                                    MatchReasonChip(
                                        text: timeGapText(match.hoursApart),
                                        icon: "clock.arrow.circlepath"
                                    )
                                    ForEach(match.sharedTraits, id: \.self) { trait in
                                        MatchReasonChip(text: trait, icon: "checkmark.circle.fill")
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(PetSignalTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(PetSignalTheme.teal.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .petSignalCard()
    }

    // MARK: - Device Management Section

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
                .frame(minHeight: 44)

                Button {
                    reportStore.updateStatus(.closed, for: report.id)
                } label: {
                    Label("Close report", systemImage: "archivebox")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete report", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
        }
        .petSignalCard()
    }

    // MARK: - Bottom Action Bar

    private func bottomActionBar(_ report: AnimalReport) -> some View {
        HStack(spacing: 10) {
            Button {
                isShowingFollowUp = true
            } label: {
                Label(
                    report.kind == .missing ? "I saw this animal" : "Log follow-up sighting",
                    systemImage: "eye.fill"
                )
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(PetSignalTheme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)
            }

            Button {
                isShowingResolveConfirmation = true
            } label: {
                Label(
                    report.kind == .missing ? "Reunited" : "Safe",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(PetSignalTheme.subtleSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(PetSignalTheme.border.opacity(0.5), lineWidth: 1)
                )
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Helpers

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
        if hours < 1 { return "< 1 hr apart" }
        if hours < 24 { return "\(Int(hours.rounded())) hr apart" }
        return "\(Int((hours / 24).rounded())) d apart"
    }

    private func shareText(for report: AnimalReport) -> String {
        "\(report.kind.rawValue): \(report.displayName). \(report.summary) Last seen \(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened)). Shared via PetSignal."
    }
}
