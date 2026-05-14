import ComposableArchitecture
import SwiftUI

@main
struct NightcapApp: App {
    @State private var store: StoreOf<AppFeature>

    init() {
        let store = Store(initialState: AppFeature.State()) { AppFeature() }
        store.send(.onAppear)
        _store = State(initialValue: store)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(store: store)
        } label: {
            Image(systemName: store.assertionHeld
                  ? "cup.and.saucer.fill"
                  : "cup.and.saucer")
        }
        .menuBarExtraStyle(.menu)
    }
}
