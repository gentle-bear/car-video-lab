import Foundation

@main
struct ParserSmoke {
    static func main() {
        let id = "M7lc1UVf-VE"
        let good = [
            id,
            "https://www.youtube.com/watch?v=\(id)&t=14",
            "https://youtu.be/\(id)",
            "https://m.youtube.com/watch?v=\(id)",
            "https://youtube.com/shorts/\(id)",
            "https://www.youtube.com/live/\(id)",
            "https://www.youtube-nocookie.com/embed/\(id)"
        ]
        let bad = [
            "", "hello", "https://example.com/watch?v=\(id)",
            "https://notyoutube.com/watch?v=\(id)",
            "https://youtube.com/watch?v=invalid", "javascript:alert(1)"
        ]
        for text in good { precondition(VideoURLParser.parse(text) == id, "Valid: \(text)") }
        for text in bad { precondition(VideoURLParser.parse(text) == nil, "Invalid: \(text)") }
        let shared = [
            "Check this out https://youtu.be/\(id) great!",
            "YouTube: https://www.youtube.com/watch?v=\(id)&feature=shared",
            "🎬 https://youtube.com/shorts/\(id)"
        ]
        for text in shared {
            precondition(VideoURLParser.parseSharedText(text) == id, "Share: \(text)")
        }
        precondition(VideoURLParser.parseSharedText("hello https://evil.youtube.com/watch?v=\(id)") == nil)
        print("ParserSmoke: PASS (\(good.count) URLs + \(bad.count) invalid + \(shared.count) share texts)")
    }
}
