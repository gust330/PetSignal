import Foundation
import Observation

@MainActor
@Observable
final class ReportStore {
    private(set) var reports: [AnimalReport]

    init(reports: [AnimalReport] = AnimalReport.samples) {
        self.reports = reports
    }

    func add(_ draft: ReportDraft) {
        let report = AnimalReport(
            id: UUID(),
            kind: draft.kind,
            species: draft.species,
            petName: draft.petName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            details: draft.details.trimmingCharacters(in: .whitespacesAndNewlines),
            location: draft.location,
            reportedAt: Date(),
            lastSeenAt: draft.lastSeenAt,
            imageData: draft.imageData,
            status: .active
        )
        reports.insert(report, at: 0)
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
            status: .active
        )
    ]
}
