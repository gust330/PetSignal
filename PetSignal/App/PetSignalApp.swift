import SwiftUI

@main
struct PetSignalApp: App {
    @State private var reportStore = ReportStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(reportStore)
        }
    }
}
