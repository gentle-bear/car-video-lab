import SwiftUI
import WebKit

/// Official YouTube embedded player, loaded through the system WKWebView.
/// It is not a CarPlay scene. AirPlay support depends on video and receiver.
struct YouTubeEmbedView: UIViewRepresentable {
    let videoID: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        // Keep playback user-initiated; respect autoplay restrictions.
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.backgroundColor = .black
        view.isOpaque = false
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedVideoID != videoID else { return }
        context.coordinator.loadedVideoID = videoID

        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.youtube.com"
        url.path = "/embed/\(videoID)"
        url.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "controls", value: "1")
        ]
        guard let target = url.url else { return }

        var request = URLRequest(url: target)
        // Google requires an HTTP Referer in WebView embeds (error 153 otherwise).
        // The app's own Bundle ID is the required identity; do not impersonate a site.
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.carvideolab"
        request.setValue("https://\(bundleID.lowercased())", forHTTPHeaderField: "Referer")
        webView.load(request)
    }

    final class Coordinator {
        var loadedVideoID: String?
    }
}
