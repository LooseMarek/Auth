import SwiftUI

@main
struct DemoAuthDefaultApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
