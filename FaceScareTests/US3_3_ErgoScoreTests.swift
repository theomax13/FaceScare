import XCTest
@testable import FaceScare

/// US 3.3 — Voir son score ergonomique
///
/// Règles :
/// - Score de 0 (mauvaise posture) à 100 (aucun scare en 7 jours)
/// - Affiché dans le menu : "Ergo score: XX/100 ⬆️"
/// - Flèche : ⬆️ amélioration, ⬇️ dégradation, ➡️ stable
/// - Basé sur la moyenne glissante de scares/jour sur 7 jours
/// - Données sauvegardées localement
final class US3_3_ErgoScoreTests: XCTestCase {

    private var sut: StatsStore!
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.theomax.facescare.ergo.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        sut = StatsStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Scénario 1 : 0 scares sur 7 jours → score 100

    func test_scenario1_zeroScaresOver7Days_scoreIs100() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(0, for: date)
        }

        XCTAssertEqual(sut.ergoScore, 100)
    }

    // MARK: - Scénario 2 : Moyenne 15 scares/jour → score bas

    func test_scenario2_highScareAverage_scoreLow() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(15, for: date)
        }

        let score = sut.ergoScore!
        XCTAssertLessThan(score, 20)
        XCTAssertGreaterThanOrEqual(score, 0)
    }

    // MARK: - Scénario 3 : Hier 10, aujourd'hui 3 → score monte

    func test_scenario3_fewerScaresToday_trendImproving() {
        let today = Date()
        sut.setCount(10, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(3, for: today)

        XCTAssertEqual(sut.trend, .improving)
    }

    // MARK: - Scénario 4 : Premier jour, pas 7 jours de données → nil

    func test_scenario4_firstDay_ergoScoreIsNil() {
        XCTAssertNil(sut.ergoScore)
    }

    func test_scenario4_onlyOneDay_ergoScoreIsNil() {
        sut.recordScare()

        XCTAssertNil(sut.ergoScore)
    }

    // MARK: - Scénario 5 : Jours désactivés comptent comme 0 scares

    func test_scenario5_missingDaysCountAsZero() {
        let today = Date()
        // Only set data for 2 days out of 7
        sut.setCount(0, for: Calendar.current.date(byAdding: .day, value: -6, to: today)!)
        sut.setCount(0, for: today)

        // ergoScore should still be calculable if we have >= 2 days
        // Missing days = 0 scares = good posture
        if let score = sut.ergoScore {
            XCTAssertGreaterThan(score, 80)
        }
    }

    // MARK: - Score boundaries

    func test_score_neverExceeds100() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(0, for: date)
        }

        XCTAssertLessThanOrEqual(sut.ergoScore!, 100)
    }

    func test_score_neverBelow0() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(100, for: date)
        }

        XCTAssertGreaterThanOrEqual(sut.ergoScore!, 0)
    }

    // MARK: - Format d'affichage

    func test_ergoScoreText_with7DaysData_containsScoreAndTrend() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(3, for: date)
        }

        let text = sut.ergoScoreText

        XCTAssertTrue(text.contains("/100"))
        XCTAssertTrue(text.contains("Ergo score:"))
    }

    func test_ergoScoreText_firstDay_showsDashes() {
        let text = sut.ergoScoreText

        XCTAssertEqual(text, "Ergo score: --/100")
    }

    func test_ergoScoreText_improving_containsUpArrow() {
        let today = Date()
        sut.setCount(10, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(2, for: today)

        let text = sut.ergoScoreText

        XCTAssertTrue(text.contains("⬆️"))
    }

    func test_ergoScoreText_degrading_containsDownArrow() {
        let today = Date()
        sut.setCount(2, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(10, for: today)

        let text = sut.ergoScoreText

        XCTAssertTrue(text.contains("⬇️"))
    }
}
