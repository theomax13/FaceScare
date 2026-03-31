import XCTest
@testable import FaceScare

/// US 2.1 — Choisir la sensibilité de détection
///
/// Règles :
/// - 3 choix possibles : Low (50%), Medium (40%), High (30%)
/// - Medium par défaut
/// - Le choix se fait depuis le menu → sous-menu "Sensitivity"
/// - Le choix actuel est coché
/// - Le changement prend effet immédiatement
final class US2_1_SensitivityMenuTests: XCTestCase {

    private var faceDetector: FaceDetector!
    private var scareEngine: ScareEngine!
    private var sut: StatusBarController!

    private var sensitivitySubmenu: NSMenu? {
        sut.menu.items.first(where: { $0.title == "Sensitivity" })?.submenu
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

    // MARK: - Scénario 1 : Le sous-menu contient 3 niveaux

    func test_sensitivitySubmenu_hasThreeItems() {
        XCTAssertEqual(sensitivitySubmenu?.items.count, 3)
    }

    func test_sensitivitySubmenu_itemTitlesMatchLevels() {
        let titles = sensitivitySubmenu?.items.map(\.title)

        XCTAssertEqual(titles, ["Low (50%)", "Medium (40%)", "High (30%)"])
    }

    // MARK: - Scénario 1 : Medium est coché par défaut

    func test_defaultSensitivity_mediumIsChecked() {
        let states = sensitivitySubmenu?.items.map(\.state)

        XCTAssertEqual(states, [.off, .on, .off])
    }

    // MARK: - Scénario 2 : Changer la sensibilité met à jour la coche

    func test_selectHigh_checkmarkMovesToHigh() {
        sensitivitySubmenu?.performActionForItem(at: 2) // High

        let states = sensitivitySubmenu?.items.map(\.state)
        XCTAssertEqual(states, [.off, .off, .on])
    }

    func test_selectLow_checkmarkMovesToLow() {
        sensitivitySubmenu?.performActionForItem(at: 0) // Low

        let states = sensitivitySubmenu?.items.map(\.state)
        XCTAssertEqual(states, [.on, .off, .off])
    }

    // MARK: - Scénario 2 : Le changement met à jour le FaceDetector

    func test_selectHigh_updatesFaceDetectorSensitivity() {
        sensitivitySubmenu?.performActionForItem(at: 2) // High

        XCTAssertEqual(faceDetector.sensitivity, .high)
    }

    func test_selectLow_updatesFaceDetectorSensitivity() {
        sensitivitySubmenu?.performActionForItem(at: 0) // Low

        XCTAssertEqual(faceDetector.sensitivity, .low)
    }

    // MARK: - Scénario 5 : Le changement prend effet immédiatement

    func test_changeSensitivity_effectIsImmediate() {
        XCTAssertEqual(faceDetector.sensitivity, .medium)

        sensitivitySubmenu?.performActionForItem(at: 2) // High

        XCTAssertEqual(faceDetector.sensitivity, .high)
        XCTAssertEqual(faceDetector.sensitivity.threshold, 0.30)
    }

    // MARK: - Sous-menu présent dans le menu principal

    func test_sensitivitySubmenu_existsInMenu() {
        let sensitivityItem = sut.menu.items.first(where: { $0.title == "Sensitivity" })

        XCTAssertNotNil(sensitivityItem)
        XCTAssertNotNil(sensitivityItem?.submenu)
    }
}
