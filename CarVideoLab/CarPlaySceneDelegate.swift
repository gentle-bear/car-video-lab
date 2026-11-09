import UIKit
import CarPlay
import AVFoundation

/// Only launched by iOS if Apple has granted the CarPlay VIDEO entitlement
/// and the connected vehicle advertises the video-in-car feature.
/// Merely building/installing the IPA with Sideloadly will not grant that entitlement.
@available(iOS 27.0, *)
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPSessionConfigurationDelegate {
    private var sessionConfiguration: CPSessionConfiguration?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        let configuration = CPSessionConfiguration(delegate: self)
        sessionConfiguration = configuration

        let supported = configuration.supportsVideoPlayback
        let testVideo = CPListItem(
            text: "Тест CarPlay Video (Apple)",
            detailText: supported ? "Нативное HLS-видео — только на стоянке" : "Автомобиль не поддерживает Video in Car"
        )
        testVideo.isEnabled = supported
        if supported {
            testVideo.playbackConfiguration = CPPlaybackConfiguration(
                preferredPresentation: .video,
                playbackAction: .play,
                elapsedTime: .zero,
                duration: .zero
            )
            testVideo.handler = { _, completion in
                NativeHLSPlayback.shared.play()
                completion()
            }
        }

        let youtubeInfo = CPListItem(
            text: "YouTube",
            detailText: "Встроенный YouTube iframe не является нативным HLS-потоком"
        )
        youtubeInfo.isEnabled = false

        let list = CPListTemplate(
            title: "Car Video Lab",
            sections: [CPListSection(items: [testVideo, youtubeInfo])]
        )
        interfaceController.setRootTemplate(list, animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        NativeHLSPlayback.shared.pause()
        sessionConfiguration = nil
    }
}
