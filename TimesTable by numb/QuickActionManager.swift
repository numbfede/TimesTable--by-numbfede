import SwiftUI

#if os(iOS)
import Combine

// Configura i tipi di azioni rapide
enum QuickAction: String, Identifiable {
    case addClass = "com.numb.timestable.addclass"
    case addTask = "com.numb.timestable.addtask"
    
    var id: String { rawValue }
}

// Classe che gestisce l'azione ricevuta
@MainActor
final class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    @Published var action: QuickAction?
}

// AppDelegate per configurare il SceneDelegate
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Se l'app viene avviata da un'azione rapida mentre era chiusa, salviamo l'azione
        if let shortcutItem = options.shortcutItem {
            if let type = QuickAction(rawValue: shortcutItem.type) {
                QuickActionManager.shared.action = type
            }
        }
        
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// SceneDelegate per ricevere l'azione quando l'app è già in background
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let type = QuickAction(rawValue: shortcutItem.type) {
            QuickActionManager.shared.action = type
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
}
#endif

