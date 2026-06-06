import XCTest
import EmoPetKit
import EmoPetCore

final class PetEngineTests: XCTestCase {
    func testUnlockIsIrreversible() {
        var unlocked = UnlockedFeatures()
        unlocked.applyUnlocks(stage: .growth, intimacy: 70, ageDays: 25)
        XCTAssertTrue(unlocked.vocabularyBudding)

        unlocked.applyUnlocks(stage: .cub, intimacy: 10, ageDays: 5)
        XCTAssertTrue(unlocked.vocabularyBudding)
    }

    func testSleepModeAfter48Hours() {
        var snapshot = PetSnapshot(speciesID: .cat)
        snapshot.lastOpenedAt = Date().addingTimeInterval(-50 * 3600)
        let engine = PetEngine(snapshot: snapshot)
        let events = engine.onAppOpen()
        XCTAssertTrue(events.contains(.reunionPending))
        XCTAssertEqual(engine.snapshot.presence, .reunionPending)
    }

    func testSicknessRequiresMultipleLowStats() {
        var snapshot = PetSnapshot(speciesID: .cat)
        snapshot.stats.hunger = 15
        snapshot.stats.cleanliness = 15
        snapshot.lowStatsSince = Date().addingTimeInterval(-7 * 3600)
        snapshot.sickness = .healthy
        let engine = PetEngine(snapshot: snapshot)
        _ = engine.tick()
        XCTAssertEqual(engine.snapshot.sickness, .sick)
    }

    func testCopyLibraryRotates() {
        var library = DefaultCopyLibrary.make(for: .cat)
        let first = library.next(for: .hungerWarning)
        let second = library.next(for: .hungerWarning)
        XCTAssertNotEqual(first, second)
    }
}
