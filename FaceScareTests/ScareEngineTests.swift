import XCTest
@testable import FaceScare

final class ScareEngineTests: XCTestCase {

    private var sut: ScareEngine!

    override func setUp() {
        super.setUp()
        sut = ScareEngine()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_init_totalScaresTriggeredIsZero() {
        XCTAssertEqual(sut.totalScaresTriggered, 0)
    }

    func test_init_defaultCooldownIsTenSeconds() {
        XCTAssertEqual(sut.cooldownInterval, 10.0)
    }

    // MARK: - Trigger Scare

    func test_triggerScare_incrementsTotalScaresTriggered() {
        sut.triggerScare()

        XCTAssertEqual(sut.totalScaresTriggered, 1)
    }

    func test_triggerScare_calledTwiceWithinCooldown_onlyIncrementsOnce() {
        sut.triggerScare()
        sut.triggerScare()

        XCTAssertEqual(sut.totalScaresTriggered, 1)
    }

    func test_triggerScare_afterCooldownExpires_incrementsAgain() {
        sut.cooldownInterval = 0.0 // No cooldown

        sut.triggerScare()
        sut.triggerScare()

        XCTAssertEqual(sut.totalScaresTriggered, 2)
    }

    // MARK: - Cooldown Configuration

    func test_cooldownInterval_canBeChanged() {
        sut.cooldownInterval = 30.0

        XCTAssertEqual(sut.cooldownInterval, 30.0)
    }

    func test_triggerScare_respectsCustomCooldown() {
        sut.cooldownInterval = 60.0

        sut.triggerScare()
        sut.triggerScare()

        XCTAssertEqual(sut.totalScaresTriggered, 1)
    }

    // MARK: - Multiple Triggers

    func test_triggerScare_multipleTimesWithZeroCooldown_countsAll() {
        sut.cooldownInterval = 0.0

        for _ in 0..<5 {
            sut.triggerScare()
        }

        XCTAssertEqual(sut.totalScaresTriggered, 5)
    }
}
