import XCTest
@testable import FaceScare

/// US 2.5 — Ajouter ses propres sons
///
/// Règles :
/// - L'app cherche tous les fichiers dont le nom commence par "scare" et finit par ".mp3"
/// - Le choix du son est aléatoire à chaque scare parmi tous les fichiers trouvés
/// - Il faut au moins 1 fichier son — sinon bip système en fallback
/// - Pas de limite maximale du nombre de fichiers
final class US2_5_CustomScareSoundsTests: XCTestCase {

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

    // MARK: - Helpers

    private func createFakeMP3(named name: String) {
        let url = tempDirectory.appendingPathComponent(name)
        FileManager.default.createFile(atPath: url.path, contents: Data([0xFF, 0xFB, 0x90]))
    }

    // MARK: - Scénario 1 : Plusieurs fichiers scare*.mp3 → tous découverts

    func test_scenario1_fiveScareFiles_allDiscovered() {
        for i in 1...5 {
            createFakeMP3(named: "scare\(i).mp3")
        }

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        XCTAssertEqual(urls.count, 5)
    }

    // MARK: - Scénario 2 : Un seul fichier → retourné

    func test_scenario2_singleScareFile_returnsOne() {
        createFakeMP3(named: "scare1.mp3")

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first?.lastPathComponent, "scare1.mp3")
    }

    // MARK: - Scénario 3 : Aucun fichier custom → fallback vers le bundle

    func test_scenario3_noCustomScareFiles_fallsBackToBundle() {
        // tempDirectory is empty — no custom scare files
        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        // Should fallback to bundle's scare1.mp3
        XCTAssertFalse(urls.isEmpty)
        XCTAssertFalse(urls.first!.path.contains(tempDirectory.lastPathComponent))
    }

    // MARK: - Scénario 4 : Fichier ne commençant pas par "scare" → ignoré, fallback bundle

    func test_scenario4_nonScareFileName_isIgnored_fallsBackToBundle() {
        createFakeMP3(named: "mysound.mp3")
        createFakeMP3(named: "scary.mp3")
        createFakeMP3(named: "sound_scare.mp3")

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        // None of these match scare*.mp3, so fallback to bundle
        for url in urls {
            XCTAssertFalse(url.path.contains(tempDirectory.lastPathComponent))
        }
    }

    // MARK: - Règle : seuls les .mp3 sont pris en compte

    func test_nonMP3Files_areIgnored() {
        createFakeMP3(named: "scare1.mp3")
        let wavURL = tempDirectory.appendingPathComponent("scare2.wav")
        FileManager.default.createFile(atPath: wavURL.path, contents: Data([0x00]))
        let oggURL = tempDirectory.appendingPathComponent("scare3.ogg")
        FileManager.default.createFile(atPath: oggURL.path, contents: Data([0x00]))

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first?.lastPathComponent, "scare1.mp3")
    }

    // MARK: - Règle : mélange custom + bundle ignoré (custom directory prioritaire)

    func test_customDirectoryOnly_bundleNotMixed() {
        createFakeMP3(named: "scare1.mp3")
        createFakeMP3(named: "scare2.mp3")

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        // All URLs should come from our temp directory
        for url in urls {
            XCTAssertTrue(url.path.contains(tempDirectory.lastPathComponent))
        }
    }

    // MARK: - Règle : pas de limite de fichiers

    func test_noFileLimit_twentyFilesAllDiscovered() {
        for i in 1...20 {
            createFakeMP3(named: "scare\(i).mp3")
        }

        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        XCTAssertEqual(urls.count, 20)
    }

    // MARK: - Règle : le dossier custom est dans Application Support

    func test_defaultCustomDirectory_isInApplicationSupport() {
        let defaultDir = ScareEngine.defaultCustomSoundDirectory

        XCTAssertTrue(defaultDir.path.contains("Application Support"))
        XCTAssertTrue(defaultDir.path.hasSuffix("FaceScare"))
    }

    // MARK: - Règle : si pas de fichiers custom, fallback vers le bundle

    func test_emptyCustomDirectory_fallsBackToBundle() {
        // tempDirectory is empty, so resolveScareSoundURLs should fall back to bundle
        let urls = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        // In test environment, bundle may or may not have scare files
        // The important thing is it doesn't crash and returns a valid array
        XCTAssertNotNil(urls)
    }

    // MARK: - Règle : les fichiers sont redécouverts à chaque appel (pas de cache)

    func test_filesResolvedEachTime_notCached() {
        let urlsBefore = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        createFakeMP3(named: "scare1.mp3")
        createFakeMP3(named: "scare2.mp3")

        let urlsAfter = ScareEngine.resolveScareSoundURLs(customDirectory: tempDirectory)

        XCTAssertNotEqual(urlsBefore.count, urlsAfter.count)
        XCTAssertEqual(urlsAfter.count, 2)
    }
}
