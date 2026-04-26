import Foundation

#if os(macOS)
import AppKit
import ApplicationServices
#endif

struct TrackingSample {
    var appName: String?
    var bundleIdentifier: String?
    var websiteURL: String?
}

final class TrackingService {
    private(set) var isTracking = false
    private var timer: Timer?
    private let sampleInterval: TimeInterval = 5
    var onSample: ((TrackingSample) -> Void)?
    var onError: ((String) -> Void)?

    func start() {
#if os(macOS)
        guard AXIsProcessTrusted() else {
            onError?(String(localized: "tracking.error.accessibilityNotGranted"))
            return
        }
#endif
        guard !isTracking else { return }
        isTracking = true

        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.sampleForegroundApplication()
        }
    }

    func stop() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }

    private func sampleForegroundApplication() {
#if os(macOS)
        let app = NSWorkspace.shared.frontmostApplication
        let sample = TrackingSample(
            appName: app?.localizedName,
            bundleIdentifier: app?.bundleIdentifier,
            websiteURL: browserURL(forBundleIdentifier: app?.bundleIdentifier)
        )
        onSample?(sample)
#else
        onSample?(TrackingSample())
#endif
    }

#if os(macOS)
    private func browserURL(forBundleIdentifier bundleIdentifier: String?) -> String? {
        guard let bundleIdentifier else { return nil }
        switch bundleIdentifier {
        case "com.apple.Safari":
            return runAppleScript("""
            tell application "Safari"
                if (count of windows) = 0 then return ""
                return URL of current tab of front window
            end tell
            """)
        case "com.google.Chrome":
            return runAppleScript("""
            tell application "Google Chrome"
                if (count of windows) = 0 then return ""
                return URL of active tab of front window
            end tell
            """)
        case "org.mozilla.firefox":
            if let url = runAppleScript("""
            tell application "Firefox"
                if (count of windows) = 0 then return ""
                return URL of active tab of front window
            end tell
            """), isLikelyURL(url) {
                return url
            }
            return runAppleScript("""
            tell application "System Events"
                tell process "Firefox"
                    try
                        set frontWindowName to name of front window
                        return frontWindowName
                    on error
                        return ""
                    end try
                end tell
            end tell
            """)
        case "com.microsoft.edgemac":
            return runAppleScript("""
            tell application "Microsoft Edge"
                if (count of windows) = 0 then return ""
                return URL of active tab of front window
            end tell
            """)
        default:
            return nil
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error,
           let message = error[NSAppleScript.errorMessage] as? String,
           !message.isEmpty {
            onError?(
                String(
                    format: String(localized: "tracking.error.appleScript"),
                    locale: Locale.current,
                    message
                )
            )
            return nil
        }
        let value = result.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        if value?.isEmpty == true { return nil }
        return value
    }

    private func isLikelyURL(_ value: String) -> Bool {
        value.hasPrefix("http://") || value.hasPrefix("https://")
    }
#endif
}
