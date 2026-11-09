import Foundation

/// Only real YouTube domains and exactly 11-character video IDs are accepted.
enum VideoURLParser {
    static func parse(_ input: String) -> String? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if validVideoID(value) { return value }
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let rawHost = url.host?.lowercased() else { return nil }
        let host = rawHost.hasPrefix("www.") ? String(rawHost.dropFirst(4)) : rawHost
        let pieces = url.path.split(separator: "/").map(String.init)
        if host == "youtu.be", let id = pieces.first {
            return validVideoID(id) ? id : nil
        }
        let hosts: Set<String> = ["youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com"]
        guard hosts.contains(host) else { return nil }
        if pieces.first == "watch" {
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "v" })?.value
            return id.flatMap { validVideoID($0) ? $0 : nil }
        }
        if pieces.count >= 2, ["shorts", "live", "embed", "v"].contains(pieces[0]) {
            return validVideoID(pieces[1]) ? pieces[1] : nil
        }
        return nil
    }

    /// Share sheet text may have explanatory text surrounding a YouTube link.
    static func parseSharedText(_ text: String) -> String? {
        if let id = parse(text) { return id }
        let pattern = #"https?://[^\s<>\"']+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let candidate = ns.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,;!?)]}"))
            if let id = parse(candidate) { return id }
        }
        return nil
    }

    private static func validVideoID(_ value: String) -> Bool {
        guard value.utf8.count == 11 else { return false }
        return value.utf8.allSatisfy { byte in
            (48...57).contains(byte) || (65...90).contains(byte) ||
            (97...122).contains(byte) || byte == 45 || byte == 95
        }
    }
}
