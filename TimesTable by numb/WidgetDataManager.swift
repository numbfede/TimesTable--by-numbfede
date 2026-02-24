import Foundation
import SwiftData
import WidgetKit

// MARK: - Shared Data Model
struct WidgetClass: Codable, Identifiable {
    var id: String { name + "\(startTime.timeIntervalSince1970)" }
    var name: String
    var room: String?
    var startTime: Date
    var endTime: Date
    var hexColor: String
}

@MainActor
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let suiteName = "group.com.numb.TimesTable"
    
    // Convert SwiftData SchoolClass to Codable WidgetClass
    func updateWidgetData(classes: [SchoolClass]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        
        let now = Date()
        let cal = Calendar.current
        let todayWeekday = cal.component(.weekday, from: now)
        let normalizedToday = todayWeekday == 1 ? 7 : todayWeekday - 1
        
        // Filter classes for today
        // Note: We map the class start/end times to explicitly be matching today's date
        let todayClassesRaw = classes.filter { $0.dayOfWeek == normalizedToday }
        
        // Convert to WidgetClass matching today's actual calendar date so the widget logic is easy
        let widgetClasses: [WidgetClass] = todayClassesRaw.compactMap { sc in
            let classStart = sc.startTime
            let classEnd = sc.endTime
            
            let startComponents = cal.dateComponents([.hour, .minute], from: classStart)
            let endComponents = cal.dateComponents([.hour, .minute], from: classEnd)
            
            guard let exactStart = cal.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: now),
                  let exactEnd = cal.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: now) else {
                return nil
            }
            
            return WidgetClass(
                name: sc.name,
                room: sc.room,
                startTime: exactStart,
                endTime: exactEnd,
                hexColor: sc.color.toHex()
            )
        }.sorted { $0.startTime < $1.startTime }
        
        if let encoded = try? JSONEncoder().encode(widgetClasses) {
            defaults.set(encoded, forKey: "widgetClasses")
            // Tell the widget to refresh immediately
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

