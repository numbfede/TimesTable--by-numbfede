import Foundation
import SwiftData
import SwiftUI

// MARK: - Average Calculation Types

enum AverageType: String, CaseIterable, Identifiable {
    case arithmetic       = "arithmetic"
    case weighted         = "weighted"          // Weighted average
    case geometric        = "geometric"
    case harmonic         = "harmonic"
    case quadratic        = "quadratic"        // RMS
    case median           = "median"
    case mode             = "mode"
    case trimmed          = "trimmed"           // Exclude min & max
    case midrange         = "midrange"          // (min + max) / 2
    case cubic            = "cubic"
    case contraharmonic   = "contraharmonic"    // Σx² / Σx

    var id: String { rawValue }

    /// Whether this type requires a weight for each grade
    var needsWeight: Bool { self == .weighted }

    var displayName: String {
        switch self {
        case .arithmetic:     return String(localized: "Arithmetic Mean")
        case .weighted:       return String(localized: "Weighted Mean")
        case .geometric:      return String(localized: "Geometric Mean")
        case .harmonic:       return String(localized: "Harmonic Mean")
        case .quadratic:      return String(localized: "Quadratic Mean (RMS)")
        case .median:         return String(localized: "Median")
        case .mode:           return String(localized: "Mode")
        case .trimmed:        return String(localized: "Trimmed Mean")
        case .midrange:       return String(localized: "Midrange")
        case .cubic:          return String(localized: "Cubic Mean")
        case .contraharmonic: return String(localized: "Contraharmonic Mean")
        }
    }

    /// Compute weighted average from (value, weight) pairs
    func computeWeighted(_ pairs: [(value: Double, weight: Double)]) -> Double {
        guard !pairs.isEmpty else { return 0 }
        let totalWeight = pairs.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return compute(pairs.map(\.value)) }
        return pairs.reduce(0.0) { $0 + $1.value * $1.weight } / totalWeight
    }

    func compute(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let n = Double(values.count)

        switch self {
        case .arithmetic, .weighted:
            return values.reduce(0, +) / n

        case .geometric:
            let product = values.reduce(1.0, *)
            return pow(product, 1.0 / n)

        case .harmonic:
            let sumReciprocals = values.reduce(0.0) { $0 + 1.0 / $1 }
            guard sumReciprocals != 0 else { return 0 }
            return n / sumReciprocals

        case .quadratic:
            let sumSquares = values.reduce(0.0) { $0 + $1 * $1 }
            return sqrt(sumSquares / n)

        case .median:
            let sorted = values.sorted()
            let mid = sorted.count / 2
            if sorted.count % 2 == 0 {
                return (sorted[mid - 1] + sorted[mid]) / 2.0
            }
            return sorted[mid]

        case .mode:
            var freq: [Double: Int] = [:]
            let rounded = values.map { (Double(Int($0 * 10))) / 10.0 }
            for v in rounded { freq[v, default: 0] += 1 }
            let maxFreq = freq.values.max() ?? 0
            let modes = freq.filter { $0.value == maxFreq }.map(\.key)
            return modes.reduce(0, +) / Double(modes.count)

        case .trimmed:
            guard values.count > 2 else { return values.reduce(0, +) / n }
            let sorted = values.sorted()
            let trimmed = Array(sorted.dropFirst().dropLast())
            return trimmed.reduce(0, +) / Double(trimmed.count)

        case .midrange:
            guard let min = values.min(), let max = values.max() else { return 0 }
            return (min + max) / 2.0

        case .cubic:
            let sumCubes = values.reduce(0.0) { $0 + $1 * $1 * $1 }
            return cbrt(sumCubes / n)

        case .contraharmonic:
            let sumSquares = values.reduce(0.0) { $0 + $1 * $1 }
            let sum = values.reduce(0, +)
            guard sum != 0 else { return 0 }
            return sumSquares / sum
        }
    }
}

// MARK: - SchoolClass

@Model
final class SchoolClass {
    var id: UUID
    var name: String
    var room: String?
    var teacher: String?
    var notes: String?
    var dayOfWeek: Int        // 1=Mon … 7=Sun
    var weekIndex: Int        // 1–4 (for multi-week schedules)
    var startTime: Date
    var endTime: Date
    var hexColor: String
    var attachmentPaths: [String]  // file paths stored locally

    @Relationship(deleteRule: .cascade)
    var tasks: [StudyTask]

    init(
        name: String,
        room: String? = nil,
        teacher: String? = nil,
        notes: String? = nil,
        dayOfWeek: Int,
        weekIndex: Int = 1,
        startTime: Date,
        endTime: Date,
        hexColor: String = "#3498db",
        attachmentPaths: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.room = room
        self.teacher = teacher
        self.notes = notes
        self.dayOfWeek = dayOfWeek
        self.weekIndex = weekIndex
        self.startTime = startTime
        self.endTime = endTime
        self.hexColor = hexColor
        self.attachmentPaths = attachmentPaths
        self.tasks = []
    }

    var color: Color {
        Color(hex: hexColor) ?? .blue
    }

    var gradient: LinearGradient {
        AppTheme.cardGradient(for: color)
    }
}

// MARK: - ClassPreset

@Model
final class ClassPreset {
    var id: UUID
    var name: String
    var room: String?
    var teacher: String?
    var hexColor: String

    init(name: String, room: String? = nil, teacher: String? = nil, hexColor: String = "#0A84FF") {
        self.id = UUID()
        self.name = name
        self.room = room
        self.teacher = teacher
        self.hexColor = hexColor
    }

    var color: Color {
        Color(hex: hexColor) ?? .blue
    }
}

// MARK: - StudyTask

@Model
final class StudyTask {
    var id: UUID
    var title: String
    var detail: String?
    var dueDate: Date
    var isCompleted: Bool
    var hexColor: String
    var grade: Double?          // optional grade when completed
    var gradeWeight: Double?    // optional weight (%) for weighted average
    var subjectName: String     // linked subject (preset name)

    @Relationship(inverse: \SchoolClass.tasks)
    var linkedClass: SchoolClass?

    init(
        title: String,
        detail: String? = nil,
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        hexColor: String = "#e74c3c",
        linkedClass: SchoolClass? = nil,
        grade: Double? = nil,
        gradeWeight: Double? = nil,
        subjectName: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.hexColor = hexColor
        self.linkedClass = linkedClass
        self.grade = grade
        self.gradeWeight = gradeWeight
        self.subjectName = subjectName
    }

    var color: Color {
        Color(hex: hexColor) ?? .red
    }
}

// MARK: - Color Hex Extension

extension Color {
    /// Convert a Color back to a hex string (#RRGGBB)
    func toHex() -> String {
#if os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
    }

    init?(hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        switch h.count {
        case 6:
            self.init(
                red:   Double((rgb & 0xFF0000) >> 16) / 255,
                green: Double((rgb & 0x00FF00) >> 8)  / 255,
                blue:  Double( rgb & 0x0000FF)         / 255
            )
        case 8:
            self.init(
                red:   Double((rgb & 0xFF000000) >> 24) / 255,
                green: Double((rgb & 0x00FF0000) >> 16) / 255,
                blue:  Double((rgb & 0x0000FF00) >> 8)  / 255,
                opacity: Double(rgb & 0x000000FF)        / 255
            )
        default:
            return nil
        }
    }
}
