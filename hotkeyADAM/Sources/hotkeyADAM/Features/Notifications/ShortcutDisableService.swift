import Foundation

/// Persists a user's request to stop showing a shortcut hint.
final class ShortcutDisableService {
    private let repository: ShortcutRepository

    init(repository: ShortcutRepository) {
        self.repository = repository
    }

    func disable(appName: String, elementTitle: String, shortcutString: String) {
        let element = UIElement(
            role: "",
            roleDescription: "",
            subrole: "",
            title: elementTitle,
            help: "",
            elementDescription: "",
            parentTitle: "",
            value: "",
            cocoaIdentifier: "",
            shortcutString: shortcutString)
        try? repository.disableShortcut(element: element,
                                        appName: appName,
                                        shortcutString: shortcutString)
    }
}
