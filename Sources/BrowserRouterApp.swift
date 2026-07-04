import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let router = Router.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--install") {
            router.setAsDefault()
            print("BrowserRouter set as default browser.")
            exit(0)
        }

        router.refreshStatus()
        setupStatusBar()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { router.route(url) }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let btn = statusItem.button else {
            NSLog("BrowserRouter: failed to create status item button")
            return
        }
        btn.image = makeStatusIcon()
        btn.toolTip = "BrowserRouter"
        btn.isHighlighted = true

        let menu = NSMenu()
        menu.addItem(createHeaderItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: router.isDefaultBrowser ? "Disable (restore Safari)" : "Set as Default Browser",
                                action: #selector(toggleDefault), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.isVisible = true

        NSLog("BrowserRouter: status bar item created")
    }

    private func createHeaderItem() -> NSMenuItem {
        let item = NSMenuItem()
        let hv = NSHostingView(rootView: HeaderView(router: router))
        hv.frame = NSRect(x: 0, y: 0, width: 220, height: 48)
        item.view = hv
        return item
    }

    private func makeStatusIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size)
        img.isTemplate = true
        img.lockFocus()

        NSColor.controlTextColor.setStroke()
        NSColor.controlTextColor.setFill()

        let path = NSBezierPath()
        path.lineWidth = 2.4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        // Horizontal line
        path.move(to: NSPoint(x: 2, y: 9))
        path.line(to: NSPoint(x: 9, y: 9))
        path.stroke()

        // Upper branch (Chrome direction)
        path.move(to: NSPoint(x: 9, y: 9))
        path.line(to: NSPoint(x: 16, y: 3))
        path.stroke()

        // Lower branch (Safari direction)
        path.move(to: NSPoint(x: 9, y: 9))
        path.line(to: NSPoint(x: 16, y: 15))
        path.stroke()

        // Origin dot
        NSBezierPath(ovalIn: NSRect(x: 1.5, y: 8, width: 3, height: 3)).fill()

        img.unlockFocus()
        return img
    }

    @objc private func toggleDefault() {
        if router.isDefaultBrowser {
            router.restoreSafari()
        } else {
            router.setAsDefault()
        }
        rebuildMenu()
    }

    @objc private func openSettings() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        win.title = "BrowserRouter Settings"
        win.center()
        win.contentView = NSHostingView(rootView: SettingsView(router: router, onClose: { win.close() }))
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func rebuildMenu() {
        setupStatusBar()
    }
}

// MARK: - SwiftUI Views

struct HeaderView: View {
    @ObservedObject var router: Router

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title3)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("BrowserRouter").font(.headline)
                Text("local → Chrome  •  other → Safari")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @ObservedObject var router: Router
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BrowserRouter").font(.title2).bold()
                    Text("Route local dev URLs to Chrome,\neverything else to Safari.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            Divider()

            GroupBox("Default Browser") {
                HStack {
                    Image(systemName: router.isDefaultBrowser ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(router.isDefaultBrowser ? .green : .secondary)
                    Text(router.isDefaultBrowser ? "BrowserRouter is the default" : "NOT the default browser")
                        .font(.body)
                    Spacer()
                    Button(router.isDefaultBrowser ? "Restore Safari" : "Set as Default") {
                        if router.isDefaultBrowser { router.restoreSafari() }
                        else { router.setAsDefault() }
                    }
                    .controlSize(.small)
                }
                .padding(8)
            }

            GroupBox("Routing Rules") {
                VStack(alignment: .leading, spacing: 2) {
                    RuleRow("localhost, 127.0.0.1, 0.0.0.0", "Chrome")
                    RuleRow("*.test, *.local, *.dev", "Chrome")
                    RuleRow("10.*, 192.168.*", "Chrome")
                    RuleRow("All other URLs", "Safari")
                }
                .padding(8)
            }

            Spacer()
            HStack {
                Spacer()
                Button("Close", action: onClose).keyboardShortcut(.escape)
            }
        }
        .padding(16)
    }
}

private struct RuleRow: View {
    let label: String; let dest: String
    init(_ label: String, _ dest: String) { self.label = label; self.dest = dest }

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(dest)
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(dest == "Chrome" ? .red : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background((dest == "Chrome" ? Color.red : Color.blue).opacity(0.1).cornerRadius(4))
        }
    }
}
