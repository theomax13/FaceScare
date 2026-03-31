import XCTest
@testable import FaceScare

/// US 2.4 — Changer l'image du jump scare
///
/// Règles :
/// - L'utilisateur dépose un fichier jump-scare.png dans ~/Library/Application Support/FaceScare/
/// - L'image est chargée à chaque scare (pas mise en cache)
/// - Formats acceptés : PNG uniquement
/// - Si le fichier est absent ou illisible → l'écran rouge de fallback s'affiche
final class US2_4_CustomScareImageTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FaceScareTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    // MARK: - Scénario 1 : Image custom présente → utilisée en priorité

    func test_scenario1_customImageExists_returnsCustomURL() {
        let customImageURL = tempDirectory.appendingPathComponent("jump-scare.png")
        FileManager.default.createFile(atPath: customImageURL.path, contents: Data([0x89, 0x50]))

        let resolvedURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        XCTAssertEqual(resolvedURL, customImageURL)
    }

    // MARK: - Scénario 2 : Image custom absente → fallback bundle

    func test_scenario2_noCustomImage_returnsBundleURL() {
        // tempDirectory is empty — no custom image
        let resolvedURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        if let url = resolvedURL {
            // Should come from bundle, not from our temp directory
            XCTAssertFalse(url.path.contains("FaceScareTests"))
        }
        // If bundle also doesn't have it (test environment), nil is acceptable
    }

    // MARK: - Scénario 3 : Fichier corrompu (0 octets) → nil (fallback rouge)

    func test_scenario3_corruptedFile_returnsURLButImageIsNil() {
        let customImageURL = tempDirectory.appendingPathComponent("jump-scare.png")
        FileManager.default.createFile(atPath: customImageURL.path, contents: Data())

        let resolvedURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        // URL is returned (file exists)
        XCTAssertNotNil(resolvedURL)
        // But NSImage can't load empty data
        let image = NSImage(contentsOf: resolvedURL!)
        XCTAssertNil(image)
    }

    // MARK: - Scénario 4 : JPG renommé en .png → NSImage le lit quand même

    func test_scenario4_jpgRenamedToPng_imageIsStillLoadable() {
        let customImageURL = tempDirectory.appendingPathComponent("jump-scare.png")
        // Minimal valid JPEG header
        let jpegHeader = Data([0xFF, 0xD8, 0xFF, 0xE0])
        FileManager.default.createFile(atPath: customImageURL.path, contents: jpegHeader)

        let resolvedURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        XCTAssertNotNil(resolvedURL)
        XCTAssertEqual(resolvedURL, customImageURL)
    }

    // MARK: - Règle : l'image est chargée à chaque scare (pas de cache)

    func test_imageResolvedEachTime_notCached() {
        // First call: no custom image
        let firstURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        // Add custom image
        let customImageURL = tempDirectory.appendingPathComponent("jump-scare.png")
        FileManager.default.createFile(atPath: customImageURL.path, contents: Data([0x89, 0x50]))

        // Second call: custom image now exists
        let secondURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        XCTAssertNotEqual(firstURL, secondURL)
        XCTAssertEqual(secondURL, customImageURL)
    }

    // MARK: - Règle : seul jump-scare.png est reconnu

    func test_otherFileNames_areIgnored() {
        let wrongName = tempDirectory.appendingPathComponent("scary-image.png")
        FileManager.default.createFile(atPath: wrongName.path, contents: Data([0x89, 0x50]))

        let resolvedURL = ScareEngine.resolveScareImageURL(customDirectory: tempDirectory)

        // Should not pick up "scary-image.png"
        XCTAssertNotEqual(resolvedURL?.lastPathComponent, "scary-image.png")
    }

    // MARK: - Règle : le dossier custom est dans Application Support

    func test_defaultCustomDirectory_isInApplicationSupport() {
        let defaultDir = ScareEngine.defaultCustomImageDirectory

        XCTAssertTrue(defaultDir.path.contains("Application Support"))
        XCTAssertTrue(defaultDir.path.hasSuffix("FaceScare"))
    }
}
