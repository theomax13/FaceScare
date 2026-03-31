import Foundation
import CryptoKit

/// WeeklyReportExporter generates a CSV report of the last 7 days of scare data.
///
/// The report is saved to a specified directory with the filename
/// `facescare-rapport-YYYY-WXX.csv`. The user is identified by an anonymous hash.
enum WeeklyReportExporter {

    // MARK: - Export

    /// Exports the last 7 days of stats to a CSV file.
    /// Returns the file URL on success, nil on failure.
    @discardableResult
    static func export(from store: StatsStore, to directory: URL? = nil) -> URL? {
        let outputDir = directory ?? downloadsDirectory
        let fileName = generateFileName()
        let fileURL = outputDir.appendingPathComponent(fileName)

        let csv = generateCSV(from: store)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("[FaceScare] Failed to write report: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - CSV Generation

    private static func generateCSV(from store: StatsStore) -> String {
        var lines = ["User,Day,Scares"]
        let userId = anonymousUserHash()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for entry in store.last7Days {
            let dateStr = dateFormatter.string(from: entry.date)
            lines.append("\(userId),\(dateStr),\(entry.count)")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - File Name

    private static func generateFileName() -> String {
        let calendar = Calendar(identifier: .iso8601)
        let weekNumber = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        return "facescare-rapport-\(year)-W\(String(format: "%02d", weekNumber)).csv"
    }

    // MARK: - Anonymous User Hash

    private static func anonymousUserHash() -> String {
        let identifier = ProcessInfo.processInfo.hostName + (NSUserName())
        let hash = SHA256.hash(data: Data(identifier.utf8))
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Downloads Directory

    private static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }
}
