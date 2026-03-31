import XCTest
@testable import FaceScare

final class StatusBarControllerTests: XCTestCase {

    private var faceDetector: FaceDetector!
    private var scareEngine: ScareEngine!
    private var sut: StatusBarController!

    override func setUp() {
        super.setUp()
        faceDetector = FaceDetector()
        scareEngine = ScareEngine()
        sut = StatusBarController(faceDetector: faceDetector, scareEngine: scareEngine)
    }

    override func tearDown() {
        sut = nil
        scareEngine = nil
        faceDetector.stop()
        faceDetector = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_init_createsStatusBarController() {
        XCTAssertNotNil(sut)
    }

    func test_init_faceDetectorSensitivityUnchanged() {
        XCTAssertEqual(faceDetector.sensitivity, .medium)
    }

    func test_init_scareEngineCooldownUnchanged() {
        XCTAssertEqual(scareEngine.cooldownInterval, 10.0)
    }
}
