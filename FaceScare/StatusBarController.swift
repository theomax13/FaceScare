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

    // MARK: - Menu Bar

    private let statusItem: NSStatusItem
    let menu = NSMenu()

    // MARK: - State

    private(set) var isEnabled = true

    // MARK: - Menu Items (need references for dynamic updates)

    private var toggleItem: NSMenuItem!
    private(set) var statsItem: NSMenuItem!

    // MARK: - Init

    init(faceDetector: FaceDetector, scareEngine: ScareEngine) {
        self.faceDetector = faceDetector
        self.scareEngine = scareEngine
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
    }
}
