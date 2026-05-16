import SwiftUI
import Combine
import SwiftData

@main
struct WeighItApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task { Telemetry.launch() }
                .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
                    ReviewManager.shared.addPlayTime(10)
                }
        }
        .modelContainer(for: [Board.self, Hypothesis.self, Evidence.self, CellRating.self])
    }
}
