import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {
        Task { await checkStatus() }
    }

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    /// Schedule a notification for a class on a given weekday.
    func scheduleNotification(for schoolClass: SchoolClass) {
        guard isAuthorized else {
            print("🔕 [NotifManager] Not authorized — skipping \(schoolClass.name)")
            return
        }

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "notificationsEnabled") else {
            print("🔕 [NotifManager] Notifications disabled in settings — skipping \(schoolClass.name)")
            return
        }

        let offset = defaults.object(forKey: "reminderOffset") as? Int ?? 10

        let center = UNUserNotificationCenter.current()
        let id = schoolClass.id.uuidString

        // Remove existing notification for this class
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "La tua lezione di \(schoolClass.name) sta per iniziare!")
        var locationParts: [String] = []
        if let room = schoolClass.room, !room.isEmpty { locationParts.append(String(localized: "Room: \(room)")) }
        if let teacher = schoolClass.teacher, !teacher.isEmpty { locationParts.append(teacher) }
        content.body = locationParts.isEmpty
            ? String(localized: "Tra \(offset) minuti")
            : locationParts.joined(separator: " · ") + " — " + String(localized: "Tra \(offset) minuti")
        content.sound = .default

        // Build trigger: weekday + time - offset min
        let cal = Calendar.current
        let startComponents = cal.dateComponents([.hour, .minute], from: schoolClass.startTime)
        guard let hour = startComponents.hour, let minute = startComponents.minute else {
            print("⚠️ [NotifManager] Could not extract time components for \(schoolClass.name)")
            return
        }

        var notifMinute = minute - offset
        var notifHour = hour
        while notifMinute < 0 {
            notifMinute += 60
            notifHour -= 1
        }
        var weekdayOffset = 0
        if notifHour < 0 {
            notifHour += 24
            weekdayOffset = -1
        }

        // dayOfWeek: 1=Mon→2, 2=Tue→3 ... 7=Sun→1 (Calendar weekday)
        var calWeekday = schoolClass.dayOfWeek == 7 ? 1 : schoolClass.dayOfWeek + 1

        if weekdayOffset < 0 {
            calWeekday -= 1
            if calWeekday < 1 { calWeekday = 7 }
        }

        var triggerComponents = DateComponents()
        triggerComponents.weekday = calWeekday
        triggerComponents.hour = notifHour
        triggerComponents.minute = notifMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        print("📅 [NotifManager] Scheduling '\(schoolClass.name)' → weekday \(calWeekday), \(notifHour):\(String(format: "%02d", notifMinute)) (offset -\(offset)min)")

        let className = schoolClass.name
        center.add(request) { [className] error in
            if let error = error {
                print("❌ [NotifManager] Failed to add notification: \(error.localizedDescription)")
            } else {
                print("✅ [NotifManager] Notification scheduled for '\(className)'")
            }
        }
    }

    /// Reschedule all notifications (called after create/edit/delete)
    func rescheduleAll(classes: [SchoolClass], tasks: [StudyTask]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        guard isAuthorized else { return }
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: "notificationsEnabled") {
            for c in classes {
                scheduleNotification(for: c)
            }
        }
        
        if defaults.bool(forKey: "taskNotificationsEnabled") {
            for t in tasks {
                scheduleTaskNotifications(for: t)
            }
        }
        
        // Debug: print pending count
        center.getPendingNotificationRequests { requests in
            print("📋 [NotifManager] Total pending notifications: \(requests.count)")
        }
    }

    func removeNotification(for schoolClass: SchoolClass) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [schoolClass.id.uuidString])
    }

    func scheduleTaskNotifications(for task: StudyTask) {
        guard isAuthorized else { return }

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "taskNotificationsEnabled") else { return }

        let center = UNUserNotificationCenter.current()
        let baseId = task.id.uuidString
        let idsToRemove = (0...14).map { "\(baseId)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        
        guard !task.isCompleted else { return }

        let days = defaults.object(forKey: "taskReminderDays") as? Int ?? 5
        let cal = Calendar.current
        
        for dayOffset in 0...days {
            guard let notifDate = cal.date(byAdding: .day, value: -dayOffset, to: task.dueDate) else { continue }
            
            var components = cal.dateComponents([.year, .month, .day], from: notifDate)
            components.hour = 8
            components.minute = 0
            
            guard var triggerDate = cal.date(from: components) else { continue }
            
            if triggerDate <= Date() {
                if cal.isDateInToday(triggerDate) {
                    triggerDate = Date().addingTimeInterval(5)
                } else {
                    continue
                }
            }
            
            let content = UNMutableNotificationContent()
            if dayOffset == 0 {
                content.title = String(localized: "Oggi scade: \(task.title)")
            } else if dayOffset == 1 {
                content.title = String(localized: "Manca 1 giorno a: \(task.title)")
            } else {
                content.title = String(localized: "Mancano \(dayOffset) giorni a: \(task.title)")
            }
            if let detail = task.detail, !detail.isEmpty {
                content.body = detail
            }
            content.sound = .default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            
            let triggerComponents = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "\(baseId)-\(dayOffset)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("❌ [NotifManager] Failed to add task notification: \(error.localizedDescription)")
                }
            }
        }
    }

    func removeTaskNotification(for task: StudyTask) {
        let baseId = task.id.uuidString
        let idsToRemove = (0...14).map { "\(baseId)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
