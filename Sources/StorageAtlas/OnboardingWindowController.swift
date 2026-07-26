import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()

    static var isCompleted: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    private var window: NSWindow?

    func present(model: StorageModel) {
        guard window == nil, let screen = targetScreen() else { return }

        let overlay = StorageAtlasOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .floating
        overlay.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        overlay.appearance = NSAppearance(named: .darkAqua)
        overlay.isReleasedWhenClosed = false
        overlay.isMovable = false
        overlay.hasShadow = false

        let root = OnboardingView { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            self?.dismiss()
        }
        .environmentObject(model)
        overlay.contentView = NSHostingView(rootView: root)

        overlay.alphaValue = 0
        overlay.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            overlay.animator().alphaValue = 1
        }
        window = overlay
    }

    func dismiss() {
        guard let window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self, weak window] in
            Task { @MainActor in
                window?.orderOut(nil)
                self?.window = nil
            }
        })
    }

    private func targetScreen() -> NSScreen? {
        if let mainWindow = NSApp.mainWindow, let screen = mainWindow.screen {
            return screen
        }
        return NSScreen.main
    }
}

private final class StorageAtlasOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
