import XCTest
@testable import FaceScare

/// US 3.1 — Exporter ses stats en image (partie export)
///
/// Règles :
/// - L'image générée est un PNG
/// - Contient : nombre de scares aujourd'hui, tendance sur 7 jours, meilleur jour
/// - L'image est copiée dans le presse-papier
/// - Aucune donnée personnelle identifiable
final class US3_1_StatsExporterTests: XCTestCase {

    private var statsStore: StatsStore!
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.theomax.facescare.export.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        statsStore = StatsStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        testDefaults = nil
        statsStore = nil
        super.tearDown()
    }

    // MARK: - Scénario 1 : Génération d'une image avec des données

    func test_generateImage_returnsNonNilImage() {
        statsStore.recordScare()
        statsStore.recordScare()

        let image = StatsExporter.generateImage(from: statsStore)

        XCTAssertNotNil(image)
    }

    func test_generateImage_returnsImageWithReasonableSize() {
        statsStore.recordScare()

        let image = StatsExporter.generateImage(from: statsStore)

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image!.size.width, 0)
        XCTAssertGreaterThan(image!.size.height, 0)
    }

    // MARK: - Scénario 2 : L'image est copiable dans le presse-papier

    func test_copyToClipboard_setsClipboardContent() {
        statsStore.recordScare()
        let image = StatsExporter.generateImage(from: statsStore)!

        StatsExporter.copyToClipboard(image: image)

        let pasteboard = NSPasteboard.general
        XCTAssertTrue(pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.png.rawValue]))
    }

    // MARK: - Scénario 3 : Premier jour, pas de données historiques

    func test_generateImage_firstDay_returnsValidImage() {
        // No history, just today
        statsStore.recordScare()

        let image = StatsExporter.generateImage(from: statsStore)

        XCTAssertNotNil(image)
    }

    // MARK: - Image au format PNG

    func test_generateImage_canBeConvertedToPNGData() {
        statsStore.recordScare()

        let image = StatsExporter.generateImage(from: statsStore)
        let pngData = image?.tiffRepresentation.flatMap {
            NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:])
        }

        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData!.count, 0)
    }

    // MARK: - Sans données → image quand même

    func test_generateImage_noScares_returnsValidImage() {
        let image = StatsExporter.generateImage(from: statsStore)

        XCTAssertNotNil(image)
    }
}
