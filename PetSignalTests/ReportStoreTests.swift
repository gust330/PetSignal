import XCTest
@testable import PetSignal

@MainActor
final class ReportStoreTests: XCTestCase {
    func testPublishingRejectsOutOfRangeCoordinates() {
        let store = ReportStore(reports: [])
        var invalidLatitude = ReportDraft()
        invalidLatitude.summary = "Dog near the station"
        invalidLatitude.location = GeoPoint(latitude: 90.1, longitude: -9.14)

        var invalidLongitude = invalidLatitude
        invalidLongitude.location = GeoPoint(latitude: 38.72, longitude: -180.1)

        XCTAssertThrowsError(try store.add(invalidLatitude))
        XCTAssertThrowsError(try store.add(invalidLongitude))
        XCTAssertTrue(store.reports.isEmpty)
    }

    func testPublishingRejectsInvalidImageData() {
        let store = ReportStore(reports: [])
        var draft = ReportDraft()
        draft.summary = "Dog near the station"
        draft.imageData = Data("not an image".utf8)

        XCTAssertThrowsError(try store.add(draft))
        XCTAssertTrue(store.reports.isEmpty)
    }

    func testPublishedLocationUsesAnApproximatelyThreeHundredMetrePrivacyGrid() {
        for latitude in [0.0, 38.72234, 60.0] {
            let point = GeoPoint(latitude: latitude, longitude: -9.13926)
            let rounded = point.privacyRounded
            let latitudeCellMetres = GeoPoint.privacyGridLatitudeDegrees * 111_320
            let longitudeCellMetres = GeoPoint.privacyGridLongitudeDegrees(at: latitude)
                * 111_320 * cos(latitude * .pi / 180)

            XCTAssertEqual(latitudeCellMetres, 300, accuracy: 1)
            XCTAssertEqual(longitudeCellMetres, 300, accuracy: 1)
            XCTAssertLessThanOrEqual(abs(rounded.latitude - latitude), GeoPoint.privacyGridLatitudeDegrees / 2 + 0.000_001)
            XCTAssertLessThanOrEqual(abs(rounded.longitude - point.longitude), GeoPoint.privacyGridLongitudeDegrees(at: latitude) / 2 + 0.000_001)
        }
    }

    func testPrivacyLongitudeGridUsesPublishedLatitudeCell() {
        let latitudeStep = GeoPoint.privacyGridLatitudeDegrees
        let cellCenter = 38.72234
        let first = GeoPoint(
            latitude: cellCenter - latitudeStep * 0.2,
            longitude: -9.13926
        ).privacyRounded
        let second = GeoPoint(
            latitude: cellCenter + latitudeStep * 0.2,
            longitude: -9.13926
        ).privacyRounded

        XCTAssertEqual(first.latitude, second.latitude, accuracy: 0.000_000_1)
        XCTAssertEqual(first.longitude, second.longitude, accuracy: 0.000_000_1)
    }

    func testPublishedLocationRemainsValidAtDatelineAndPoles() {
        let store = ReportStore(reports: [])

        for location in [
            GeoPoint(latitude: 89.9, longitude: 180),
            GeoPoint(latitude: 89.9, longitude: -180),
            GeoPoint(latitude: -89.9, longitude: 180),
            GeoPoint(latitude: -89.9, longitude: -180)
        ] {
            var draft = ReportDraft()
            draft.summary = "Animal seen near the dateline"
            draft.location = location

            let reportID = try! store.add(draft)
            guard let publishedLocation = store.report(withID: reportID)?.location else {
                return XCTFail("Published report was not stored")
            }

            XCTAssertTrue((-90...90).contains(publishedLocation.latitude))
            XCTAssertTrue((-180...180).contains(publishedLocation.longitude))
        }
    }

    func testPublishedLocationIsPrivacyRounded() {
        let store = ReportStore(reports: [])
        var draft = ReportDraft()
        draft.summary = "Small dog wearing a blue collar"
        draft.location = GeoPoint(latitude: 38.72234, longitude: -9.13926)

        let reportID = try! store.add(draft)
        guard let report = store.report(withID: reportID) else {
            return XCTFail("Published report was not stored")
        }

        XCTAssertNotEqual(report.location, draft.location)
        XCTAssertTrue(store.createdReportIDs.contains(reportID))
    }

    func testResolvingReportRemovesItFromActiveState() {
        let store = ReportStore(reports: [])
        var draft = ReportDraft()
        draft.kind = .missing
        draft.summary = "Orange cat with a green collar"
        let reportID = try! store.add(draft)

        store.updateStatus(.reunited, for: reportID)

        XCTAssertEqual(store.report(withID: reportID)?.status, .reunited)
    }

    func testSavedReportCanBeToggled() {
        let report = AnimalReport.samples[0]
        let store = ReportStore(reports: [report])

        store.toggleSaved(report.id)
        XCTAssertTrue(store.savedReportIDs.contains(report.id))

        store.toggleSaved(report.id)
        XCTAssertFalse(store.savedReportIDs.contains(report.id))
    }

    func testDeletingParentClearsFollowUpLink() {
        let store = ReportStore(reports: [])
        var parentDraft = ReportDraft()
        parentDraft.kind = .missing
        parentDraft.summary = "Missing black dog"
        let parentID = try! store.add(parentDraft)

        var followUpDraft = ReportDraft()
        followUpDraft.kind = .sighting
        followUpDraft.summary = "Black dog seen nearby"
        followUpDraft.linkedReportID = parentID
        let followUpID = try! store.add(followUpDraft)

        store.delete(parentID)

        XCTAssertNil(store.report(withID: followUpID)?.linkedReportID)
    }

    func testFollowUpInheritsOppositeKindAndSpecies() {
        let parent = AnimalReport.samples[0]
        let store = ReportStore(reports: [parent])
        var followUpDraft = ReportDraft()
        followUpDraft.kind = .missing
        followUpDraft.species = .cat
        followUpDraft.summary = "Possible sighting"
        followUpDraft.linkedReportID = parent.id

        let followUpID = try! store.add(followUpDraft)
        let followUp = store.report(withID: followUpID)

        XCTAssertEqual(followUp?.kind, .sighting)
        XCTAssertEqual(followUp?.species, .dog)
    }
}
