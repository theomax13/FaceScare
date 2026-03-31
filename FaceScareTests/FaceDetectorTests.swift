import XCTest
@testable import FaceScare

final class FaceDetectorTests: XCTestCase {

    private var sut: FaceDetector!

    override func setUp() {
        super.setUp()
        sut = FaceDetector()
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_init_isRunningIsFalse() {
        XCTAssertFalse(sut.isRunning)
    }

    func test_init_defaultSensitivityIsMedium() {
        XCTAssertEqual(sut.sensitivity, .medium)
    }

    func test_init_onFaceTooCloseIsNil() {
        XCTAssertNil(sut.onFaceTooClose)
    }

    // MARK: - Start / Stop

    func test_start_setsIsRunningToTrue() {
        sut.start()

        XCTAssertTrue(sut.isRunning)
    }

    func test_stop_setsIsRunningToFalse() {
        sut.start()
        sut.stop()

        XCTAssertFalse(sut.isRunning)
    }

    func test_start_calledTwice_remainsRunning() {
        sut.start()
        sut.start()

        XCTAssertTrue(sut.isRunning)
    }

    func test_stop_calledWithoutStart_remainsNotRunning() {
        sut.stop()

        XCTAssertFalse(sut.isRunning)
    }

    // MARK: - Sensitivity

    func test_sensitivity_canBeChanged() {
        sut.sensitivity = .high

        XCTAssertEqual(sut.sensitivity, .high)
    }

    func test_sensitivity_canBeCycledThroughAllCases() {
        for level in Sensitivity.allCases {
            sut.sensitivity = level
            XCTAssertEqual(sut.sensitivity, level)
        }
    }

    // MARK: - Callback

    func test_onFaceTooClose_canBeAssigned() {
        var callbackInvoked = false
        sut.onFaceTooClose = { callbackInvoked = true }

        sut.onFaceTooClose?()

        XCTAssertTrue(callbackInvoked)
    }

    func test_onFaceTooClose_canBeSetToNil() {
        sut.onFaceTooClose = { }
        sut.onFaceTooClose = nil

        XCTAssertNil(sut.onFaceTooClose)
    }
}
