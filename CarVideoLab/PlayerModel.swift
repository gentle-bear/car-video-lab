import Foundation
import Combine

@MainActor
final class PlayerModel: ObservableObject {
    @Published private(set) var currentVideoID: String?
    @Published private(set) var recents: [String]
    @Published var inputText = ""
    @Published var errorMessage: String?
    let receiver = ReceiverServer()

    init() {
        recents = UserDefaults.standard.stringArray(forKey: "recentVideos") ?? []
        currentVideoID = recents.first
        receiver.updateVideo(currentVideoID)
    }

    func open(_ input: String) {
        guard let id = VideoURLParser.parseSharedText(input) else {
            errorMessage = "Нужна ссылка на конкретный ролик YouTube."
            return
        }
        openID(id)
    }

    func openID(_ id: String) {
        guard let validated = VideoURLParser.parse(id) else { return }
        errorMessage = nil
        currentVideoID = validated
        inputText = "https://youtu.be/\(validated)"
        recents.removeAll { $0 == validated }
        recents.insert(validated, at: 0)
        recents = Array(recents.prefix(12))
        UserDefaults.standard.set(recents, forKey: "recentVideos")
        receiver.updateVideo(validated)
    }

    func clearHistory() {
        recents = []
        UserDefaults.standard.removeObject(forKey: "recentVideos")
    }
}
