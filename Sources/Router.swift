import Foundation
import AppKit

final class Router {
    static let shared = Router()
    static let bundleID = "com.user.browserrouter"

    static var isDefault: Bool {
        if let app = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) {
            return app.lastPathComponent == "BrowserRouter.app"
        }
        return false
    }

    static func setAsDefault() {
        LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
        LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)
    }

    func route(_ url: URL, app: NSApplication) {
        let browser = isLocal(url) ? "Google Chrome" : "Safari"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", browser, url.absoluteString]

        do {
            try process.run()
        } catch {
            NSWorkspace.shared.open(url)
        }
    }

    private func isLocal(_ url: URL) -> Bool {
        let s = url.absoluteString
        for pattern in ["localhost", "127.0.0.1", "0.0.0.0", ".test", ".local", ".dev"] {
            if s.contains(pattern) { return true }
        }
        for prefix in ["http://10.", "https://10.", "http://192.168.", "https://192.168."] {
            if s.hasPrefix(prefix) { return true }
        }
        return false
    }
}
