//  PortfolioTelemetry.swift
//  Canonical zero-dependency analytics drop-in for the whole app fleet.
//  Source of truth: ~/Developer/_scripts/portfolio/PortfolioTelemetry.swift
//  Injected per-app by inject_telemetry.rb — DO NOT hand-edit the copy in an app repo;
//  edit the canonical file and re-run the injector so the fleet stays consistent.
//
//  Design contract:
//   • Zero third-party dependencies (pure Foundation). No SPM, no IDFA, no ATT, no PII.
//   • EGRESS-SAFE: if `ANALYTICS_KEY` (Info.plist) is empty/missing, events are buffered
//     to disk and NEVER sent. A shipped app phones home only after a key is supplied.
//   • Anonymous identity = random UUID in the Keychain (NOT UserDefaults — applies the
//     vibecoded-security lesson: tokens/ids in UserDefaults are extractable).
//   • PostHog-compatible `/capture/` JSON shape, but host/key are config — any
//     compatible collector works.
//   • Privacy nutrition label: "Diagnostics, NOT linked to the user." No data is
//     collected until ANALYTICS_KEY is set; declare accordingly when you flip it on.

import Foundation

enum Telemetry {

    // MARK: Config (from Info.plist; empty key ⇒ no network, ever)

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

    private static let appId: String =
        Bundle.main.bundleIdentifier ?? "unknown.app"
    private static let appVersion: String =
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")

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
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("portfolio_telemetry.jsonl")
    }

    // MARK: Public API

    /// Call once from the App entry `.task {}` / `init`.
    static func launch() {
        q.async {
            let first = anonId(createIfMissing: true)
            _ = first
            emitDay1ReturnIfDue()
            event("app_launch")
            flushBuffer()
        }
    }

    /// The single action that predicts retention for THIS app (define per app).
    static func activation(_ name: String) { event("activation", ["activation": name]) }

    /// The core value action. `surface` = where in the app it happened.
    static func coreAction(_ name: String, _ surface: String? = nil) {
        event("core_action", ["action": name, "surface": surface ?? ""])
    }

    static func paywallView(_ placement: String) {
        event("paywall_view", ["placement": placement])
    }
    static func paywallConvert(_ product: String) {
        event("paywall_convert", ["product": product])
    }

    /// Generic escape hatch.
    static func event(_ name: String, _ props: [String: String] = [:]) {
        let payload: [String: Any] = [
            "api_key": apiKey,
            "event": name,
            "distinct_id": anonId(createIfMissing: true),
            "timestamp": iso(Date()),
            "properties": props.merging([
                "$app": appId,
                "app_version": appVersion,
                "$lib": "portfolio-telemetry",
                "$os": "iOS"
            ]) { a, _ in a }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        q.async {
            guard enabled else { append(data); return }   // egress-safe: buffer only
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
            let ok = err == nil && (resp as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            done(ok)
        }.resume()
    }

    // MARK: Disk buffer (capped)

    private static func append(_ line: Data) {
        var s = String(data: line, encoding: .utf8) ?? ""
        s += "\n"
        let url = bufferURL
        if let h = try? FileHandle(forWritingTo: url) {
            defer { try? h.close() }
            h.seekToEndOfFile()
            h.write(s.data(using: .utf8) ?? Data())
        } else {
            try? s.data(using: .utf8)?.write(to: url)
        }
        // Cap at ~256 KB so a key-less app can't grow the buffer unbounded.
        if let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int,
           size > 262_144 {
            try? FileManager.default.removeItem(at: url)
        }
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

    // MARK: Anonymous identity (Keychain, not UserDefaults)

    private static let kcKey = "portfolio.telemetry.anon_id"

    private static func anonId(createIfMissing: Bool) -> String {
        if let existing = keychainGet(kcKey) { return existing }
        guard createIfMissing else { return "anon" }
        let id = UUID().uuidString
        keychainSet(kcKey, id)
        return id
    }

    private static func keychainGet(_ key: String) -> String? {
        let qd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(qd as CFDictionary, &out) == errSecSuccess,
              let d = out as? Data, let s = String(data: d, encoding: .utf8) else { return nil }
        return s
    }

    private static func keychainSet(_ key: String, _ value: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = value.data(using: .utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    // MARK: D1 return (calendar next-day after first launch)

    private static func emitDay1ReturnIfDue() {
        let firstKey = "portfolio.telemetry.first_launch"
        let firedKey = "portfolio.telemetry.d1_fired"
        let cal = Calendar.current
        guard let firstStr = keychainGet(firstKey), let first = Double(firstStr) else {
            keychainSet(firstKey, String(Date().timeIntervalSince1970))
            return
        }
        if keychainGet(firedKey) != nil { return }
        let firstDate = Date(timeIntervalSince1970: first)
        if let days = cal.dateComponents([.day], from: cal.startOfDay(for: firstDate),
                                         to: cal.startOfDay(for: Date())).day, days >= 1 {
            event("day1_return", ["days_since_first": String(days)])
            keychainSet(firedKey, "1")
        }
    }

    private static func iso(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: d)
    }
}
