import SwiftUI
import AVKit

/// System picker. AirPlay-capable vehicles appear only if the car itself
/// implements AirPlay video-in-car. This cannot unlock CarPlay video.
struct AirPlayPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        picker.tintColor = .white
        picker.activeTintColor = .systemPink
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) { }
}

struct CarPlayAirPlayView: View {
    @State private var player = NativeHLSPlayback.shared.player

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Label("CarPlay / AirPlay", systemImage: "car.side")
                        .font(.title.bold())
                    Text("Экспериментальная проверка видеовывода — только на стоянке.")
                        .foregroundStyle(.secondary)

                    GroupBox("1. Проверяем AirPlay-приёмник") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Если машина поддерживает AirPlay Video in Car, её экран появится в системном выборе устройств.")
                                .font(.subheadline)
                            HStack {
                                Label("Выбрать экран", systemImage: "airplayvideo")
                                Spacer()
                                AirPlayPicker().frame(width: 48, height: 46)
                            }
                            Text("Это проверка нативного HLS-плеера, не трансляция YouTube из WKWebView.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GroupBox("2. Тестовое видео Apple HLS") {
                        VStack(alignment: .leading, spacing: 10) {
                            VideoPlayer(player: player)
                                .frame(height: 192)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Button { NativeHLSPlayback.shared.play() } label: {
                                Label("Воспроизвести тест", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Пауза") { NativeHLSPlayback.shared.pause() }
                                .buttonStyle(.bordered)
                        }
                    }

                    GroupBox("3. CarPlay Video API") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("В проект добавлена CarPlay-сцена для iOS 27 и тестового HLS. Она появится в CarPlay только после получения разрешения Apple com.apple.developer.carplay-video и при поддержке Video in Car автомобилем.")
                            Text("Обычная бесплатная подпись через Sideloadly не предоставляет это разрешение. На штатном CarPlay без Video in Car приложение не появится.")
                                .foregroundStyle(.secondary)
                            Text("YouTube через CarPlay пока не реализован: официальный iframe-плеер нельзя передать как AVPlayer HLS без отдельной разрешённой интеграции.")
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(18)
            }
            .navigationTitle("Вывод на экран")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
