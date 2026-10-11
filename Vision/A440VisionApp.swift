import SwiftUI

@main
struct A440VisionApp: App {
    var body: some Scene {
        WindowGroup("A440") {
            TunerView().frame(minWidth: 600, minHeight: 480)
        }
        .defaultSize(width: 720, height: 760)
        .windowResizability(.contentMinSize)
    }
}
