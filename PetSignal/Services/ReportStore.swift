import Foundation
import Observation

extension ReportStore {
    enum PublishError: Error, Equatable {
        case invalidLocation
        case invalidImage
    }
}

@MainActor
@Observable
final class ReportStore {
    private(set) var reports: [AnimalReport]
    private(set) var createdReportIDs = Set<UUID>()
    private(set) var savedReportIDs = Set<UUID>()

    init(reports: [AnimalReport] = AnimalReport.samples) {
        self.reports = reports
    }

    @discardableResult
    func add(_ draft: ReportDraft) throws -> UUID {
        guard (-90...90).contains(draft.location.latitude),
              (-180...180).contains(draft.location.longitude) else {
            throw PublishError.invalidLocation
        }

        let sanitizedImageData: Data?
        if let imageData = draft.imageData {
            guard let sanitized = ImageSanitizer.sanitizedJPEGData(from: imageData) else {
                throw PublishError.invalidImage
            }
            sanitizedImageData = sanitized
        } else {
            sanitizedImageData = nil
        }

        let id = UUID()
        let linkedReport: AnimalReport? = draft.linkedReportID.flatMap { linkedID in
            self.report(withID: linkedID)
        }
        let kind: ReportKind = linkedReport.map { linked in
            linked.kind == ReportKind.missing ? ReportKind.sighting : ReportKind.missing
        } ?? draft.kind
        let species = linkedReport?.species ?? draft.species
        let newReport = AnimalReport(
            id: id,
            kind: kind,
            species: species,
            petName: draft.petName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            details: draft.details.trimmingCharacters(in: .whitespacesAndNewlines),
            location: draft.location.privacyRounded,
            reportedAt: Date(),
            lastSeenAt: draft.lastSeenAt,
            imageData: sanitizedImageData,
            linkedReportID: draft.linkedReportID,
            status: .active
        )
        reports.insert(newReport, at: 0)
        createdReportIDs.insert(id)
        return id
    }

    func report(withID id: UUID) -> AnimalReport? {
        reports.first { $0.id == id }
    }

    func toggleSaved(_ id: UUID) {
        if savedReportIDs.contains(id) {
            savedReportIDs.remove(id)
        } else {
            savedReportIDs.insert(id)
        }
    }

    func updateStatus(_ status: ReportStatus, for id: UUID) {
        guard let index = reports.firstIndex(where: { $0.id == id }) else { return }
        reports[index].status = status
    }

    func delete(_ id: UUID) {
        guard createdReportIDs.contains(id) else { return }
        for index in reports.indices where reports[index].linkedReportID == id {
            reports[index].linkedReportID = nil
        }
        reports.removeAll { $0.id == id }
        createdReportIDs.remove(id)
        savedReportIDs.remove(id)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

extension AnimalReport {
    static let samples: [AnimalReport] = [
        AnimalReport(
            id: UUID(uuidString: "EE23D9E0-F49E-4328-AED5-64307179991A")!,
            kind: .missing,
            species: .dog,
            petName: "Luna",
            summary: "Small black dog with a white chest",
            details: "Very shy. Wearing a red collar. Please do not chase her.",
            location: GeoPoint(latitude: 38.7247, longitude: -9.1455),
            reportedAt: Date().addingTimeInterval(-7_200),
            lastSeenAt: Date().addingTimeInterval(-10_800),
            imageData: nil,
            linkedReportID: nil,
            status: .active
        ),
        AnimalReport(
            id: UUID(uuidString: "12236AE4-481D-4696-973D-931E9D1158CF")!,
            kind: .sighting,
            species: .dog,
            petName: nil,
            summary: "Black dog seen near the garden",
            details: "Small dog with white fur on its chest, moving west alone.",
            location: GeoPoint(latitude: 38.7266, longitude: -9.1510),
            reportedAt: Date().addingTimeInterval(-1_800),
            lastSeenAt: Date().addingTimeInterval(-2_400),
            imageData: nil,
            linkedReportID: UUID(uuidString: "EE23D9E0-F49E-4328-AED5-64307179991A"),
            status: .active
        ),
        AnimalReport(
            id: UUID(uuidString: "07303F32-6201-4F6A-8A70-832B18E8EAC8")!,
            kind: .missing,
            species: .cat,
            petName: "Milo",
            summary: "Orange tabby with green eyes",
            details: "Indoor cat and likely hiding. Microchipped.",
            location: GeoPoint(latitude: 38.7169, longitude: -9.1378),
            reportedAt: Date().addingTimeInterval(-86_400),
            lastSeenAt: Date().addingTimeInterval(-90_000),
            imageData: nil,
            linkedReportID: nil,
            status: .active
        ),
        AnimalReport(
            id: UUID(uuidString: "8791FD34-1F4E-4669-A657-F50E8A789BE1")!,
            kind: .missing,
            species: .dog,
            petName: "Toby",
            summary: "Senior golden retriever",
            details: "Found by a volunteer and reunited with his family.",
            location: GeoPoint(latitude: 38.7350, longitude: -9.1480),
            reportedAt: Date().addingTimeInterval(-259_200),
            lastSeenAt: Date().addingTimeInterval(-262_800),
            imageData: nil,
            linkedReportID: nil,
            status: .reunited
        )
    ]
}
