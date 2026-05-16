import SwiftUI

@main
struct AppleTVRemoteApp: App {
    @NSApplicationDelegateAdaptor(MenuBarController.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
