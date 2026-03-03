import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Data Model

struct WidgetClass: Codable, Identifiable {
    var id: String { name + "\(startTime.timeIntervalSince1970)" }
    var name: String
    var room: String?
    var startTime: Date
    var endTime: Date
    var hexColor: String
}

// MARK: - Timeline Entry

struct TimetableEntry: TimelineEntry {
    let date: Date
    let currentClass: WidgetClass?
    let nextClass: WidgetClass?
    let todayClasses: [WidgetClass]
}

// MARK: - Timeline Provider

struct TimetableProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimetableEntry {
        let now = Date()
        let c1 = WidgetClass(name: "Pranzo", room: nil, startTime: now.addingTimeInterval(-3600), endTime: now.addingTimeInterval(-1800), hexColor: "#3498db")
        let c2 = WidgetClass(name: "Pausa breve", room: nil, startTime: now.addingTimeInterval(-1800), endTime: now, hexColor: "#3498db")
        let c3 = WidgetClass(name: "Numerica", room: nil, startTime: now, endTime: now.addingTimeInterval(3600), hexColor: "#e67e22")
        
        return TimetableEntry(
            date: now,
            currentClass: c3,
            nextClass: nil,
            todayClasses: [c1, c2, c3]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
        let entry = fetchEntry()
        
        // We want the widget to update exactly when a class starts or ends
        var updateDates: [Date] = [Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()]
        
        for cls in entry.todayClasses {
            if cls.startTime > Date() { updateDates.append(cls.startTime) }
            if cls.endTime > Date() { updateDates.append(cls.endTime) }
        }
        
        updateDates.sort()
        let nextUpdate = updateDates.first(where: { $0 > Date() }) ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> TimetableEntry {
        let defaults = UserDefaults(suiteName: "group.com.numb.TimesTable")
        guard let data = defaults?.data(forKey: "widgetClasses"),
              let classes = try? JSONDecoder().decode([WidgetClass].self, from: data) else {
            return TimetableEntry(date: Date(), currentClass: nil, nextClass: nil, todayClasses: [])
        }

        let now = Date()
        
        let currentClass = classes.first { now >= $0.startTime && now < $0.endTime }
        let nextClass = classes.first { $0.startTime > now }

        return TimetableEntry(date: now, currentClass: currentClass, nextClass: nextClass, todayClasses: classes)
    }
}

// MARK: - Formatters
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

func formatTimeNoColon(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH mm"
    return formatter.string(from: date)
}

// MARK: - Color Extension for Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Next Class Views

struct NextClassWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimetableEntry

    var body: some View {
        let displayClass = entry.currentClass ?? entry.nextClass
        
        ZStack(alignment: .leading) {
            Color(white: 0.15)
            
            if let cls = displayClass {
                let badgeColor = Color(hex: cls.hexColor) ?? .blue
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(cls.name)
                        .font(.system(size: family == .systemSmall ? 24 : 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)

                    Text("\(formatTime(cls.startTime)) – \(formatTime(cls.endTime))")
                        .font(.system(size: family == .systemSmall ? 16 : 20, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))

                    if family == .systemLarge {
                        if entry.currentClass != nil {
                            Text("In corso")
                                .font(.subheadline.bold())
                                .foregroundColor(badgeColor)
                                .padding(.top, 8)
                        } else {
                            Text("Tra poco")
                                .font(.subheadline.bold())
                                .foregroundColor(badgeColor)
                                .padding(.top, 8)
                        }
                    }

                    Spacer()

                    // Bottom Pill
                    if let next = entry.nextClass, entry.currentClass != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.caption2.bold())
                            Text(next.name)
                                .font(.caption.bold())
                                .lineLimit(1)
                        }
                        // Use the next class color for the "up next" pill
                        .foregroundColor(Color(hex: next.hexColor) ?? .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((Color(hex: next.hexColor) ?? .white).opacity(0.2))
                        .clipShape(Capsule())
                    } else if let room = cls.room, !room.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(room)
                                .font(.caption.bold())
                                .lineLimit(1)
                        }
                        .foregroundColor(badgeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badgeColor.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(16)
            } else {
                VStack(alignment: .leading) {
                    Text("Libero")
                        .font(.system(size: family == .systemSmall ? 24 : 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Nessuna lezione in programma.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Today Schedule Views

struct TodayScheduleWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: TimetableEntry

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Oggi")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)

                if entry.todayClasses.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Nessuna lezione oggi")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                    Spacer()
                } else {
                    let classesToShow = computeVisibleClasses(for: family)
                    
                    VStack(spacing: 4) {
                        ForEach(classesToShow) { cls in
                            let isActive = cls.id == entry.currentClass?.id
                            let classColor = Color(hex: cls.hexColor) ?? .orange
                            
                            HStack(spacing: 12) {
                                Text(formatTimeNoColon(cls.startTime))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Text(cls.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            // If active, use its color. Otherwise use standard dark gray
                            .background(isActive ? classColor : Color(white: 0.2))
                            // If active and color is bright we might want dark text, but white usually looks good
                            .foregroundColor(isActive ? .white : .white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    let remaining = entry.todayClasses.count - classesToShow.count
                    if remaining > 0 {
                        Text("Altre \(remaining)...")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                            .padding(.top, 2)
                    }
                    if family == .systemLarge {
                        Spacer()
                    }
                }
            }
            .padding(14)
        }
    }
    
    private func computeVisibleClasses(for family: WidgetFamily) -> [WidgetClass] {
        let maxDisplay: Int
        switch family {
        case .systemSmall: maxDisplay = 2
        case .systemMedium: maxDisplay = 3
        case .systemLarge: maxDisplay = 6
        default: maxDisplay = 3
        }
        
        let classes = entry.todayClasses
        
        if classes.count <= maxDisplay {
            return classes
        }
        
        guard let current = entry.currentClass, let currentIndex = classes.firstIndex(where: { $0.id == current.id }) else {
            if let next = entry.nextClass, let nextIndex = classes.firstIndex(where: { $0.id == next.id }) {
                let start = max(0, min(nextIndex, classes.count - maxDisplay))
                return Array(classes[start..<start+maxDisplay])
            }
            return Array(classes.prefix(maxDisplay))
        }
        
        let startIndex = max(0, min(currentIndex - 1, classes.count - maxDisplay))
        let endIndex = min(startIndex + maxDisplay, classes.count)
        
        return Array(classes[startIndex..<endIndex])
    }
}

// MARK: - Widget Configurations

struct NextClassWidget: Widget {
    let kind: String = "NextClassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            NextClassWidgetView(entry: entry)
                .containerBackground(Color(white: 0.15), for: .widget)
        }
        .configurationDisplayName("Prossima Lezione")
        .description("Visualizza la tua lezione corrente o successiva.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct TodayScheduleWidget: Widget {
    let kind: String = "TodayScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimetableProvider()) { entry in
            TodayScheduleWidgetView(entry: entry)
                .containerBackground(Color(white: 0.1), for: .widget)
        }
        .configurationDisplayName("Orario di Oggi")
        .description("Visualizza la timeline delle lezioni di oggi.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
