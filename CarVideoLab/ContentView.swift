import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

private enum Palette {
    static let base = Color(red: 0.043, green: 0.063, blue: 0.11)
    static let card = Color(red: 0.095, green: 0.123, blue: 0.19)
    static let subtle = Color(red: 0.66, green: 0.72, blue: 0.83)
    static let pink = Color(red: 0.99, green: 0.31, blue: 0.43)
    static let violet = Color(red: 0.49, green: 0.44, blue: 0.97)
}

struct ContentView: View {
    @StateObject private var model = PlayerModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var showSearch = false
    @State private var showLinkInput = false
    @State private var hasClipboardLink = false

    var body: some View {
        TabView(selection: $tab) {
            watchTab
                .tabItem { Label("Смотреть", systemImage: "play.rectangle.on.rectangle") }
                .tag(0)
            ReceiverTab(server: model.receiver, videoID: model.currentVideoID)
                .tabItem { Label("Браузер авто", systemImage: "network") }
                .tag(1)
            CarPlayAirPlayView()
                .tabItem { Label("CarPlay", systemImage: "airplayvideo") }
                .tag(2)
        }
        .tint(Palette.pink)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSearch) {
            YouTubeSearchSheet { id in model.openID(id); tab = 0 }
        }
        .sheet(isPresented: $showLinkInput) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Ссылка на ролик")
                        .font(.title2.bold())
                    TextField("https://youtu.be/…", text: $model.inputText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(15)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
                        .onSubmit(loadDraft)
                    Button(action: loadDraft) { Label("Открыть видео", systemImage: "play.fill") }
                        .buttonStyle(HighlightButton())
                    if let error = model.errorMessage { Text(error).foregroundStyle(.orange) }
                    Spacer()
                }
                .padding(22)
                .background(Palette.base.ignoresSafeArea())
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Закрыть") { showLinkInput = false } } }
            }
            .presentationDetents([.medium])
        }
        .onOpenURL(perform: receiveDeepLink)
        .onAppear(perform: detectClipboard)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { detectClipboard() }
        }
    }

    private var watchTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    playerCard
                    actionButtons
                    if hasClipboardLink { clipboardBanner }
                    recentSection
                    helpCard
                }
                .padding(18)
                .padding(.bottom, 15)
            }
            .background(Palette.base.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(LinearGradient(colors: [Palette.pink, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 25, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("CAR VIDEO LAB")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                Text("YouTube под рукой")
                    .font(.subheadline)
                    .foregroundStyle(Palette.subtle)
            }
            Spacer()
            if model.receiver.isRunning {
                Button { tab = 1 } label: {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .padding(10)
                        .background(Palette.card, in: Circle())
                }
                .accessibilityLabel("Экран авто подключён")
            }
        }
    }

    private var playerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("СЕЙЧАС В ПЛЕЕРЕ", systemImage: "waveform")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(Palette.subtle)
                Spacer()
                Text("YouTube")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.pink)
            }
            if let id = model.currentVideoID {
                YouTubeEmbedView(videoID: id)
                    .frame(height: 220)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Текущее видео").font(.headline)
                        Text(id).font(.caption.monospaced()).foregroundStyle(Palette.subtle)
                    }
                    Spacer()
                    ShareLink(item: URL(string: "https://youtu.be/\(id)")!) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Palette.pink)
                    Text("Выбери первый ролик")
                        .font(.title3.bold())
                    Text("Поиск, ссылка или меню «Поделиться» в YouTube")
                        .font(.caption)
                        .foregroundStyle(Palette.subtle)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
            }
            if model.receiver.isRunning {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Экран авто готов — выбор ролика синхронизируется")
                        .font(.caption)
                        .foregroundStyle(Palette.subtle)
                }
            }
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { showSearch = true } label: {
                Label("Выбрать на YouTube", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(HighlightButton())
            HStack(spacing: 12) {
                Button { showLinkInput = true } label: {
                    Label("По ссылке", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButton())
                Button { importFromClipboard() } label: {
                    Label("Вставить", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButton())
            }
        }
    }

    private var clipboardBanner: some View {
        Button(action: importFromClipboard) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.fill").font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Получил ссылку из YouTube?").font(.subheadline.bold())
                    Text("Нажми здесь, чтобы открыть видео")
                        .font(.caption)
                        .foregroundStyle(Palette.subtle)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(15)
            .background(Palette.violet.opacity(0.2), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Недавно смотрели").font(.title3.bold())
                Spacer()
                if !model.recents.isEmpty {
                    Button("Очистить") { model.clearHistory() }
                        .font(.caption)
                        .foregroundStyle(Palette.subtle)
                }
            }
            if model.recents.isEmpty {
                Text("Здесь появятся выбранные ролики.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.subtle)
                    .padding(.vertical, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(model.recents, id: \.self) { id in
                            Button { model.openID(id) } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Palette.card).overlay(Image(systemName: "play.fill"))
                                    }
                                    .frame(width: 180, height: 102)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 13))
                                    Text(id)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Palette.subtle)
                                        .lineLimit(1)
                                }
                                .frame(width: 180)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var helpCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.violet)
            VStack(alignment: .leading, spacing: 5) {
                Text("Для просмотра на стоянке").font(.subheadline.bold())
                Text("Для браузера авто используй вкладку «Браузер авто». Для проверки AirPlay и CarPlay Video — отдельную вкладку «CarPlay». Видеоблокировка автомобиля не обходится.")
                    .font(.caption)
                    .foregroundStyle(Palette.subtle)
            }
        }
        .padding(15)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func detectClipboard() { hasClipboardLink = UIPasteboard.general.hasStrings }
    private func importFromClipboard() {
        guard let clip = UIPasteboard.general.string else {
            model.errorMessage = "Буфер обмена пуст."
            showLinkInput = true
            return
        }
        model.open(clip)
        if model.errorMessage != nil { showLinkInput = true }
        hasClipboardLink = false
    }
    private func loadDraft() {
        model.open(model.inputText)
        if model.errorMessage == nil { showLinkInput = false }
    }
    private func receiveDeepLink(_ url: URL) {
        guard url.scheme == "carvideolab", url.host == "open",
              let video = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "url" })?.value else { return }
        model.open(video)
        tab = 0
    }
}

private struct HighlightButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Palette.pink, Palette.violet],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.68 : 1)
    }
}
private struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(Palette.card.opacity(configuration.isPressed ? 0.65 : 1),
                        in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct ReceiverTab: View {
    @ObservedObject var server: ReceiverServer
    let videoID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Экран автомобиля").font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("Вывод ролика через браузер планшета")
                            .font(.subheadline).foregroundStyle(Palette.subtle)
                    }
                    .padding(.top, 10)
                    VStack(spacing: 15) {
                        Image(systemName: server.isRunning ? "display.2" : "display")
                            .font(.system(size: 42))
                            .foregroundStyle(server.isRunning ? .green : Palette.violet)
                        Text(server.isRunning ? "Приёмник запущен" : "Подключить автомобиль")
                            .font(.title3.bold())
                        Text(server.isRunning ? "Открой адрес ниже в браузере автомобильного планшета" : "Телефон и планшет должны находиться в одной локальной сети")
                            .font(.subheadline)
                            .foregroundStyle(Palette.subtle)
                            .multilineTextAlignment(.center)
                        Button {
                            if server.isRunning { server.stop() } else { server.start() }
                        } label: {
                            Text(server.isRunning ? "Остановить подключение" : "Запустить приёмник")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HighlightButton())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(22)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 23))
                    if server.isRunning {
                        if let url = server.localURLs.first {
                            VStack(spacing: 14) {
                                if let code = QRCodeRenderer.make(url) {
                                    Image(uiImage: code)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 184, height: 184)
                                        .padding(12)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 13))
                                }
                                Text("Адрес автомобильного экрана").font(.subheadline.bold())
                                Text(url)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                                    .multilineTextAlignment(.center)
                                Button {
                                    UIPasteboard.general.string = url
                                } label: {
                                    Label("Скопировать адрес", systemImage: "doc.on.doc")
                                }
                                .font(.subheadline.weight(.medium))
                                Text("Код подключения: \(server.pin)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(Palette.subtle)
                                if server.localURLs.count > 1 {
                                    Text("Если адрес не открывается, попробуй альтернативный:")
                                        .font(.caption)
                                        .foregroundStyle(Palette.subtle)
                                    ForEach(server.localURLs.dropFirst(), id: \.self) { other in
                                        Button(other) { UIPasteboard.general.string = other }
                                            .font(.caption.monospaced())
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
                        } else {
                            Label("Не найден адрес Wi-Fi. Подключись к сети и нажми «Обновить адреса».", systemImage: "wifi.exclamationmark")
                                .foregroundStyle(.orange)
                        }
                        Button("Обновить адреса", systemImage: "arrow.clockwise") { server.refreshAddresses() }
                            .font(.subheadline)
                        if videoID != nil {
                            HStack(spacing: 12) {
                                Button { server.send("play") } label: {
                                    Label("Воспроизвести", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }.buttonStyle(SecondaryActionButton())
                                Button { server.send("pause") } label: {
                                    Label("Пауза", systemImage: "pause.fill")
                                        .frame(maxWidth: .infinity)
                                }.buttonStyle(SecondaryActionButton())
                            }
                            Text("Первый запуск видео может потребовать нажатия «Смотреть» в браузере автомобиля.")
                                .font(.caption).foregroundStyle(Palette.subtle)
                        }
                    }
                    if let error = server.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.orange)
                    }
                    Text("Только на стоянке. Оставь Car Video Lab открытым на iPhone: iOS может приостанавливать локальный сервер в фоне. Некоторые магнитолы блокируют браузер или встроенный YouTube-плеер.")
                        .font(.footnote)
                        .foregroundStyle(Palette.subtle)
                        .padding(15)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(18)
            }
            .background(Palette.base.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private enum QRCodeRenderer {
    static func make(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 9, y: 9))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
