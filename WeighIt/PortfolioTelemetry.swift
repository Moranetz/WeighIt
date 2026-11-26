//  PortfolioTelemetry.swift
//  Canonical zero-dependency analytics drop-in for the whole app fleet.
//  Source of truth: ~/Developer/_scripts/portfolio/PortfolioTelemetry.swift
//  Injected per-app by inject_telemetry.rb — DO NOT hand-edit the copy in an app repo;
//  edit the canonical file and re-run the injector so the fleet stays consistent.
//
//  v2 (iter5) — rewritten after the cold-eyes audit found data-integrity bugs in v1:
//   • Identity moved Keychain→UserDefaults: install-scoped. Reinstall = new user, which
//     is the HONEST default for retention. v1's Keychain id persisted across delete/
//     reinstall and systematically inflated retention (confidently-wrong data).
//   • Removed the client-side `day1_return` event: v1 fired it for ANY later return and
//     mislabeled it D1. Retention/activation are now derived SERVER-SIDE in PostHog from
//     reliable `app_launch` events (distinct_id + timestamp + days_since_install +
//     launch_count). The client does not lie about cohorts.
//   • Buffer cap is now FIFO trim (keep last N), not "delete the whole file."
//
//  Contract unchanged: zero deps (Foundation only), no IDFA/ATT/PII. EGRESS-SAFE — if
//  `ANALYTICS_KEY` (Info.plist) is empty/missing, events buffer to disk and are NEVER
//  sent. Privacy label: "Diagnostics, not linked to the user" (once a key is set).

import Foundation

enum Telemetry {

    // MARK: Config (empty key ⇒ no network, ever)

    private static let apiKey: String = {
        (Bundle.main.object(forInfoDictionaryKey: "ANALYTICS_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }()
    private static let host: String = {
        let h = (Bundle.main.object(forInfoDictionaryKey: "ANALYTICS_HOST") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return h.isEmpty ? "https://us.i.posthog.com" : h
    }()
    private static var enabled: Bool { !apiKey.isEmpty }

    private static let appId = Bundle.main.bundleIdentifier ?? "unknown.app"
    private static let appVersion =
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")

    // MARK: Identity & install state (UserDefaults — install-scoped, honest)

    private static let d = UserDefaults.standard
    private static let kID = "portfolio.telemetry.anon_id"
    private static let kFirst = "portfolio.telemetry.first_seen"
    private static let kLaunches = "portfolio.telemetry.launch_count"

    private static var anonId: String {
        if let s = d.string(forKey: kID) { return s }
        let s = UUID().uuidString
        d.set(s, forKey: kID)
        return s
    }

    /// app_launch with the props PostHog needs to derive activation + D1/D7/D30
    /// retention server-side. No client-side cohort math (v1's bug).
    private static func launchProps() -> [String: String] {
        let now = Date()
        if d.object(forKey: kFirst) == nil { d.set(now.timeIntervalSince1970, forKey: kFirst) }
        let first = Date(timeIntervalSince1970: d.double(forKey: kFirst))
        let days = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: first),
            to: Calendar.current.startOfDay(for: now)).day ?? 0
        let n = d.integer(forKey: kLaunches) + 1
        d.set(n, forKey: kLaunches)
        return ["days_since_install": String(days), "launch_count": String(n)]
    }

    // MARK: Plumbing

    private static let q = DispatchQueue(label: "portfolio.telemetry", qos: .utility)
    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 12
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()
    private static var bufferURL: URL {
        let dir = (try? FileManager.default.url(for: .applicationSupportDirectory,
                    in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("portfolio_telemetry.jsonl")
    }

    // MARK: Public API (signatures unchanged — already-wired call sites keep compiling)

    /// Call once from the App entry `.task {}` / `init`.
    static func launch() {
        q.async {
            event("app_launch", launchProps())
            flushBuffer()
        }
    }

    /// The first meaningful success in a session (define the verb per app).
    static func activation(_ name: String) { event("activation", ["activation": name]) }

    /// The core value action, repeated. `surface` = where it happened.
    static func coreAction(_ name: String, _ surface: String? = nil) {
        event("core_action", ["action": name, "surface": surface ?? ""])
    }

    static func paywallView(_ placement: String) {
        event("paywall_view", ["placement": placement])
    }
    static func paywallConvert(_ product: String) {
        event("paywall_convert", ["product": product])
    }

    static func event(_ name: String, _ props: [String: String] = [:]) {
        let payload: [String: Any] = [
            "api_key": apiKey,
            "event": name,
            "distinct_id": anonId,
            "timestamp": iso(Date()),
            "properties": props.merging([
                "$app": appId, "app_version": appVersion,
                "$lib": "portfolio-telemetry", "$os": "iOS"
            ]) { a, _ in a }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        q.async {
            guard enabled else { append(data); return }   // egress-safe
            send(data) { ok in if !ok { append(data) } }
        }
    }

    // MARK: Network

    private static func send(_ body: Data, _ done: @escaping (Bool) -> Void) {
        guard let url = URL(string: host + "/capture/") else { done(false); return }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = body
        session.dataTask(with: r) { _, resp, err in
            let ok = err == nil &&
                (resp as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            done(ok)
        }.resume()
    }

    // MARK: Disk buffer — FIFO trim (keep last N), never nuke

    private static let bufferMaxLines = 500

    private static func append(_ line: Data) {
        let url = bufferURL
        var lines: [String] = []
        if let raw = try? String(contentsOf: url, encoding: .utf8), !raw.isEmpty {
            lines = raw.split(separator: "\n").map(String.init)
        }
        if let s = String(data: line, encoding: .utf8) { lines.append(s) }
        if lines.count > bufferMaxLines { lines = Array(lines.suffix(bufferMaxLines)) }
        try? (lines.joined(separator: "\n") + "\n").data(using: .utf8)?.write(to: url)
    }

    private static func flushBuffer() {
        guard enabled else { return }
        let url = bufferURL
        guard let raw = try? String(contentsOf: url, encoding: .utf8), !raw.isEmpty else { return }
        try? FileManager.default.removeItem(at: url)
        for line in raw.split(separator: "\n") {
            if let d = line.data(using: .utf8) { send(d) { ok in if !ok { append(d) } } }
        }
    }

    private static func iso(_ dt: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: dt)
    }
}
