import SwiftUI

/// FaceScare — A macOS menu bar app that detects face proximity via webcam
/// and triggers a jump-scare when the user leans too close to the screen.
///
/// Architecture:
/// - Menu bar only (LSUIElement = true, no Dock icon)
/// - AVFoundation webcam feed → Vision face detection → ScareEngine
@main
struct FaceScareApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — everything lives in the menu bar
        Settings {
            EmptyView()
        }
    }
}
