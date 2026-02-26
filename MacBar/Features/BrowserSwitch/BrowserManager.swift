import AppKit
import UniformTypeIdentifiers

struct BrowserInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let icon: NSImage
    var isDefault: Bool
}

@Observable
final class BrowserManager {
    var browsers: [BrowserInfo] = []
    var currentDefaultID = ""

    private static let excludedIDs: Set<String> = [
        "com.googlecode.iterm2",
        "com.apple.Terminal",
        "com.sublimetext.4",
        "com.sublimetext.3",
        "com.microsoft.VSCode",
        "com.panic.Nova",
    ]

    func refresh() {
        guard let httpsURL = URL(string: "https:") else {
            return
        }

        let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: httpsURL)
        if let defaultApp = defaultAppURL,
           let bundle = Bundle(url: defaultApp) {
            currentDefaultID = bundle.bundleIdentifier ?? ""
        }

        let htmlHandlers = NSWorkspace.shared.urlsForApplications(toOpen: .html)
        let httpsHandlers = NSWorkspace.shared.urlsForApplications(toOpen: httpsURL)
        let browserURLs = Set(htmlHandlers).intersection(httpsHandlers)

        var seen = Set<String>()
        browsers = browserURLs
            .compactMap { url -> BrowserInfo? in
                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier,
                      !Self.excludedIDs.contains(bundleID),
                      !seen.contains(bundleID) else {
                    return nil
                }
                seen.insert(bundleID)

                let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? url.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 32, height: 32)

                return BrowserInfo(
                    id: bundleID,
                    name: name,
                    url: url,
                    icon: icon,
                    isDefault: bundleID == currentDefaultID
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func setDefault(browserID: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: browserID
        ) else {
            return
        }

        Task {
            do {
                try await NSWorkspace.shared.setDefaultApplication(
                    at: appURL, toOpenURLsWithScheme: "http"
                )
                try await NSWorkspace.shared.setDefaultApplication(
                    at: appURL, toOpenURLsWithScheme: "https"
                )
            } catch {
                print("Failed to set default browser: \(error)")
            }

            await MainActor.run {
                refresh()
            }
        }
    }
}
