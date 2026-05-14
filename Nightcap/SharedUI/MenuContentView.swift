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
            Text("No apps added")
                .foregroundStyle(.secondary)
        } else {
            ForEach(store.watchedApps) { app in
                Menu {
                    Button(app.isObserved ? "Pause Watching" : "Resume Watching") {
                        store.send(.observationToggled(app.id, !app.isObserved))
                    }

                    Button("Remove from List", role: .destructive) {
                        store.send(.removeAppRequested(app.id))
                    }
                } label: {
                    HStack {
                        Image(systemName: statusIcon(for: app))
                            .foregroundStyle(statusColor(for: app))
                        Text(app.displayName)
                        if !app.isObserved {
                            Text("Paused")
                                .foregroundStyle(.secondary)
                        }
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
            Label("Keeping Mac Awake", systemImage: "cup.and.saucer.fill")
            Text(activeAppsLabel)
                .foregroundStyle(.secondary)
        } else {
            Label("Idle", systemImage: "moon.zzz")
            Text("Sleep allowed")
                .foregroundStyle(.secondary)
        }
    }

    private var activeAppsLabel: String {
        let count = store.runningWatchedIDs.count
        return count == 1 ? "1 app active" : "\(count) apps active"
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
                    title: "Already in your list",
                    message: existing.isObserved
                        ? "\(existing.displayName) is already being watched."
                        : "\(existing.displayName) is already in your list. Choose Resume Watching from its menu to watch it again."
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

    private func statusIcon(for app: WatchedApp) -> String {
        guard app.isObserved else { return "pause.circle" }
        return store.runningWatchedIDs.contains(app.bundleID) ? "circle.fill" : "circle"
    }

    private func statusColor(for app: WatchedApp) -> Color {
        guard app.isObserved else { return .secondary }
        return store.runningWatchedIDs.contains(app.bundleID) ? .green : .secondary
    }
}
