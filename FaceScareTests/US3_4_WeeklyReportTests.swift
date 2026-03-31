import XCTest
@testable import FaceScare

/// US 3.4 — Générer un rapport hebdomadaire d'équipe
///
/// Règles :
/// - Format CSV sauvegardé sur le Bureau
/// - Colonnes : Jour, Nombre de scares
/// - Identifiant anonyme (hash), pas de nom d'utilisateur
/// - Couvre les 7 derniers jours
final class US3_4_WeeklyReportTests: XCTestCase {

    private var statsStore: StatsStore!
    private var testDefaults: UserDefaults!
    private var suiteName: String!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        suiteName = "com.theomax.facescare.report.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        statsStore = StatsStore(defaults: testDefaults)
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FaceScareReport-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        testDefaults.removePersistentDomain(forName: suiteName)
        tempDirectory = nil
        suiteName = nil
        testDefaults = nil
        statsStore = nil
        super.tearDown()
    }

    // MARK: - Scénario 1 : 7 jours de données → fichier CSV créé

    func test_scenario1_7daysOfData_createsCSVFile() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            statsStore.setCount(daysAgo + 1, for: date)
        }

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)

        XCTAssertNotNil(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL!.path))
    }

    func test_scenario1_fileName_containsWeekNumber() {
        statsStore.recordScare()

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)

        XCTAssertNotNil(fileURL)
        XCTAssertTrue(fileURL!.lastPathComponent.hasPrefix("facescare-rapport-"))
        XCTAssertTrue(fileURL!.lastPathComponent.hasSuffix(".csv"))
        XCTAssertTrue(fileURL!.lastPathComponent.contains("-W"))
    }

    func test_scenario1_csvContent_hasHeaderRow() {
        statsStore.recordScare()

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let content = try! String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")

        XCTAssertEqual(lines.first, "User,Day,Scares")
    }

    func test_scenario1_csvContent_has7DataRows() {
        let today = Date()
        for daysAgo in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            statsStore.setCount(daysAgo, for: date)
        }

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let content = try! String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // 1 header + 7 data rows
        XCTAssertEqual(lines.count, 8)
    }

    // MARK: - Scénario 2 : Moins de 7 jours → rapport partiel

    func test_scenario2_lessThan7Days_containsOnlyAvailableDays() {
        let today = Date()
        statsStore.setCount(3, for: today)
        statsStore.setCount(5, for: Calendar.current.date(byAdding: .day, value: -1, to: today)!)

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let content = try! String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // 1 header + 2 data rows
        XCTAssertEqual(lines.count, 3)
    }

    // MARK: - Scénario 3 : Fichier existant → écrasé

    func test_scenario3_fileAlreadyExists_isOverwritten() {
        statsStore.recordScare()

        let firstURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let firstContent = try! String(contentsOf: firstURL, encoding: .utf8)

        // Record more scares and re-export
        statsStore.recordScare()
        statsStore.recordScare()

        let secondURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let secondContent = try! String(contentsOf: secondURL, encoding: .utf8)

        XCTAssertEqual(firstURL, secondURL)
        XCTAssertNotEqual(firstContent, secondContent)
    }

    // MARK: - Règle : identifiant anonyme (hash)

    func test_userIdentifier_isAnonymousHash() {
        statsStore.recordScare()

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let content = try! String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Data rows should have a hash identifier, not a username
        let dataLine = lines[1]
        let userId = dataLine.components(separatedBy: ",").first!

        // Hash should be a hex string, not contain spaces or real names
        XCTAssertFalse(userId.isEmpty)
        XCTAssertFalse(userId.contains(" "))
        XCTAssertGreaterThanOrEqual(userId.count, 8)
    }

    // MARK: - Règle : pas de données → pas de crash

    func test_noData_stillCreatesFileWithHeaderOnly() {
        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)

        XCTAssertNotNil(fileURL)
        let content = try! String(contentsOf: fileURL!, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Header only
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines.first, "User,Day,Scares")
    }

    // MARK: - Format CSV correct

    func test_csvFormat_commasAsSeparators() {
        let today = Date()
        statsStore.setCount(5, for: today)

        let fileURL = WeeklyReportExporter.export(from: statsStore, to: tempDirectory)!
        let content = try! String(contentsOf: fileURL, encoding: .utf8)
        let dataLine = content.components(separatedBy: "\n")[1]

        let columns = dataLine.components(separatedBy: ",")
        XCTAssertEqual(columns.count, 3)
    }
}
