import Foundation

/// Trend direction for scare frequency over time.
enum Trend: Equatable {
    case improving
    case degrading
    case stable
}

/// A daily scare entry: date + count.
struct DailyStats: Equatable {
    let date: Date
    let count: Int
}

/// StatsStore persists daily scare counts using UserDefaults.
///
/// Data is stored as a dictionary of [dateKey: count] where dateKey is "yyyy-MM-dd".
/// Used by US 3.1 (export stats) and US 3.3 (ergo score).
final class StatsStore {

    // MARK: - Constants

    private static let storageKey = "com.theomax.facescare.dailyStats"
    private static let firstLaunchKey = "com.theomax.facescare.firstLaunchDate"

    // MARK: - Dependencies

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Self.firstLaunchKey) == nil {
            defaults.set(Date(), forKey: Self.firstLaunchKey)
        }
    }

    // MARK: - Date Formatting

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func dateKey(for date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    // MARK: - Storage Access

    private var allStats: [String: Int] {
        get { defaults.dictionary(forKey: Self.storageKey) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: Self.storageKey) }
    }

    // MARK: - Public API

    /// Number of scares recorded today.
    var todayCount: Int {
        allStats[dateKey(for: Date())] ?? 0
    }

    /// Record a scare for today. Increments the persistent counter.
    func recordScare() {
        let key = dateKey(for: Date())
        var stats = allStats
        stats[key] = (stats[key] ?? 0) + 1
        allStats = stats
    }

    /// Set a specific count for a date (used for testing and data import).
    func setCount(_ count: Int, for date: Date) {
        let key = dateKey(for: date)
        var stats = allStats
        stats[key] = count
        allStats = stats
    }

    /// Returns the last 7 days of stats, ordered from oldest to newest.
    /// Only includes days that have data.
    var last7Days: [DailyStats] {
        let today = Date()
        var result: [DailyStats] = []

        for daysAgo in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let key = dateKey(for: date)
            if let count = allStats[key] {
                result.append(DailyStats(date: date, count: count))
            }
        }

        return result
    }

    /// The day with the lowest scare count, or nil if no history.
    var bestDay: DailyStats? {
        let days = last7Days
        return days.min(by: { $0.count < $1.count })
    }

    /// Trend based on comparing the first half and second half of available data.
    var trend: Trend {
        let days = last7Days
        guard days.count >= 2 else { return .stable }

        let mid = days.count / 2
        let firstHalf = days.prefix(mid)
        let secondHalf = days.suffix(from: mid)

        let avgFirst = Double(firstHalf.map(\.count).reduce(0, +)) / Double(firstHalf.count)
        let avgSecond = Double(secondHalf.map(\.count).reduce(0, +)) / Double(secondHalf.count)

        if avgSecond < avgFirst {
            return .improving
        } else if avgSecond > avgFirst {
            return .degrading
        }
        return .stable
    }

    /// Number of days since first launch (1-indexed).
    var dayNumber: Int {
        guard let firstLaunch = defaults.object(forKey: Self.firstLaunchKey) as? Date else { return 1 }
        let days = calendar.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return days + 1
    }

    // MARK: - Ergo Score

    /// Ergonomic score from 0 (bad posture) to 100 (no scares).
    /// Returns `nil` if fewer than 2 days of data are available.
    ///
    /// Formula: 100 - min(avgScares * 6.67, 100)
    /// 0 scares/day → 100, 15 scares/day → ~0
    var ergoScore: Int? {
        let days = last7Days
        guard days.count >= 2 else { return nil }

        let totalScares = days.map(\.count).reduce(0, +)
        let avg = Double(totalScares) / Double(days.count)
        let score = 100.0 - min(avg * 6.67, 100.0)
        return max(0, min(100, Int(score.rounded())))
    }

    /// Formatted ergo score for display in the menu.
    /// Returns "Ergo score: --/100" if not enough data.
    var ergoScoreText: String {
        guard let score = ergoScore else {
            return "Ergo score: --/100"
        }

        let trendEmoji: String
        switch trend {
        case .improving: trendEmoji = " ⬆️"
        case .degrading: trendEmoji = " ⬇️"
        case .stable:    trendEmoji = " ➡️"
        }

        return "Ergo score: \(score)/100\(trendEmoji)"
    }
}
