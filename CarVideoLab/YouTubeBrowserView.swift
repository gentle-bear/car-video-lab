import SwiftUI
import WebKit

/// Browses YouTube's own search page: no scraping service and no API key.
/// Intercepts a tapped video URL to send its ID back to the player.
struct YouTubeBrowserView: UIViewRepresentable {
    let query: String
    let onVideoSelected: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onVideoSelected: onVideoSelected) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "selectedVideo")
        let script = #"""
        (function () {
          document.addEventListener('click', function (event) {
            var node = event.target;
            var link = node && node.closest ? node.closest('a[href]') : null;
            if (!link) return;
            var url;
            try { url = new URL(link.href, document.baseURI); } catch (_) { return; }
            var host = url.hostname.toLowerCase();
            var isYT = host === 'youtube.com' || host === 'www.youtube.com' ||
                       host === 'm.youtube.com' || host === 'youtu.be';
            var videoLink = url.pathname === '/watch' ||
                            /^\/(shorts|live)\/[A-Za-z0-9_-]{11}/.test(url.pathname) ||
                            host === 'youtu.be';
            if (isYT && videoLink) {
              event.preventDefault();
              event.stopPropagation();
              window.webkit.messageHandlers.selectedVideo.postMessage(url.href);
            }
          }, true);
        })();
        """#
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.backgroundColor = .black
        view.isOpaque = false
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.lastQuery != query else { return }
        context.coordinator.lastQuery = query
        var components = URLComponents(string: "https://m.youtube.com/results")!
        components.queryItems = [URLQueryItem(name: "search_query", value: query)]
        if let url = components.url { view.load(URLRequest(url: url)) }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var lastQuery: String?
        let onVideoSelected: (String) -> Void
        init(onVideoSelected: @escaping (String) -> Void) {
            self.onVideoSelected = onVideoSelected
        }
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let link = message.body as? String,
                  let id = VideoURLParser.parseSharedText(link) else { return }
            DispatchQueue.main.async { self.onVideoSelected(id) }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               let id = VideoURLParser.parse(url.absoluteString) {
                DispatchQueue.main.async { self.onVideoSelected(id) }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct YouTubeSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var submitted = ""
    let select: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Найти видео на YouTube", text: $text)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit(search)
                    Button("Искать", action: search)
                        .font(.subheadline.weight(.bold))
                }
                .padding(12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                .padding(14)
                Text("Нажми на найденный ролик — он откроется в Car Video Lab.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
                YouTubeBrowserView(query: submitted) { id in
                    select(id)
                    dismiss()
                }
            }
            .background(Color(red: 0.055, green: 0.071, blue: 0.105))
            .navigationTitle("Поиск YouTube")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }

    private func search() { submitted = text.trimmingCharacters(in: .whitespacesAndNewlines) }
}
