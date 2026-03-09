import SwiftUI
import SwiftData

struct AddEditClassView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClassPreset.name) private var presets: [ClassPreset]
    @Query private var allClasses: [SchoolClass]

    var existingClass: SchoolClass?
    var defaultWeekIndex: Int = 1

    @State private var name = ""
    @State private var room = ""
    @State private var teacher = ""
    @State private var notes = ""
    @State private var dayOfWeek = 1
    @State private var weekIndex = 1
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var selectedColor = "#0A84FF"
    @State private var customColor: Color = Color(hex: "#0A84FF") ?? .blue

    @AppStorage("numberOfWeeks") private var numberOfWeeks = 1
    @AppStorage("repeatingWeeksEnabled") private var repeatingWeeksEnabled = false
    @AppStorage("defaultClassDuration") private var defaultClassDuration = 60
    @AppStorage("defaultStartTime") private var defaultStartTime = 480

    private var isEditing: Bool { existingClass != nil }

    private var previewColor: Color { Color(hex: selectedColor) ?? .blue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Live Preview (top)
                    previewCard
                        .padding(.top, 8)

                    // MARK: Preset Picker (only for new classes)
                    if !isEditing && !presets.isEmpty {
                        formSection(title: String(localized: "Use Preset"), icon: "rectangle.stack.fill", iconColors: [.indigo, .purple]) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(presets) { preset in
                                        Button {
                                            withAnimation(AppTheme.smooth) {
                                                name = preset.name
                                                room = preset.room ?? ""
                                                teacher = preset.teacher ?? ""
                                                selectedColor = preset.hexColor
                                                customColor = preset.color
                                            }
#if os(iOS)
                                            Haptic.selection()
#endif
                                        } label: {
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(preset.color)
                                                    .frame(width: 10, height: 10)
                                                Text(preset.name)
                                                    .font(.subheadline.bold())
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                name == preset.name
                                                    ? AnyShapeStyle(preset.color.opacity(0.15))
                                                    : AnyShapeStyle(Color.secondary.opacity(0.08))
                                            )
                                            .foregroundStyle(name == preset.name ? preset.color : .primary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(name == preset.name ? preset.color.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Basic Info
                    formSection(title: "Basic Info", icon: "info.circle.fill", iconColors: [.blue, .cyan]) {
                        formField(icon: "textformat", placeholder: "Class Name", text: $name, isRequired: true)
                        Divider().padding(.leading, 36)
                        formField(icon: "mappin.circle", placeholder: "Room (optional)", text: $room)
                        Divider().padding(.leading, 36)
                        formField(icon: "person.circle", placeholder: "Teacher (optional)", text: $teacher)
                        Divider().padding(.leading, 36)
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                                .frame(width: 22)
                                .padding(.top, 4)
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.plain)
                        }
                    }

                    // MARK: Schedule
                    formSection(title: String(localized: "Schedule"), icon: "clock.fill", iconColors: [.orange, .yellow]) {
                        HStack {
                            Label("Day", systemImage: "calendar")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $dayOfWeek) {
                                ForEach(1...7, id: \.self) { tag in
                                    Text(Calendar.current.weekdaySymbols[tag % 7]).tag(tag)
                                }
                            }
                            .labelsHidden()
#if os(iOS)
                            .pickerStyle(.menu)
#endif
                        }

                        if numberOfWeeks > 1 {
                            Divider()
                            HStack {
                                Label("Week", systemImage: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $weekIndex) {
                                    ForEach(1...numberOfWeeks, id: \.self) { w in
                                        Text("Week \(w)").tag(w)
                                    }
                                }
                                .labelsHidden()
#if os(iOS)
                                .pickerStyle(.menu)
#endif
                            }
                        }

                        Divider()

                        HStack(spacing: 20) {
                            // Start time
                            VStack(alignment: .leading, spacing: 6) {
                                Text("START")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Divider
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 18)

                            // End time
                            VStack(alignment: .leading, spacing: 6) {
                                Text("END")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // MARK: Color
                    formSection(title: "Color", icon: "paintpalette.fill", iconColors: [.purple, .pink]) {
                        colorPicker
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(nsOrUIColor: .secondarySystemBackground))
            .navigationTitle(isEditing ? "Edit Class" : "New Class")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
#if os(iOS)
                        Haptic.success()
#endif
                    } label: {
                        Text("Save")
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .foregroundStyle(.white)
                            .background(
                                name.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.secondary.opacity(0.3)
                                    : previewColor,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { prefill() }
        }
    }

    // MARK: - Form Section

    private func formSection<Content: View>(
        title: String,
        icon: String,
        iconColors: [Color],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Label {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.leading, 4)

            // Card
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsOrUIColor: .tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Form Field

    private func formField(icon: String, placeholder: String, text: Binding<String>, isRequired: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(isRequired ? previewColor : .secondary)
                .frame(width: 22)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(isRequired ? .headline : .body)
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(spacing: 16) {
            // Preset grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AppTheme.palette, id: \.hex) { hex, colorName in
                    let color = Color(hex: hex) ?? .gray
                    let isSelected = selectedColor == hex
                    Button {
                        withAnimation(AppTheme.bouncy) {
                            selectedColor = hex
                            customColor = color
                        }
#if os(iOS)
                        Haptic.selection()
#endif
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.65)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)

                            if isSelected {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2.5)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 6, y: 2)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(AppTheme.bouncy, value: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(colorName)
                }
            }
            .padding(.vertical, 4)

            Divider()

            // Custom color picker
            HStack {
                ColorPicker(selection: $customColor, supportsOpacity: false) {
                    Label("Custom Color", systemImage: "eyedropper")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .onChange(of: customColor) { _, newColor in
                    withAnimation(AppTheme.bouncy) {
                        selectedColor = newColor.toHex()
                    }
                }
            }
        }
    }

    // MARK: - Live Preview

    private var previewCard: some View {
        HStack(spacing: 0) {
            // Gradient accent strip
            RoundedRectangle(cornerRadius: 3)
                .fill(AppTheme.stripGradient(for: previewColor))
                .frame(width: 5)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(name.isEmpty ? "Class Name" : name)
                        .font(.headline)
                        .foregroundStyle(name.isEmpty ? .tertiary : .primary)

                    HStack(spacing: 10) {
                        if !room.isEmpty {
                            Label(room, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !teacher.isEmpty {
                            Label(teacher, systemImage: "person.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if room.isEmpty && teacher.isEmpty {
                            Text("Fill in the details below")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.leading, 12)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(startTime, style: .time)
                        .font(.subheadline.bold().monospacedDigit())
                    Text(endTime, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(previewColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .strokeBorder(previewColor.opacity(0.15), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: previewColor.opacity(0.12), radius: 8, y: 4)
        .animation(AppTheme.smooth, value: selectedColor)
        .animation(AppTheme.smooth, value: name)
    }

    // MARK: - Prefill / Save

    private func prefill() {
        guard let c = existingClass else {
            weekIndex = defaultWeekIndex
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = defaultStartTime / 60
            components.minute = defaultStartTime % 60
            if let newStart = calendar.date(from: components) {
                startTime = newStart
                endTime = newStart.addingTimeInterval(Double(defaultClassDuration * 60))
            }
            return
        }
        name = c.name
        room = c.room ?? ""
        teacher = c.teacher ?? ""
        notes = c.notes ?? ""
        dayOfWeek = c.dayOfWeek
        weekIndex = c.weekIndex
        startTime = c.startTime
        endTime = c.endTime
        selectedColor = c.hexColor
    }

    private func save() {
        if let c = existingClass {
            c.name = name.trimmingCharacters(in: .whitespaces)
            c.room = room.isEmpty ? nil : room
            c.teacher = teacher.isEmpty ? nil : teacher
            c.notes = notes.isEmpty ? nil : notes
            c.dayOfWeek = dayOfWeek
            c.weekIndex = weekIndex
            c.startTime = startTime
            c.endTime = endTime
            c.hexColor = selectedColor
        } else {
            let newClass = SchoolClass(
                name: name.trimmingCharacters(in: .whitespaces),
                room: room.isEmpty ? nil : room,
                teacher: teacher.isEmpty ? nil : teacher,
                notes: notes.isEmpty ? nil : notes,
                dayOfWeek: dayOfWeek,
                weekIndex: weekIndex,
                startTime: startTime,
                endTime: endTime,
                hexColor: selectedColor
            )
            modelContext.insert(newClass)
        }
        // Save or update preset
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            if let existing = presets.first(where: { $0.name == trimmedName }) {
                existing.room = room.isEmpty ? nil : room
                existing.teacher = teacher.isEmpty ? nil : teacher
                existing.hexColor = selectedColor
            } else {
                let preset = ClassPreset(
                    name: trimmedName,
                    room: room.isEmpty ? nil : room,
                    teacher: teacher.isEmpty ? nil : teacher,
                    hexColor: selectedColor
                )
                modelContext.insert(preset)
            }
        }

        // Reschedule notifications to include this class
        NotificationManager.shared.rescheduleAll(classes: allClasses, tasks: [])

        dismiss()
    }
}

// MARK: - Cross-platform system color helper

extension Color {
    init(nsOrUIColor name: SystemColorName) {
        switch name {
        case .secondarySystemBackground:
#if os(iOS)
            self = Color(UIColor.secondarySystemBackground)
#else
            self = Color(NSColor.controlBackgroundColor)
#endif
        case .tertiarySystemBackground:
#if os(iOS)
            self = Color(UIColor.tertiarySystemBackground)
#else
            self = Color(NSColor.textBackgroundColor)
#endif
        }
    }

    enum SystemColorName {
        case secondarySystemBackground
        case tertiarySystemBackground
    }
}

