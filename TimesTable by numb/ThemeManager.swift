import SwiftUI
import Combine

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case custom = "Custom"
    var id: String { rawValue }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    // MARK: - Selected Mode
    var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }

    // MARK: - Global Accent
    var accentHex: String {
        didSet { UserDefaults.standard.set(accentHex, forKey: "accentHex") }
    }
    
    var accentColor: Color {
        get { Color(hex: accentHex) ?? .blue }
        set { accentHex = newValue.toHex() }
    }

    // MARK: - Custom Theme Variables
    var customBackgroundHex: String {
        didSet { UserDefaults.standard.set(customBackgroundHex, forKey: "customBackgroundHex") }
    }
    
    var customButtonHex: String {
        didSet { UserDefaults.standard.set(customButtonHex, forKey: "customButtonHex") }
    }
    
    var customIconHex: String {
        didSet { UserDefaults.standard.set(customIconHex, forKey: "customIconHex") }
    }

    // Colors
    var customBackgroundColor: Color {
        get { Color(hex: customBackgroundHex) ?? Color(white: 0.1) }
        set { customBackgroundHex = newValue.toHex() }
    }
    var customButtonColor: Color {
        get { Color(hex: customButtonHex) ?? Color(white: 0.2) }
        set { customButtonHex = newValue.toHex() }
    }
    var customIconColor: Color {
        get { Color(hex: customIconHex) ?? .white }
        set { customIconHex = newValue.toHex() }
    }

    // MARK: - Background Image (GIF / Static)
    
    private let backgroundImageFilename = "custom_background.data"
    
    private var imageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(backgroundImageFilename)
    }

    // This property holds the raw data (which could be a GIF)
    var backgroundImageData: Data? {
        didSet {
            if let backgroundImageData {
                try? backgroundImageData.write(to: imageURL)
            } else {
                try? FileManager.default.removeItem(at: imageURL)
            }
        }
    }
    
    var hasCustomBackgroundImage: Bool {
        FileManager.default.fileExists(atPath: imageURL.path)
    }

    // Trigger UI updates
    func notifyChange() {
        // Since @Observable tracks property access, updating a dummy property
        // or explicitly writing to UserDefaults is sufficient.
        objectWillChange.send()
    }
    
    // For manual combine back-compat if needed in older views
    let objectWillChange = PassthroughSubject<Void, Never>()

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "themeMode"), let mode = ThemeMode(rawValue: raw) {
            self.themeMode = mode
        } else {
            self.themeMode = .system
        }
        self.accentHex = UserDefaults.standard.string(forKey: "accentHex") ?? "#0A84FF"
        self.customBackgroundHex = UserDefaults.standard.string(forKey: "customBackgroundHex") ?? "#1C1C1E"
        self.customButtonHex = UserDefaults.standard.string(forKey: "customButtonHex") ?? "#2C2C2E"
        self.customIconHex = UserDefaults.standard.string(forKey: "customIconHex") ?? "#FFFFFF"
        
        self.backgroundImageData = try? Data(contentsOf: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("custom_background.data"))
    }
}

