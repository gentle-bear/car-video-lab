import Foundation
import AVFoundation

/// Native video used only to validate Apple's supported CarPlay/AirPlay route.
/// YouTube's WKWebView iframe is NOT an AVPlayerItem/HLS asset and cannot be
/// silently converted into a CarPlay stream.
@MainActor
final class NativeHLSPlayback {
    static let shared = NativeHLSPlayback()

    // Apple developer test stream (Bip Bop) — not YouTube content.
    private let demoURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
    private(set) var player: AVPlayer

    private init() {
        player = AVPlayer(url: demoURL)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
    }

    func play() {
        // Restart the sample to make repeated checks deterministic.
        player.replaceCurrentItem(with: AVPlayerItem(url: demoURL))
        player.play()
    }

    func pause() { player.pause() }
}
