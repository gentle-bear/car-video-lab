import UIKit
import UniformTypeIdentifiers

/// Official iOS Share Extension. Does not try to forcibly launch its containing app.
/// Copying to the system clipboard works without App Groups / paid entitlements.
final class ShareViewController: UIViewController {
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private var sharedText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.15, alpha: 1)
        titleLabel.text = "Car Video Lab"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 24)
        messageLabel.text = "Получаем ссылку YouTube…"
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        let button = UIButton(type: .system)
        button.setTitle("Скопировать и закрыть", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor(red: 0.92, green: 0.26, blue: 0.42, alpha: 1)
        button.layer.cornerRadius = 13
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addTarget(self, action: #selector(finish), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, button])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25)
        ])
        loadSharedURL()
    }

    private func loadSharedURL() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            read(provider, identifier: UTType.url.identifier)
        } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            read(provider, identifier: UTType.plainText.identifier)
        } else {
            messageLabel.text = "Ссылка не найдена. В YouTube выбери «Поделиться» → Car Video Lab."
        }
    }

    private func read(_ provider: NSItemProvider, identifier: String) {
        provider.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] item, error in
            let text = (item as? URL)?.absoluteString ?? (item as? String)
            DispatchQueue.main.async {
                guard let self else { return }
                if let text, text.contains("youtu") {
                    self.sharedText = text
                    UIPasteboard.general.string = text
                    self.messageLabel.text = "Ссылка скопирована. Открой Car Video Lab и нажми «Вставить»."
                } else {
                    self.messageLabel.text = "Не удалось получить ссылку YouTube. Попробуй ещё раз."
                }
            }
        }
    }

    @objc private func finish() {
        if let sharedText { UIPasteboard.general.string = sharedText }
        extensionContext?.completeRequest(returningItems: nil)
    }
}
