import Foundation
import SwiftData

// MARK: - Codable DTOs

struct ClassExport: Codable {
    var id: String
    var name: String
    var room: String?
    var teacher: String?
    var notes: String?
    var dayOfWeek: Int
    var weekIndex: Int
    var startTime: Date
    var endTime: Date
    var hexColor: String
}

struct TaskExport: Codable {
    var id: String
    var title: String
    var detail: String?
    var dueDate: Date
    var isCompleted: Bool
    var hexColor: String
    var linkedClassID: String?
}

struct TimetableExport: Codable {
    var exportDate: Date
    var classes: [ClassExport]
    var tasks: [TaskExport]
}

// MARK: - Manager

final class ExportManager {
    static let shared = ExportManager()
    private init() {}

    func exportToURL(classes: [SchoolClass], tasks: [StudyTask]) throws -> URL {
        let classExports = classes.map { c in
            ClassExport(
                id: c.id.uuidString,
                name: c.name,
                room: c.room,
                teacher: c.teacher,
                notes: c.notes,
                dayOfWeek: c.dayOfWeek,
                weekIndex: c.weekIndex,
                startTime: c.startTime,
                endTime: c.endTime,
                hexColor: c.hexColor
            )
        }
        let taskExports = tasks.map { t in
            TaskExport(
                id: t.id.uuidString,
                title: t.title,
                detail: t.detail,
                dueDate: t.dueDate,
                isCompleted: t.isCompleted,
                hexColor: t.hexColor,
                linkedClassID: t.linkedClass?.id.uuidString
            )
        }
        let bundle = TimetableExport(exportDate: Date(), classes: classExports, tasks: taskExports)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(bundle)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimesTable_Export_\(Date().timeIntervalSince1970).json")
        try data.write(to: url)
        return url
    }

    func importFrom(url: URL, context: ModelContext) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "ExportManager", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Permission denied to access the file.")])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(TimetableExport.self, from: data)

        var classMap: [String: SchoolClass] = [:]
        for c in bundle.classes {
            let sc = SchoolClass(
                name: c.name,
                room: c.room,
                teacher: c.teacher,
                notes: c.notes,
                dayOfWeek: c.dayOfWeek,
                weekIndex: c.weekIndex,
                startTime: c.startTime,
                endTime: c.endTime,
                hexColor: c.hexColor
            )
            context.insert(sc)
            classMap[c.id] = sc
        }
        for t in bundle.tasks {
            let task = StudyTask(
                title: t.title,
                detail: t.detail,
                dueDate: t.dueDate,
                isCompleted: t.isCompleted,
                hexColor: t.hexColor,
                linkedClass: t.linkedClassID.flatMap { classMap[$0] }
            )
            context.insert(task)
        }
    }
}
