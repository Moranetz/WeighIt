import SwiftUI
import Combine
import SwiftData

@main
struct WeighItApp: App {
    init() {
        #if DEBUG
        DebugLaunchArgs.applyOnboardingBypass()
        #endif
    }

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

#if DEBUG
/// Test-only launch-argument bypass so the first-run screens (onboarding, the
/// tutorial board, the example picker, a truly blank board) can be reached and
/// captured without tapping through the app by hand. None of these flags exist
/// in a Release build — reading them is compiled out entirely.
///
/// Usage (simulator): pass as -args to `xcrun simctl launch`, e.g.
///   xcrun simctl launch <device> com.melmarion.WeighIt -reckonOnboarded 1
enum DebugLaunchArgs {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    private static func isSet(_ flag: String) -> Bool {
        guard let idx = arguments.firstIndex(of: flag) else { return false }
        guard idx + 1 < arguments.count else { return true }
        let value = arguments[idx + 1]
        return value == "1" || value.lowercased() == "true"
    }

    /// -reckonOnboarded 1        → skip the 3-page onboarding fullScreenCover
    /// -reckonTutorialDone 1     → skip the auto-inserted tutorial board
    static func applyOnboardingBypass() {
        if isSet("-reckonOnboarded") {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
        if isSet("-reckonTutorialDone") {
            UserDefaults.standard.set(true, forKey: "hasCompletedTutorial")
        }
    }

    /// -reckonForceBlankBoard 1  → skip the example picker, open a truly blank board
    static var forceBlankBoard: Bool { isSet("-reckonForceBlankBoard") }
    /// -reckonShowBoardList 1    → present the board-list sheet on launch
    static var showBoardList: Bool { isSet("-reckonShowBoardList") }
    /// -reckonShowCalibration 1 → present the calibration-history sheet on launch
    static var showCalibration: Bool { isSet("-reckonShowCalibration") }
}
#endif
