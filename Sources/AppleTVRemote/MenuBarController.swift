import SwiftUI
import AppKit

class MenuBarController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let bridge = AppleTVBridge()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "appletv.fill",
                accessibilityDescription: "Apple TV Remote"
            )
            button.action = #selector(togglePopover)
            button.target = self
            button.toolTip = "Apple TV Remote"

            // Make icon template (adapts to light/dark menu bar)
            button.image?.isTemplate = true
        }

        // Create popover with SwiftUI content
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 420)
        popover.behavior = .transient
        popover.animates = true

        let contentView = RemoteView()
            .environmentObject(bridge)
        popover.contentViewController = NSHostingController(rootView: contentView)

        // Start bridge and scan on launch
        bridge.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.bridge.scan()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Activate app so popover gets focus (needed for .transient behavior)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        bridge.stop()
    }
}
