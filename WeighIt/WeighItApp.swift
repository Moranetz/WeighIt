import SwiftUI
import SwiftData

@main
struct WeighItApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Board.self, Hypothesis.self, Evidence.self, CellRating.self])
    }
}
