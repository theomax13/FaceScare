import XCTest
@testable import FaceScare

/// US 2.6 — Voir le nombre de scares de la session
///
/// Règles :
/// - Le compteur apparaît dans le menu déroulant, en texte grisé (non cliquable)
/// - Format : "Scares triggered: X"
/// - Le compteur se met à jour à chaque ouverture du menu
/// - Le compteur repart à 0 quand l'app est relancée
final class US2_6_ScareCounterTests: XCTestCase {

    private var faceDetector: FaceDetector!
    private var scareEngine: ScareEngine!
    private var statusBarController: StatusBarController!

    override func setUp() {
        super.setUp()
        faceDetector = FaceDetector()
        scareEngine = ScareEngine()
        scareEngine.cooldownInterval = 0.0 // Disable cooldown for testing
        statusBarController = StatusBarController(
            faceDetector: faceDetector,
            scareEngine: scareEngine
        )
    }

    override func tearDown() {
        statusBarController = nil
        scareEngine = nil
        faceDetector.stop()
        faceDetector = nil
        super.tearDown()
    }

    // MARK: - Scénario 1 : Aucun scare → affiche 0

    func test_scenario1_appJustLaunched_statsShowZero() {
        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 0")
    }

    // MARK: - Scénario 2 : N scares → affiche N

    func test_scenario2_afterSevenScares_statsShowSeven() {
        for _ in 0..<7 {
            scareEngine.triggerScare()
        }

        // Simulate menu opening (triggers stats refresh)
        statusBarController.menuWillOpen(statusBarController.menu)

        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 7")
    }

    func test_scenario2_afterOneScare_statsShowOne() {
        scareEngine.triggerScare()

        statusBarController.menuWillOpen(statusBarController.menu)

        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 1")
    }

    // MARK: - Scénario 3 : Relance → compteur repart à 0

    func test_scenario3_newScareEngineInstance_counterResetsToZero() {
        scareEngine.triggerScare()
        XCTAssertEqual(scareEngine.totalScaresTriggered, 1)

        // Simulate app relaunch: new instances
        let freshScareEngine = ScareEngine()
        XCTAssertEqual(freshScareEngine.totalScaresTriggered, 0)
    }

    func test_scenario3_newStatusBarController_statsShowZero() {
        scareEngine.triggerScare()
        statusBarController.menuWillOpen(statusBarController.menu)
        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 1")

        // Simulate app relaunch
        let freshScareEngine = ScareEngine()
        let freshController = StatusBarController(
            faceDetector: faceDetector,
            scareEngine: freshScareEngine
        )

        XCTAssertEqual(freshController.statsItem.title, "Scares triggered: 0")
    }

    // MARK: - Scénario 4 : Scare pendant menu ouvert → ancienne valeur jusqu'à réouverture

    func test_scenario4_scareAfterMenuOpen_statsNotUpdatedUntilReopen() {
        // Open menu first
        statusBarController.menuWillOpen(statusBarController.menu)
        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 0")

        // Scare happens while menu is "open"
        scareEngine.triggerScare()

        // Stats still show old value (no automatic refresh)
        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 0")

        // Reopen menu → stats refresh
        statusBarController.menuWillOpen(statusBarController.menu)
        XCTAssertEqual(statusBarController.statsItem.title, "Scares triggered: 1")
    }

    // MARK: - Règle : texte grisé (non cliquable)

    func test_statsItem_isDisabled() {
        XCTAssertFalse(statusBarController.statsItem.isEnabled)
    }

    func test_statsItem_hasNoAction() {
        XCTAssertNil(statusBarController.statsItem.action)
    }

    // MARK: - Règle : le compteur est dans le menu

    func test_statsItem_isPresentInMenu() {
        let menuItems = statusBarController.menu.items
        XCTAssertTrue(menuItems.contains(statusBarController.statsItem))
    }

    // MARK: - Format du compteur

    func test_statsFormat_matchesExpectedPattern() {
        scareEngine.triggerScare()
        scareEngine.triggerScare()
        scareEngine.triggerScare()

        statusBarController.menuWillOpen(statusBarController.menu)

        XCTAssertTrue(statusBarController.statsItem.title.hasPrefix("Scares triggered: "))
        XCTAssertTrue(statusBarController.statsItem.title.hasSuffix("3"))
    }
}
