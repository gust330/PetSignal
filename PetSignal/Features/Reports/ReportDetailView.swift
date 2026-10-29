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
                        // 1. Hero Image / Thumbnail + Privacy EXIF Badge + Signal ID Telemetry
                        heroSection(report)

                        // 2. Status Banner: Reunited Celebration or Calm Safety Guidance
                        if report.status != .active {
                            resolvedBanner(report)
                        } else {
                            SafetyBanner(kind: report.kind)
                        }

                        // 3. Title, Timestamp & Summary
                        overviewSection(report)

                        // 4. Animal Attributes 2x2 Grid (Bento)
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
                    .padding(.bottom, report.status == .active ? 88 : 24)
                }
                .background(PetSignalTheme.canvas)
                .safeAreaInset(edge: .bottom) {
                    if report.status == .active {
                        bottomActionBar(report)
                    }
                }
                .navigationTitle(report.signalID)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(item: shareText(for: report)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(PetSignalTheme.coral)
                        }
                        Button {
                            reportStore.toggleSaved(report.id)
                        } label: {
                            Image(systemName: reportStore.savedReportIDs.contains(report.id)
                                  ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(PetSignalTheme.coral)
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
                    Text("This updates the community radar status so neighbors know the animal is safe.")
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

    // MARK: - Hero Section with Signal ID Telemetry

    private func heroSection(_ report: AnimalReport) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: PetSignalTheme.cardRadius, style: .continuous)
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
                            ZStack {
                                Circle()
                                    .fill(report.kind.tint.opacity(0.12))
                                    .frame(width: 88, height: 88)
                                Image(systemName: report.species.systemImage)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(report.status != .active ? PetSignalTheme.emerald : report.kind.tint)
                            }
                            Text("COMMUNITY RADAR TELEMETRY • VERIFIED")
                                .font(.system(size: 10, weight: .bold).monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: PetSignalTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PetSignalTheme.cardRadius, style: .continuous)
                        .strokeBorder(PetSignalTheme.cardBorder, lineWidth: 1)
                )

            // Top Status Bar: Live SignalStatusBadge & Signal ID
            VStack {
                HStack {
                    SignalStatusBadge(kind: report.kind, status: report.status)
                    Spacer()
                    Text(report.signalID)
                        .font(.system(size: 11, weight: .bold).monospaced())
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(PetSignalTheme.hudBorder, lineWidth: 1))
                        .foregroundStyle(.primary)
                }
                Spacer()
                HStack {
                    Spacer()
                    Label("300m Privacy Area", systemImage: "lock.shield.fill")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(PetSignalTheme.hudBorder, lineWidth: 1))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Resolved Celebration Banner

    private func resolvedBanner(_ report: AnimalReport) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(PetSignalTheme.emerald)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.status == .reunited ? "This pet has been safely reunited" : "This animal has been secured & safe")
                    .font(.subheadline.weight(.bold))
                Text("Thank you to the community sentinels who shared sightings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetSignalTheme.emerald.opacity(0.12), in: RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                .strokeBorder(PetSignalTheme.emerald.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Overview Section

    private func overviewSection(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(report.displayName)
                    .font(.title2.weight(.black))
                    .tracking(-0.4)
                    .foregroundStyle(.primary)

                Spacer()

                Text(report.signalID)
                    .font(.system(size: 12, weight: .bold).monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Label {
                    Text(report.lastSeenAt, style: .relative)
                } icon: {
                    Image(systemName: "clock.fill")
                }
                Text("•")
                Label(report.location.approximateAreaDescription, systemImage: "dot.scope")
            }
            .font(.system(size: 12, weight: .medium).monospaced())
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

    // MARK: - 2x2 Attributes Grid (Bento)

    private func attributesGrid(_ report: AnimalReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            AttributeCell(label: "SPECIES", value: report.species.rawValue)
            AttributeCell(label: "SIGNAL STATUS", value: report.status.displayName)
            AttributeCell(label: "CATEGORY", value: report.kind == .missing ? "Lost Signal" : "Sighting Alert")
            AttributeCell(label: "PRIVACY MESH", value: "~300m Grid")
        }
    }

    // MARK: - Location Card

    private func locationSection(_ report: AnimalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Approximate Radar Area", systemImage: "dot.scope")
                    .font(.headline.weight(.bold))
                    .tracking(-0.2)
                Spacer()
                Text("~300m Mesh")
                    .font(.system(size: 10, weight: .bold).monospaced())
                    .foregroundStyle(PetSignalTheme.coral)
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
            .clipShape(RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
            .allowsHitTesting(false)

            Text("Public location is snapped to an approximate 300-meter grid centered around \(report.location.approximateAreaDescription). Private home addresses and precise GPS coordinates are never published.")
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
                    .foregroundStyle(PetSignalTheme.emerald)
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

    // MARK: - Explainable Candidate Matches (AI Match Engine)

    private func explainableMatchesSection(_ report: AnimalReport) -> some View {
        let candidates = ReportMatcher().candidates(for: report, among: reportStore.reports)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI Match Engine")
                    .font(.headline.weight(.bold))
                    .tracking(-0.2)
                Spacer()
                Text("Neural Telemetry • Suggestions")
                    .font(.system(size: 10, weight: .bold).monospaced())
                    .foregroundStyle(.secondary)
            }

            if candidates.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No candidate sighting matches in this radar zone yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("When neighbors publish sightings aligned by time, proximity, or traits, they will appear here with explainable match scores.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PetSignalTheme.subtleSurface, in: RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                        .strokeBorder(PetSignalTheme.cardBorder, lineWidth: 1)
                )
            } else {
                ForEach(candidates) { match in
                    NavigationLink {
                        ReportDetailView(reportID: match.report.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                AIMatchConfidencePill(score: Int((match.score * 100).rounded()))
                                Text(match.report.displayName)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }

                            Text("Explainable Alignment Factors:")
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
                        .background(PetSignalTheme.cardSurface, in: RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                                .strokeBorder(PetSignalTheme.indigo.opacity(0.35), lineWidth: 1.5)
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
            Text("Manage Signal")
                .font(.headline.weight(.bold))

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

    // MARK: - Bottom Action Bar (Primary Coral Gradient CTA)

    private func bottomActionBar(_ report: AnimalReport) -> some View {
        HStack(spacing: 10) {
            Button {
                isShowingFollowUp = true
            } label: {
                Label(
                    report.kind == .missing ? "Report Sighting" : "Log Follow-up",
                    systemImage: "eye.fill"
                )
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(PetSignalTheme.coralGradient, in: RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
                .foregroundStyle(.white)
                .shadow(color: PetSignalTheme.coral.opacity(0.35), radius: 8, y: 2)
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
                .background(PetSignalTheme.cardSurface, in: RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PetSignalTheme.buttonRadius, style: .continuous)
                        .strokeBorder(PetSignalTheme.cardBorder, lineWidth: 1)
                )
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassHUD(cornerRadius: 0)
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
        "\(report.kind.rawValue): \(report.displayName). \(report.summary) Last seen \(report.lastSeenAt.formatted(date: .abbreviated, time: .shortened)). Shared via PetSignal Radar."
    }
}
