import XCTest
@testable import FaceScare

/// US 2.3 — Activer ou désactiver l'app
///
/// Règles :
/// - Un item affiche "Disable" quand actif, "Enable" quand en pause
/// - Raccourci clavier : D
/// - Quand désactivée : la caméra s'arrête, l'icône change
/// - Quand réactivée : la caméra redémarre, l'icône revient
/// - Désactiver ne quitte pas l'app
final class US2_3_ToggleDetectionTests: XCTestCase {

    private var faceDetector: FaceDetector!
    private var scareEngine: ScareEngine!
    private var sut: StatusBarController!

    private var toggleItem: NSMenuItem? {
        sut.menu.items.first(where: { $0.action != nil && $0.keyEquivalent == "d" })
    }

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

    // MARK: - État initial

    func test_init_isEnabledByDefault() {
        XCTAssertTrue(sut.isEnabled)
    }

    func test_init_toggleItemTitleIsDisable() {
        XCTAssertEqual(toggleItem?.title, "Disable")
    }

    func test_init_toggleItemHasKeyEquivalentD() {
        XCTAssertEqual(toggleItem?.keyEquivalent, "d")
    }

    // MARK: - Scénario 1 : Désactiver la détection

    func test_disable_setsIsEnabledToFalse() {
        sut.menu.performActionForItem(at: 0) // Toggle

        XCTAssertFalse(sut.isEnabled)
    }

    func test_disable_stopsFaceDetector() {
        faceDetector.start()
        XCTAssertTrue(faceDetector.isRunning)

        sut.menu.performActionForItem(at: 0) // Toggle → Disable

        XCTAssertFalse(faceDetector.isRunning)
    }

    func test_disable_toggleItemTitleChangesToEnable() {
        sut.menu.performActionForItem(at: 0) // Toggle → Disable

        XCTAssertEqual(toggleItem?.title, "Enable")
    }

    // MARK: - Scénario 3 : Réactiver la détection

    func test_enable_afterDisable_setsIsEnabledToTrue() {
        sut.menu.performActionForItem(at: 0) // Disable
        sut.menu.performActionForItem(at: 0) // Enable

        XCTAssertTrue(sut.isEnabled)
    }

    func test_enable_afterDisable_startsFaceDetector() {
        sut.menu.performActionForItem(at: 0) // Disable
        XCTAssertFalse(faceDetector.isRunning)

        sut.menu.performActionForItem(at: 0) // Enable

        XCTAssertTrue(faceDetector.isRunning)
    }

    func test_enable_afterDisable_toggleItemTitleChangesBackToDisable() {
        sut.menu.performActionForItem(at: 0) // Disable
        sut.menu.performActionForItem(at: 0) // Enable

        XCTAssertEqual(toggleItem?.title, "Disable")
    }

    // MARK: - Scénario 5 : Compteur non réinitialisé au toggle

    func test_disableAndEnable_doesNotResetScareCounter() {
        scareEngine.cooldownInterval = 0.0
        scareEngine.triggerScare()
        scareEngine.triggerScare()
        XCTAssertEqual(scareEngine.totalScaresTriggered, 2)

        sut.menu.performActionForItem(at: 0) // Disable
        sut.menu.performActionForItem(at: 0) // Enable

        XCTAssertEqual(scareEngine.totalScaresTriggered, 2)
    }

    // MARK: - Le toggle est le premier item du menu

    func test_toggleItem_isFirstMenuItem() {
        XCTAssertEqual(sut.menu.items.first?.title, "Disable")
    }
}
