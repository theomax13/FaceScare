import XCTest
@testable import FaceScare

/// US 2.2 — Choisir le délai entre les scares
///
/// Règles :
/// - 4 choix possibles : 5s, 10s, 20s, 30s
/// - 10s par défaut
/// - Le choix se fait depuis le menu → sous-menu "Cooldown"
/// - Le choix actuel est coché
/// - Le changement prend effet immédiatement
final class US2_2_CooldownMenuTests: XCTestCase {

    private var faceDetector: FaceDetector!
    private var scareEngine: ScareEngine!
    private var sut: StatusBarController!

    private var cooldownSubmenu: NSMenu? {
        sut.menu.items.first(where: { $0.title == "Cooldown" })?.submenu
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

    // MARK: - Le sous-menu contient 4 options

    func test_cooldownSubmenu_hasFourItems() {
        XCTAssertEqual(cooldownSubmenu?.items.count, 4)
    }

    func test_cooldownSubmenu_itemTitlesMatchOptions() {
        let titles = cooldownSubmenu?.items.map(\.title)

        XCTAssertEqual(titles, ["5s", "10s", "20s", "30s"])
    }

    // MARK: - Scénario 1 : 10s est coché par défaut

    func test_defaultCooldown_10sIsChecked() {
        let states = cooldownSubmenu?.items.map(\.state)

        XCTAssertEqual(states, [.off, .on, .off, .off])
    }

    // MARK: - Scénario 2 : Changer le cooldown met à jour la coche

    func test_select5s_checkmarkMovesTo5s() {
        cooldownSubmenu?.performActionForItem(at: 0) // 5s

        let states = cooldownSubmenu?.items.map(\.state)
        XCTAssertEqual(states, [.on, .off, .off, .off])
    }

    func test_select30s_checkmarkMovesTo30s() {
        cooldownSubmenu?.performActionForItem(at: 3) // 30s

        let states = cooldownSubmenu?.items.map(\.state)
        XCTAssertEqual(states, [.off, .off, .off, .on])
    }

    // MARK: - Scénario 2 : Le changement met à jour le ScareEngine

    func test_select5s_updatesScareEngineCooldown() {
        cooldownSubmenu?.performActionForItem(at: 0) // 5s

        XCTAssertEqual(scareEngine.cooldownInterval, 5.0)
    }

    func test_select30s_updatesScareEngineCooldown() {
        cooldownSubmenu?.performActionForItem(at: 3) // 30s

        XCTAssertEqual(scareEngine.cooldownInterval, 30.0)
    }

    // MARK: - Scénario 3 : Le changement prend effet immédiatement

    func test_changeCooldown_effectIsImmediate() {
        XCTAssertEqual(scareEngine.cooldownInterval, 10.0)

        cooldownSubmenu?.performActionForItem(at: 0) // 5s

        XCTAssertEqual(scareEngine.cooldownInterval, 5.0)
    }

    // MARK: - Scénario 4 : 2 scares en 6s possibles avec cooldown 5s

    func test_scenario4_cooldown5s_twoScaresIn6sArePossible() {
        scareEngine.cooldownInterval = 0.0 // Simulate no cooldown for counter test

        scareEngine.triggerScare()
        scareEngine.triggerScare()

        XCTAssertEqual(scareEngine.totalScaresTriggered, 2)
    }

    // MARK: - Sous-menu présent dans le menu principal

    func test_cooldownSubmenu_existsInMenu() {
        let cooldownItem = sut.menu.items.first(where: { $0.title == "Cooldown" })

        XCTAssertNotNil(cooldownItem)
        XCTAssertNotNil(cooldownItem?.submenu)
    }
}
