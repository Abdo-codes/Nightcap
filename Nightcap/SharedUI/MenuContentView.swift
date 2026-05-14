import AppKit
import ComposableArchitecture
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct MenuContentView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        statusLine

        Divider()

        if store.watchedApps.isEmpty {
            Text("No apps watched")
                .foregroundStyle(.secondary)
        } else {
            ForEach(store.watchedApps) { app in
                Menu {
                    Button("Remove \(app.displayName)", role: .destructive) {
                        store.send(.removeAppRequested(app.id))
                    }
                } label: {
                    HStack {
                        Image(systemName: store.runningWatchedIDs.contains(app.bundleID)
                              ? "circle.fill"
                              : "circle")
                            .foregroundStyle(store.runningWatchedIDs.contains(app.bundleID)
                                             ? .green
                                             : .secondary)
                        Text(app.displayName)
                    }
                }
            }
        }

        Button("Add App…") { presentAppPicker() }

        Divider()

        Toggle(
            "Launch at Login",
            isOn: Binding(
                get: { store.launchAtLoginStatus.isOn },
                set: { store.send(.launchAtLoginToggled($0)) }
            )
        )

        if case .requiresApproval = store.launchAtLoginStatus {
            Button("Approve in System Settings…") {
                SMAppService.openSystemSettingsLoginItems()
            }
        }

        Button("About Nightcap") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }

        Divider()

        Button("Quit Nightcap") { store.send(.quitTapped) }
            .keyboardShortcut("q")
    }

    @ViewBuilder
    private var statusLine: some View {
        if store.assertionHeld {
            Label(holdingForLabel, systemImage: "cup.and.saucer.fill")
        } else {
            Label("Idle — sleep allowed", systemImage: "moon.zzz")
        }
    }

    private var holdingForLabel: String {
        let names = store.watchedApps
            .filter { store.runningWatchedIDs.contains($0.bundleID) }
            .map(\.displayName)
        if names.count <= 3 {
            return "Holding for: \(names.joined(separator: ", "))"
        }
        let first = names.prefix(3).joined(separator: ", ")
        return "Holding for: \(first) (+\(names.count - 3) more)"
    }

    private func presentAppPicker() {
        DispatchQueue.main.async {
            NSApp.activate()
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.application]
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.prompt = "Watch"
            panel.message = "Pick an app to keep your Mac awake while it's running."

            let response = panel.runModal()
            NSApp.setActivationPolicy(.accessory)

            guard response == .OK, let url = panel.url else { return }

            guard let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else {
                presentAlert(
                    title: "Couldn't read app info",
                    message: "That file isn't a recognizable app bundle. Try picking another."
                )
                return
            }

            if let existing = store.watchedApps.first(where: { $0.bundleID == bundleID }) {
                presentAlert(
                    title: "Already watching",
                    message: "\(existing.displayName) is already in your list."
                )
                return
            }

            let displayName = FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
            store.send(.addAppRequested(WatchedApp(bundleID: bundleID, displayName: displayName)))
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
