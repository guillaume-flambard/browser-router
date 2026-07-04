import SwiftUI
import AppKit

@main
struct BrowserRouterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserRouter", systemImage: "arrow.triangle.branch") {
            Text("BrowserRouter").font(.headline)
            Text("local URLs → Chrome • other → Safari")
                .font(.caption).foregroundColor(.secondary)

            Divider()

            Button("Set as Default Browser") {
                Router.setAsDefault()
            }
            .disabled(Router.isDefault)

            Button("Open Default Browser Settings…") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference?Desktop%20Dock")!)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--install") {
            Router.setAsDefault()
            print("BrowserRouter set as default browser.")
            exit(0)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            Router.shared.route(url, app: application)
        }
    }
}
