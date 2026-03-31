import AppKit

/// StatsExporter generates a PNG stats card and copies it to the clipboard.
///
/// The card contains: scares today, 7-day trend, best day, day number.
/// No personal data is included.
enum StatsExporter {

    // MARK: - Image Generation

    /// Generates a stats card image from the given StatsStore.
    static func generateImage(from store: StatsStore) -> NSImage? {
        let width: CGFloat = 400
        let height: CGFloat = 250
        let size = NSSize(width: width, height: height)

        let image = NSImage(size: size, flipped: false) { rect in
            // Background
            NSColor(white: 0.12, alpha: 1.0).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16).fill()

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .font: NSFont.boldSystemFont(ofSize: 20)
            ]
            "FaceScare Stats".draw(at: NSPoint(x: 24, y: 16), withAttributes: titleAttrs)

            // Stats text
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor(white: 0.85, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 14)
            ]

            let trendEmoji: String
            switch store.trend {
            case .improving: trendEmoji = "⬆️"
            case .degrading: trendEmoji = "⬇️"
            case .stable:    trendEmoji = "➡️"
            }

            "Scares today: \(store.todayCount)".draw(
                at: NSPoint(x: 24, y: 56), withAttributes: bodyAttrs)

            "Trend: \(trendEmoji)".draw(
                at: NSPoint(x: 24, y: 86), withAttributes: bodyAttrs)

            if let best = store.bestDay {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                "Best day: \(dateFormatter.string(from: best.date)) (\(best.count) scares)".draw(
                    at: NSPoint(x: 24, y: 116), withAttributes: bodyAttrs)
            }

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor(white: 0.5, alpha: 1.0),
                .font: NSFont.systemFont(ofSize: 12)
            ]

            let dayNumber = store.dayNumber
            let footer: String
            if store.last7Days.count <= 1 {
                footer = "Day \(dayNumber): \(store.todayCount) scares — let's go!"
            } else {
                footer = "Day \(dayNumber): \(store.todayCount) scares today"
            }
            footer.draw(at: NSPoint(x: 24, y: height - 36), withAttributes: footerAttrs)

            return true
        }

        return image
    }

    // MARK: - Clipboard

    /// Copies the given image to the system clipboard as PNG.
    /// Returns `true` if the copy succeeded.
    @discardableResult
    static func copyToClipboard(image: NSImage) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return false }

        pasteboard.setData(pngData, forType: .png)
        return true
    }
}
