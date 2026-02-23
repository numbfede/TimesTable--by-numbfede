import SwiftUI
import SwiftData

@main
struct TimesTableApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SchoolClass.self,
            StudyTask.self,
            ClassPreset.self
        ])

        // Using simple local storage.
        // To enable iCloud sync later:
        // 1. In Xcode: Target → Signing & Capabilities → + Capability → iCloud → enable CloudKit
        // 2. Create a container (e.g. iCloud.com.yourname.TimesTable)
        // 3. Change ModelConfiguration to: cloudKitDatabase: .private("your.container.id")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed (e.g. new fields added) — the old store is incompatible.
            // Delete it so the app can start fresh with the new schema.
            print("⚠️ ModelContainer load failed (\(error)). Deleting old store and recreating.")
            destroyOldStore(schema: schema)

            do {
                let freshConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                return try ModelContainer(for: schema, configurations: [freshConfig])
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }()

    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(themeManager.accentColor)
                .preferredColorScheme(colorScheme)
                .environment(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }

    private var colorScheme: ColorScheme? {
        switch themeManager.themeMode {
        case .light: return .light
        case .dark, .custom: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Store cleanup helper

private func destroyOldStore(schema: Schema) {
    // SwiftData stores the SQLite file in Application Support by default.
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    let candidates = [
        appSupport?.appendingPathComponent("default.store"),
        appSupport?.appendingPathComponent("default.store-shm"),
        appSupport?.appendingPathComponent("default.store-wal"),
    ]
    for url in candidates.compactMap({ $0 }) {
        try? FileManager.default.removeItem(at: url)
    }
}
