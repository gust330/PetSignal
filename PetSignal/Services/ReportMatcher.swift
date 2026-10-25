import Foundation

struct MatchCandidate: Identifiable, Equatable {
    let report: AnimalReport
    let score: Double
    let distanceKilometers: Double

    var id: UUID { report.id }
}

struct ReportMatcher {
    func candidates(
        for source: AnimalReport,
        among reports: [AnimalReport],
        minimumScore: Double = 0.35
    ) -> [MatchCandidate] {
        reports.compactMap { candidate in
            guard candidate.id != source.id,
                  candidate.kind != source.kind,
                  candidate.species == source.species,
                  candidate.status == .active else {
                return nil
            }

            let distance = distanceKilometers(from: source.location, to: candidate.location)
            let distanceScore = max(0, 1 - distance / 20)
            let hoursApart = abs(source.lastSeenAt.timeIntervalSince(candidate.lastSeenAt)) / 3_600
            let recencyScore = max(0, 1 - hoursApart / (24 * 14))
            let traitScore = tokenSimilarity(
                "\(source.summary) \(source.details)",
                "\(candidate.summary) \(candidate.details)"
            )
            let score = distanceScore * 0.5 + recencyScore * 0.25 + traitScore * 0.25

            guard score >= minimumScore else { return nil }
            return MatchCandidate(report: candidate, score: score, distanceKilometers: distance)
        }
        .sorted { $0.score > $1.score }
    }

    func distanceKilometers(from start: GeoPoint, to end: GeoPoint) -> Double {
        let earthRadius = 6_371.0
        let latitudeDelta = degreesToRadians(end.latitude - start.latitude)
        let longitudeDelta = degreesToRadians(end.longitude - start.longitude)
        let startLatitude = degreesToRadians(start.latitude)
        let endLatitude = degreesToRadians(end.latitude)
        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    private func tokenSimilarity(_ first: String, _ second: String) -> Double {
        let firstTokens = tokens(in: first)
        let secondTokens = tokens(in: second)
        guard !firstTokens.isEmpty, !secondTokens.isEmpty else { return 0 }
        return Double(firstTokens.intersection(secondTokens).count)
            / Double(firstTokens.union(secondTokens).count)
    }

    private func tokens(in value: String) -> Set<String> {
        Set(
            value.lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count > 2 }
        )
    }

    private func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }
}
