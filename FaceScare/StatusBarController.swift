import AppKit
import SwiftUI

/// StatusBarController manages the menu bar icon (👁️) and its dropdown menu.
///
/// Menu structure:
/// - Enable / Disable toggle
/// - Sensitivity submenu (Low / Medium / High)
/// - Cooldown submenu (5s / 10s / 20s / 30s)
/// - Separator
/// - Stats: total scares triggered
/// - Separator
/// - Quit
final class StatusBarController: NSObject {

    // MARK: - Dependencies

    private let faceDetector: FaceDetector
    private let scareEngine: ScareEngine
    private let statsStore: StatsStore?

    // MARK: - Menu Bar

    private let statusItem: NSStatusItem
    let menu = NSMenu()

    // MARK: - State

    private(set) var isEnabled = true

    // MARK: - Menu Items (need references for dynamic updates)

    private var toggleItem: NSMenuItem!
    private(set) var statsItem: NSMenuItem!
    private(set) var ergoScoreItem: NSMenuItem?

    // MARK: - Init

    init(faceDetector: FaceDetector, scareEngine: ScareEngine, statsStore: StatsStore? = nil) {
        self.faceDetector = faceDetector
        self.scareEngine = scareEngine
        self.statsStore = statsStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        configureStatusItem()
        buildMenu()
    }

    // MARK: - Status Item Setup

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.title = "👁️"
        }
        statusItem.menu = menu
    }

    // MARK: - Menu Construction

    private func buildMenu() {
        // Toggle Enable/Disable
        toggleItem = NSMenuItem(
            title: "Disable",
            action: #selector(toggleDetection),
            keyEquivalent: "d"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // Sensitivity submenu
        let sensitivitySubmenu = NSMenu()
        for level in Sensitivity.allCases {
            let item = NSMenuItem(
                title: "\(level.rawValue) (\(Int(level.threshold * 100))%)",
                action: #selector(sensitivityChanged(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = level
            if level == faceDetector.sensitivity {
                item.state = .on
            }
            sensitivitySubmenu.addItem(item)
        }
        let sensitivityItem = NSMenuItem(title: "Sensitivity", action: nil, keyEquivalent: "")
        sensitivityItem.submenu = sensitivitySubmenu
        menu.addItem(sensitivityItem)

        // Cooldown submenu
        let cooldownSubmenu = NSMenu()
        let cooldownOptions: [TimeInterval] = [5, 10, 20, 30]
        for seconds in cooldownOptions {
            let item = NSMenuItem(
                title: "\(Int(seconds))s",
                action: #selector(cooldownChanged(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = seconds
            if seconds == scareEngine.cooldownInterval {
                item.state = .on
            }
            cooldownSubmenu.addItem(item)
        }
        let cooldownItem = NSMenuItem(title: "Cooldown", action: nil, keyEquivalent: "")
        cooldownItem.submenu = cooldownSubmenu
        menu.addItem(cooldownItem)

        menu.addItem(.separator())

        // Stats
        statsItem = NSMenuItem(
            title: "Scares triggered: 0",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)

        // Ergo score (only if StatsStore is available)
        if statsStore != nil {
            ergoScoreItem = NSMenuItem(
                title: "Ergo score: --/100",
                action: nil,
                keyEquivalent: ""
            )
            ergoScoreItem?.isEnabled = false
            menu.addItem(ergoScoreItem!)
        }

        // Share stats (only if StatsStore is available)
        if statsStore != nil {
            let shareItem = NSMenuItem(
                title: "Share my stats",
                action: #selector(shareStats),
                keyEquivalent: ""
            )
            shareItem.target = self
            menu.addItem(shareItem)
        }

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit FaceScare",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Update stats before menu opens
        menu.delegate = self
    }

    // MARK: - Actions

    @objc private func shareStats() {
        guard let store = statsStore,
              let image = StatsExporter.generateImage(from: store) else { return }

        if StatsExporter.copyToClipboard(image: image) {
            // Brief feedback via the menu bar icon
            let originalTitle = statusItem.button?.title
            statusItem.button?.title = "✅"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.statusItem.button?.title = originalTitle ?? "👁️"
            }
        }
    }

    @objc private func toggleDetection() {
        isEnabled.toggle()
        if isEnabled {
            faceDetector.start()
            toggleItem.title = "Disable"
            statusItem.button?.title = "👁️"
        } else {
            faceDetector.stop()
            toggleItem.title = "Enable"
            statusItem.button?.title = "👁️‍🗨️" // Dimmed variant when disabled
        }
    }

    @objc private func sensitivityChanged(_ sender: NSMenuItem) {
        guard let level = sender.representedObject as? Sensitivity else { return }
        faceDetector.sensitivity = level

        // Update checkmarks
        if let submenu = sender.menu {
            for item in submenu.items {
                item.state = (item.representedObject as? Sensitivity == level) ? .on : .off
            }
        }
    }

    @objc private func cooldownChanged(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        scareEngine.cooldownInterval = seconds

        // Update checkmarks
        if let submenu = sender.menu {
            for item in submenu.items {
                item.state = (item.representedObject as? TimeInterval == seconds) ? .on : .off
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh stats each time the menu is opened
        statsItem.title = "Scares triggered: \(scareEngine.totalScaresTriggered)"
        ergoScoreItem?.title = statsStore?.ergoScoreText ?? "Ergo score: --/100"
    }
}
