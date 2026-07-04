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

        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openWelcome()
            }
        } else if #available(macOS 26, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkMenuBarVisibility()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { router.route(url) }
    }

    // ─── Status Bar ────────────────────────────────────────────

    private func makeIcon() -> NSImage {
        let img = NSImage(size: NSSize(width: 18, height: 18))
        img.lockFocus()

        let bg = NSColor.controlTextColor
        bg.set()

        let path = NSBezierPath()
        path.move(to: NSPoint(x: 9, y: 16))
        path.line(to: NSPoint(x: 9, y: 2))
        path.move(to: NSPoint(x: 4, y: 8))
        path.line(to: NSPoint(x: 9, y: 2))
        path.line(to: NSPoint(x: 14, y: 8))
        path.move(to: NSPoint(x: 9, y: 2))
        path.line(to: NSPoint(x: 9, y: 16))
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.stroke()

        let circle = NSBezierPath(ovalIn: NSRect(x: 4, y: 10, width: 10, height: 6))
        circle.lineWidth = 1.5
        circle.stroke()

        img.unlockFocus()
        img.isTemplate = true
        return img
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: 26)
        guard let btn = statusItem.button else { return }

        let icon = makeIcon()
        btn.image = icon
        btn.imageScaling = .scaleProportionallyDown
        btn.imagePosition = .imageOnly
        btn.toolTip = "BrowserRouter – route local URLs to Chrome, others to Safari"

        let menu = NSMenu()
        menu.addItem(createHeaderItem())
        menu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(
            title: router.isDefaultBrowser ? "Disable (restore Safari)" : "Set as Default Browser",
            action: #selector(toggleDefault),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Welcome Window", action: #selector(openWelcome), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Refresh Menu Bar Icon", action: #selector(refreshStatusItem), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.isVisible = true
        NSLog("BrowserRouter: status item set up (fixed length 26)")
    }

    private func createHeaderItem() -> NSMenuItem {
        let item = NSMenuItem()
        let hv = NSHostingView(rootView: HeaderView(router: router))
        hv.frame = NSRect(x: 0, y: 0, width: 220, height: 48)
        item.view = hv
        return item
    }

    // ─── macOS 26 Menu Bar Allow-List Detection ────────────────

    private func checkMenuBarVisibility() {
        guard let btn = statusItem?.button else { return }
        let win = btn.window
        if win == nil || !win!.isVisible || win!.screen == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.openTahoeGuidance()
            }
        } else {
            NSLog("BrowserRouter: status item window is visible ✅")
        }
    }

    @objc private func openTahoeGuidance() {
        let alert = NSAlert()
        alert.messageText = "BrowserRouter peut être masqué par macOS"
        alert.informativeText = """
        macOS 26 (Tahoe) a une nouvelle liste d'autorisation pour les icônes de la barre de menus.

        → Va dans Réglages Système > Menu Bar > Allow in the Menu Bar
        → Active « BrowserRouter »

        L'application fonctionne, mais macOS peut cacher son icône.
        """
        alert.addButton(withTitle: "Ouvrir les réglages Menu Bar")
        alert.addButton(withTitle: "OK")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openMenuBarSettings()
        }
    }

    private func openMenuBarSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!)
    }

    // ─── Windows ───────────────────────────────────────────────

    @objc private func openWelcome() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        win.title = "Welcome to BrowserRouter"
        win.center()
        win.contentView = NSHostingView(rootView: WelcomeView(
            router: router,
            onDismiss: { win.close() },
            onSettings: { win.close(); self.openSettings() }
        ))
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        win.title = "BrowserRouter Settings"
        win.center()
        win.contentView = NSHostingView(rootView: SettingsView(
            router: router,
            onClose: { win.close() }
        ))
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func refreshStatusItem() {
        if statusItem != nil {
            NSStatusBar.system.removeStatusItem(statusItem)
            statusItem = nil
        }
        setupStatusBar()
    }

    @objc private func restart() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            NSApplication.shared.terminate(nil)
        }
    }

    @objc private func toggleDefault() {
        if router.isDefaultBrowser { router.restoreSafari() }
        else { router.setAsDefault() }
        setupStatusBar()
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @ObservedObject var router: Router
    let onDismiss: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("BrowserRouter")
                .font(.largeTitle).bold()

            if #available(macOS 26, *) {
                VStack(spacing: 8) {
                    Label("Étape 1 : Ouvre Réglages > Menu Bar", systemImage: "1.circle")
                    Label("Étape 2 : Active « BrowserRouter » dans « Allow in the Menu Bar »", systemImage: "2.circle")
                    Label("Étape 3 : Reviens ici et clique « Set as Default Browser »", systemImage: "3.circle")
                }
                .font(.callout)
                .padding(10)
                .background(Color(.controlBackgroundColor).cornerRadius(8))

                Button("1. Ouvrir les réglages Menu Bar") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)

                Button("2. Redémarrer l'app (important)") {
                    let url = Bundle.main.bundleURL
                    let cfg = NSWorkspace.OpenConfiguration()
                    cfg.createsNewApplicationInstance = true
                    NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in
                        NSApplication.shared.terminate(nil)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Text("Route local dev URLs to Chrome\nand everything else to Safari.")
                    .font(.body).multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Label("Look in the menu bar (top-right)", systemImage: "menubar.arrow.up.rectangle")
                    Label("Click the  icon to open the menu", systemImage: "arrow.triangle.branch")
                    Label("Select \"Set as Default Browser\"", systemImage: "checkmark.circle")
                }
                .font(.callout)
            }

            HStack(spacing: 16) {
                Button("Set as Default Browser") {
                    router.setAsDefault()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Later") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(32)
        .frame(width: 440, height: 380)
    }
}

// MARK: - Header View

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

// MARK: - Settings View

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
