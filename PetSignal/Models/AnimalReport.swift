import CoreLocation
import Foundation

struct AnimalReport: Identifiable, Hashable {
    let id: UUID
    let kind: ReportKind
    let species: AnimalSpecies
    let petName: String?
    let summary: String
    let details: String
    let location: GeoPoint
    let reportedAt: Date
    let lastSeenAt: Date
    let imageData: Data?
    var linkedReportID: UUID?
    var status: ReportStatus

    var displayName: String {
        guard let petName, !petName.isEmpty else {
            return kind == .missing ? "Missing \(species.rawValue)" : "\(species.rawValue) sighting"
        }
        return petName
    }
}

enum ReportKind: String, CaseIterable, Identifiable, Hashable {
    case missing = "Missing"
    case sighting = "Sighting"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .missing: return "magnifyingglass"
        case .sighting: return "eye.fill"
        }
    }
}

enum AnimalSpecies: String, CaseIterable, Identifiable, Hashable {
    case dog = "Dog"
    case cat = "Cat"
    case other = "Other"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .other: return "pawprint.fill"
        }
    }
}

enum ReportStatus: String, CaseIterable, Identifiable, Hashable {
    case active = "Active"
    case reunited = "Reunited"
    case safe = "Safe"
    case closed = "Closed"

    var id: Self { self }
}

struct GeoPoint: Hashable {
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var privacyRounded: GeoPoint {
        let precision = 0.003
        return GeoPoint(
            latitude: (latitude / precision).rounded() * precision,
            longitude: (longitude / precision).rounded() * precision
        )
    }
}

struct ReportDraft: Equatable {
    var kind = ReportKind.sighting
    var species = AnimalSpecies.dog
    var petName = ""
    var summary = ""
    var details = ""
    var location = GeoPoint(latitude: 38.7223, longitude: -9.1393)
    var lastSeenAt = Date()
    var imageData: Data?
    var linkedReportID: UUID?
}
