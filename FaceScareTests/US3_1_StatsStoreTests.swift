import XCTest
@testable import FaceScare

/// US 3.1 — Exporter ses stats en image (partie stockage)
///
/// Le StatsStore persiste les scares par jour pour permettre :
/// - Nombre de scares aujourd'hui
/// - Tendance sur 7 jours
/// - Meilleur jour (le moins de scares)
final class US3_1_StatsStoreTests: XCTestCase {

    private var sut: StatsStore!
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.theomax.facescare.tests.\(UUID().uuidString)"
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

    // MARK: - État initial

    func test_init_todayCountIsZero() {
        XCTAssertEqual(sut.todayCount, 0)
    }

    func test_init_historyIsEmpty() {
        XCTAssertTrue(sut.last7Days.isEmpty)
    }

    // MARK: - Enregistrer un scare

    func test_recordScare_incrementsTodayCount() {
        sut.recordScare()

        XCTAssertEqual(sut.todayCount, 1)
    }

    func test_recordScare_calledMultipleTimes_incrementsCorrectly() {
        for _ in 0..<5 {
            sut.recordScare()
        }

        XCTAssertEqual(sut.todayCount, 5)
    }

    // MARK: - Persistance

    func test_recordScare_persistsAcrossInstances() {
        sut.recordScare()
        sut.recordScare()
        sut.recordScare()

        let newStore = StatsStore(defaults: testDefaults)

        XCTAssertEqual(newStore.todayCount, 3)
    }

    // MARK: - Historique 7 jours

    func test_last7Days_returnsUpToSevenEntries() {
        // Simulate 10 days of data
        for daysAgo in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            sut.setCount(daysAgo + 1, for: date)
        }

        XCTAssertEqual(sut.last7Days.count, 7)
    }

    func test_last7Days_orderedFromOldestToNewest() {
        let today = Date()
        for daysAgo in 0..<3 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            sut.setCount(daysAgo + 1, for: date)
        }

        let counts = sut.last7Days.map(\.count)
        // Oldest first: 3 days ago (3), 2 days ago (2), today (1)
        XCTAssertEqual(counts, [3, 2, 1])
    }

    // MARK: - Meilleur jour

    func test_bestDay_returnsLowestCount() {
        let today = Date()
        sut.setCount(10, for: Calendar.current.date(byAdding: .day, value: -2, to: today)!)
        sut.setCount(2, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(7, for: today)

        XCTAssertEqual(sut.bestDay?.count, 2)
    }

    func test_bestDay_noHistory_returnsNil() {
        XCTAssertNil(sut.bestDay)
    }

    // MARK: - Tendance

    func test_trend_scoresDecreasing_returnsImproving() {
        let today = Date()
        sut.setCount(10, for: Calendar.current.date(byAdding: .day, value: -2, to: today)!)
        sut.setCount(5, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(2, for: today)

        XCTAssertEqual(sut.trend, .improving)
    }

    func test_trend_scoresIncreasing_returnsDegrading() {
        let today = Date()
        sut.setCount(2, for: Calendar.current.date(byAdding: .day, value: -2, to: today)!)
        sut.setCount(5, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(10, for: today)

        XCTAssertEqual(sut.trend, .degrading)
    }

    func test_trend_scoresStable_returnsStable() {
        let today = Date()
        sut.setCount(5, for: Calendar.current.date(byAdding: .day, value: -2, to: today)!)
        sut.setCount(5, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        sut.setCount(5, for: today)

        XCTAssertEqual(sut.trend, .stable)
    }

    func test_trend_noHistory_returnsStable() {
        XCTAssertEqual(sut.trend, .stable)
    }

    // MARK: - Nombre de jours d'utilisation

    func test_dayNumber_firstDay_returnsOne() {
        sut.recordScare()

        XCTAssertGreaterThanOrEqual(sut.dayNumber, 1)
    }

    // MARK: - Remise à zéro au relancement (session counter vs persistent)

    func test_todayCount_reflectsPersistentData() {
        sut.recordScare()
        sut.recordScare()

        let freshStore = StatsStore(defaults: testDefaults)
        XCTAssertEqual(freshStore.todayCount, 2)
    }
}
