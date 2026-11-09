import Foundation
import Combine
import Network
import Darwin

private let receiverServerQueue = DispatchQueue(label: "CarVideoLab.ReceiverServer", qos: .userInitiated)

/// A small GET-only LAN server. No tracking or remote video downloading.
/// The app must stay foregrounded: iOS can suspend servers in the background.
@MainActor
final class ReceiverServer: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var localURLs: [String] = []
    @Published private(set) var pin = ""

    private let port: UInt16 = 8765
    private var listener: NWListener?
    private var currentVideoID: String?
    private var revision = 0
    private var command = "none"
    private var commandRevision = 0

    func updateVideo(_ id: String?) {
        currentVideoID = id
        revision += 1
    }

    func send(_ nextCommand: String) {
        guard ["play", "pause"].contains(nextCommand) else { return }
        command = nextCommand
        commandRevision += 1
    }

    func start() {
        guard listener == nil else { return }
        errorMessage = nil
        pin = String(format: "%06d", Int.random(in: 0...999_999))
        do {
            let tcpPort = NWEndpoint.Port(rawValue: port)!
            let nwListener = try NWListener(using: .tcp, on: tcpPort)
            listener = nwListener
            nwListener.newConnectionHandler = { [weak self] connection in
                guard let self else { connection.cancel(); return }
                self.handle(connection)
            }
            nwListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch state {
                    case .ready:
                        self.isRunning = true
                        self.refreshAddresses()
                    case .failed(let error):
                        self.errorMessage = "Не удалось запустить сервер: \(error.localizedDescription)"
                        self.stop()
                    case .cancelled:
                        self.isRunning = false
                    default: break
                    }
                }
            }
            nwListener.start(queue: receiverServerQueue)
        } catch {
            errorMessage = "Не удалось открыть порт: \(error.localizedDescription)"
            listener = nil
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        localURLs = []
    }

    func refreshAddresses() {
        var addresses: [(String, String)] = []
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0 else { return }
        defer { freeifaddrs(pointer) }
        var cursor = pointer
        while let node = cursor {
            let entry = node.pointee
            if let addr = entry.ifa_addr, addr.pointee.sa_family == sa_family_t(AF_INET),
               (entry.ifa_flags & UInt32(IFF_UP)) != 0,
               (entry.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 {
                let name = String(cString: entry.ifa_name)
                var ipv4 = UnsafeRawPointer(addr).assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                let output = inet_ntop(AF_INET, &ipv4, &buffer, socklen_t(INET_ADDRSTRLEN))
                if output != nil {
                    let ip = String(cString: buffer)
                    if !ip.hasPrefix("169.254.") { addresses.append((name, ip)) }
                }
            }
            cursor = entry.ifa_next
        }
        // Usually en0 is Wi-Fi, bridge100 is iPhone Personal Hotspot.
        addresses.sort { a, b in
            func priority(_ item: (String, String)) -> Int {
                if item.0 == "en0" { return 0 }
                if item.1 == "172.20.10.1" { return 1 }
                return 2
            }
            return priority(a) < priority(b)
        }
        localURLs = Array(Set(addresses.map { "http://\($0.1):\(port)/?pin=\(pin)" })).sorted()
    }

    nonisolated private func handle(_ connection: NWConnection) {
        connection.start(queue: receiverServerQueue)
        read(connection, accumulating: Data())
    }

    nonisolated private func read(_ connection: NWConnection, accumulating buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, complete, error in
            guard let self else { connection.cancel(); return }
            var next = buffer
            if let data { next.append(data) }
            guard next.count <= 16_384 else { connection.cancel(); return }
            if next.range(of: Data("\r\n\r\n".utf8)) != nil {
                let raw = String(decoding: next, as: UTF8.self)
                let requestLine = raw.components(separatedBy: "\r\n").first ?? ""
                Task { @MainActor in
                    let result = self.response(for: requestLine)
                    self.sendResponse(connection, status: result.0, mime: result.1, body: result.2)
                }
            } else if complete || error != nil {
                connection.cancel()
            } else {
                self.read(connection, accumulating: next)
            }
        }
    }

    private func response(for requestLine: String) -> (String, String, Data) {
        let pieces = requestLine.split(separator: " ")
        guard pieces.count >= 2, pieces[0] == "GET",
              let components = URLComponents(string: "http://localhost\(pieces[1])") else {
            return ("400 Bad Request", "text/plain; charset=utf-8", Data("Invalid request".utf8))
        }
        let givenPin = components.queryItems?.first(where: { $0.name == "pin" })?.value
        guard givenPin == pin else {
            return ("403 Forbidden", "text/plain; charset=utf-8", Data("Invalid pairing code".utf8))
        }
        if components.path == "/api/state" {
            let payload: [String: Any] = [
                "videoID": currentVideoID ?? "", "revision": revision,
                "command": command, "commandRevision": commandRevision
            ]
            let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
            return ("200 OK", "application/json; charset=utf-8", data)
        }
        if components.path == "/" {
            return ("200 OK", "text/html; charset=utf-8", Data(Self.receiverHTML.utf8))
        }
        return ("404 Not Found", "text/plain; charset=utf-8", Data("Not found".utf8))
    }

    nonisolated private func sendResponse(_ connection: NWConnection, status: String, mime: String, body: Data) {
        let head = "HTTP/1.1 \(status)\r\nContent-Type: \(mime)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n"
        var packet = Data(head.utf8)
        packet.append(body)
        connection.send(content: packet, completion: .contentProcessed { _ in connection.cancel() })
    }

    private static let receiverHTML = #"""
    <!doctype html><html lang="ru"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <title>Car Video Lab — экран</title><style>
    *{box-sizing:border-box}body{margin:0;background:#0a101c;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif}
    header{display:flex;justify-content:space-between;align-items:center;padding:16px 22px;background:#11192a}
    b{font-size:22px}small{font-size:12px;color:#a6b2c7}
    .dot{height:9px;width:9px;display:inline-block;border-radius:50%;background:#fca548;margin-right:8px}
    main{max-width:1200px;margin:auto;padding:18px}.frame{width:100%;aspect-ratio:16/9;background:#000;border-radius:16px;overflow:hidden;display:grid;place-items:center}
    iframe{width:100%;height:100%;border:0}.placeholder{text-align:center;color:#a6b2c7}
    .bar{display:flex;gap:12px;align-items:center;justify-content:center;padding:20px;flex-wrap:wrap}
    button{border:0;border-radius:12px;background:#e64b74;color:#fff;padding:12px 26px;font-size:17px;font-weight:700;cursor:pointer}
    button.secondary{background:#29354b}#status{color:#a6b2c7;text-align:center;font-size:14px}
    </style></head><body>
    <header><b>▶ Car Video Lab</b><small><span class="dot"></span>Локальный экран · Только на стоянке</small></header>
    <main><div id="frame" class="frame"><div class="placeholder">Выбери видео на iPhone</div></div>
    <div class="bar"><button id="play">▶ Смотреть</button><button id="pause" class="secondary">Ⅱ Пауза</button></div>
    <p id="status">Подключение к iPhone…</p></main>
    <script>
    (function(){
      const pin = new URLSearchParams(location.search).get('pin') || '';
      const frame = document.getElementById('frame');
      const status = document.getElementById('status');
      let iframe = null, lastId = '', lastCommandRevision = -1;
      function command(action){
        if(iframe && iframe.contentWindow){
          iframe.contentWindow.postMessage(JSON.stringify({event:'command',func:action+'Video',args:[]}), 'https://www.youtube.com');
        }
      }
      document.getElementById('play').onclick = () => command('play');
      document.getElementById('pause').onclick = () => command('pause');
      async function refresh(){
        try {
          const response = await fetch('/api/state?pin='+encodeURIComponent(pin), {cache:'no-store'});
          if(!response.ok) throw Error('HTTP '+response.status);
          const state = await response.json();
          status.textContent = state.videoID ? 'Видео выбрано на iPhone · Нажми Смотреть на экране автомобиля' : 'Выбери видео на iPhone';
          if(state.videoID && /^[A-Za-z0-9_-]{11}$/.test(state.videoID) && state.videoID !== lastId){
            lastId = state.videoID;
            iframe = document.createElement('iframe');
            iframe.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
            iframe.referrerPolicy = 'strict-origin-when-cross-origin';
            const origin = encodeURIComponent(location.origin);
            iframe.src = 'https://www.youtube.com/embed/'+encodeURIComponent(lastId)+'?enablejsapi=1&playsinline=1&controls=1&origin='+origin;
            iframe.allowFullscreen = true;
            frame.replaceChildren(iframe);
          }
          if(state.commandRevision !== lastCommandRevision){
            lastCommandRevision=state.commandRevision;
            if(state.command === 'pause') command('pause');
            // Autoplay/play can be blocked until a tap on this browser.
          }
        } catch (err) { status.textContent='Нет связи с iPhone. Оставь Car Video Lab открытым, проверь Wi-Fi.'; }
      }
      refresh();setInterval(refresh,1500);
    })();
    </script></body></html>
    """#
}
