import Foundation

struct MatchCandidate: Identifiable, Equatable {
    let report: AnimalReport
    let score: Double
    let distanceKilometers: Double
    let hoursApart: Double
    let sharedTraits: [String]

    var id: UUID { report.id }

    var strengthLabel: String {
        guard !sharedTraits.isEmpty else { return "Location and time align" }
        switch score {
        case 0.72...: return "More details align"
        case 0.54...: return "Some details align"
        default: return "Possible match"
        }
    }
}

struct ReportMatcher {
    func candidates(
        for source: AnimalReport,
        among reports: [AnimalReport],
        minimumScore: Double = 0.35
    ) -> [MatchCandidate] {
        guard source.status == .active else { return [] }

        return reports.compactMap { candidate in
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
            let sourceText = "\(source.summary) \(source.details)"
            let candidateText = "\(candidate.summary) \(candidate.details)"
            let traits = sharedTokens(sourceText, candidateText)
            let traitScore = tokenSimilarity(sourceText, candidateText)
            let score = distanceScore * 0.5 + recencyScore * 0.25 + traitScore * 0.25

            guard score >= minimumScore else { return nil }
            return MatchCandidate(
                report: candidate,
                score: score,
                distanceKilometers: distance,
                hoursApart: hoursApart,
                sharedTraits: Array(traits.prefix(3))
            )
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

    private func sharedTokens(_ first: String, _ second: String) -> [String] {
        tokens(in: first).intersection(tokens(in: second)).sorted()
    }

    private func tokens(in value: String) -> Set<String> {
        let stopWords: Set<String> = [
            "and", "animal", "near", "reported", "seen", "the", "this", "with"
        ]
        return Set(
            value.lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count > 2 && !stopWords.contains($0) }
        )
    }

    private func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }
}
