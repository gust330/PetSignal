import XCTest
@testable import PetSignal

@MainActor
final class ReportStoreTests: XCTestCase {
    func testPublishedLocationIsPrivacyRounded() {
        let store = ReportStore(reports: [])
        var draft = ReportDraft()
        draft.summary = "Small dog wearing a blue collar"
        draft.location = GeoPoint(latitude: 38.72234, longitude: -9.13926)

        let reportID = store.add(draft)
        guard let report = store.report(withID: reportID) else {
            return XCTFail("Published report was not stored")
        }

        XCTAssertEqual(report.location.latitude, 38.721, accuracy: 0.000_001)
        XCTAssertEqual(report.location.longitude, -9.138, accuracy: 0.000_001)
        XCTAssertTrue(store.createdReportIDs.contains(reportID))
    }

    func testResolvingReportRemovesItFromActiveState() {
        let store = ReportStore(reports: [])
        var draft = ReportDraft()
        draft.kind = .missing
        draft.summary = "Orange cat with a green collar"
        let reportID = store.add(draft)

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
        let parentID = store.add(parentDraft)

        var followUpDraft = ReportDraft()
        followUpDraft.kind = .sighting
        followUpDraft.summary = "Black dog seen nearby"
        followUpDraft.linkedReportID = parentID
        let followUpID = store.add(followUpDraft)

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

        let followUpID = store.add(followUpDraft)
        let followUp = store.report(withID: followUpID)

        XCTAssertEqual(followUp?.kind, .sighting)
        XCTAssertEqual(followUp?.species, .dog)
    }
}
