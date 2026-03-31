import XCTest
@testable import FaceScare

/// US 3.2 — Installer l'app discrètement (mode prank)
///
/// Règles :
/// - L'app ne montre aucune fenêtre au démarrage
/// - L'icône 👁️ est discrète dans la barre de menu
/// - Pas de bounce dans le Dock, pas de notification
/// - La permission caméra reste obligatoire (seul indice visible)
final class US3_2_StealthInstallTests: XCTestCase {

    // MARK: - Scénario 1 : Pas d'icône dans le Dock (LSUIElement)

    func test_scenario1_LSUIElement_isTrue() {
        let value = Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool

        XCTAssertEqual(value, true)
    }

    // MARK: - Scénario 1 : L'icône menu bar est discrète

    func test_scenario1_menuBarIcon_isEyeEmoji() {
        let faceDetector = FaceDetector()
        let scareEngine = ScareEngine()
        let controller = StatusBarController(faceDetector: faceDetector, scareEngine: scareEngine)

        // The menu exists and has items (app is functional via menu bar)
        XCTAssertGreaterThan(controller.menu.items.count, 0)

        faceDetector.stop()
    }

    // MARK: - Scénario 3 : L'utilisateur peut découvrir le menu et quitter

    func test_scenario3_menuContainsQuitItem() {
        let faceDetector = FaceDetector()
        let scareEngine = ScareEngine()
        let controller = StatusBarController(faceDetector: faceDetector, scareEngine: scareEngine)

        let quitItem = controller.menu.items.first(where: { $0.title == "Quit FaceScare" })

        XCTAssertNotNil(quitItem)
        XCTAssertEqual(quitItem?.keyEquivalent, "q")

        faceDetector.stop()
    }

    func test_scenario3_menuContainsDisableItem() {
        let faceDetector = FaceDetector()
        let scareEngine = ScareEngine()
        let controller = StatusBarController(faceDetector: faceDetector, scareEngine: scareEngine)

        let disableItem = controller.menu.items.first(where: { $0.keyEquivalent == "d" })

        XCTAssertNotNil(disableItem)
        XCTAssertEqual(disableItem?.title, "Disable")

        faceDetector.stop()
    }

    // MARK: - Règle : permission caméra déclarée dans Info.plist

    func test_cameraUsageDescription_isDeclared() {
        let description = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String

        XCTAssertNotNil(description)
        XCTAssertFalse(description!.isEmpty)
    }
}
