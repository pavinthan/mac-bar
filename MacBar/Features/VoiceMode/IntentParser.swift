import Foundation

enum ParsedIntent {
    case dictation(text: String)
    case command(action: String, params: [String: String])
}

final class VoiceIntentParser {
    var appAliases: [String: String] = [
        "safari": "Safari",
        "chrome": "Google Chrome",
        "googlechrome": "Google Chrome",
        "iterm": "iTerm2",
        "iterm2": "iTerm2",
        "terminal": "Terminal",
        "finder": "Finder"
    ]

    func parseIntent(transcript: String) -> ParsedIntent {
        return parseDeterministicCommand(from: transcript)
            ?? .dictation(text: cleanedDictation(transcript))
    }

    private func parseDeterministicCommand(from transcript: String) -> ParsedIntent? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()

        // Check app aliases first
        let normalized = normalizeAliasKey(lowered)
        if let aliasTarget = appAliases[normalized] {
            return .command(action: "switch_to", params: ["app": aliasTarget])
        }

        // Direct actions
        if lowered == "copy" || lowered.hasPrefix("copy ") {
            return .command(action: "copy", params: [:])
        }
        if lowered == "paste" || lowered.hasPrefix("paste ") {
            return .command(action: "paste", params: [:])
        }

        // Dictate prefixes
        let dictatePrefixes = ["type ", "insert ", "write ", "dictate "]
        for prefix in dictatePrefixes where lowered.hasPrefix(prefix) {
            let payload = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !payload.isEmpty {
                return .command(action: "dictate", params: ["text": payload])
            }
        }

        // Tab switching
        if let tabIndex = extractTabIndex(from: lowered) {
            return .command(action: "switch_tab", params: ["index": tabIndex])
        }

        // App switching
        if let app = extractAppTarget(from: lowered), !app.isEmpty {
            if let aliasResolved = appAliases[normalizeAliasKey(app)] {
                return .command(action: "switch_to", params: ["app": aliasResolved])
            }
            return .command(action: "switch_to", params: ["app": app])
        }

        return nil
    }

    private func cleanedDictation(_ text: String) -> String {
        let fillerWords: Set<String> = ["um", "uh", "like", "basically", "actually"]
        let phraseNormalized = text
            .replacingOccurrences(of: "you know", with: " ", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "i mean", with: " ", options: [.caseInsensitive, .regularExpression])
        let words = phraseNormalized.split(whereSeparator: \.isWhitespace).map(String.init)
        let filtered = words.filter { word in
            let n = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return !fillerWords.contains(n)
        }
        let sentence = filtered.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return sentence.isEmpty ? text : sentence
    }

    private func extractTabIndex(from text: String) -> String? {
        if let match = text.range(of: #"\bta[bp]\s+([a-z0-9]+)\b"#, options: .regularExpression) {
            let part = String(text[match])
            let token = part
                .replacingOccurrences(of: "tab", with: "")
                .replacingOccurrences(of: "tap", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let resolved = normalizeTabNumber(token) {
                return resolved
            }
        }

        let wordMap: [String: String] = [
            "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
            "six": "6", "seven": "7", "eight": "8", "nine": "9",
            "won": "1", "to": "2", "too": "2", "for": "4", "ate": "8"
        ]
        for (word, value) in wordMap where text.contains("tab \(word)") || text.contains("tap \(word)") {
            return value
        }
        return nil
    }

    private func normalizeTabNumber(_ token: String) -> String? {
        if let number = Int(token), (1...9).contains(number) {
            return String(number)
        }
        let map: [String: String] = [
            "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
            "six": "6", "seven": "7", "eight": "8", "nine": "9",
            "won": "1", "to": "2", "too": "2", "for": "4", "ate": "8"
        ]
        return map[token]
    }

    private func extractAppTarget(from text: String) -> String? {
        let patterns = [#"(?:^|\b)(?:switch to|go to|open)\s+(.+)$"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let ns = text as NSString
            let range = NSRange(location: 0, length: ns.length)
            guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 else {
                continue
            }
            let app = ns.substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .punctuationCharacters)
            if !app.isEmpty {
                return app
            }
        }
        return nil
    }

    private func normalizeAliasKey(_ raw: String) -> String {
        raw.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
