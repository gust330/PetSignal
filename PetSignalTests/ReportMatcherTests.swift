import XCTest
@testable import PetSignal

final class ReportMatcherTests: XCTestCase {
    func testNearbyOppositeReportIsSuggested() {
        let reports = AnimalReport.samples
        let sighting = reports.first { $0.kind == .sighting }!

        let candidates = ReportMatcher().candidates(for: sighting, among: reports)

        XCTAssertEqual(candidates.first?.report.petName, "Luna")
        XCTAssertGreaterThan(candidates.first?.score ?? 0, 0.5)
    }

    func testResolvedSourceDoesNotProduceCandidates() {
        var resolvedSource = AnimalReport.samples.first { $0.kind == .sighting }!
        resolvedSource.status = .safe

        let candidates = ReportMatcher().candidates(
            for: resolvedSource,
            among: AnimalReport.samples
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testReportsOfSameKindAreNotSuggested() {
        let missingReport = AnimalReport.samples.first { $0.kind == .missing }!

        let candidates = ReportMatcher().candidates(
            for: missingReport,
            among: [missingReport]
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testDistanceUsesGeographicCoordinates() {
        let distance = ReportMatcher().distanceKilometers(
            from: GeoPoint(latitude: 38.7223, longitude: -9.1393),
            to: GeoPoint(latitude: 38.7323, longitude: -9.1393)
        )

        XCTAssertEqual(distance, 1.11, accuracy: 0.02)
    }
}
