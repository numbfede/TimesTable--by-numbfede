import SwiftUI
import SwiftData
struct TaskListView: View {
#if os(iOS)
    @Binding var currentTab: iOSTab
#endif

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.dueDate) private var tasks: [StudyTask]
    @AppStorage("averageType") private var averageTypeRaw = AverageType.arithmetic.rawValue
    @AppStorage("gradeRangeMax") private var gradeRangeMax = 10
    @State private var showingAddTask = false

    // Grade input state
    @State private var taskToGrade: StudyTask?
    @State private var gradeInput = ""
    @State private var weightInput = ""
    @State private var showingGradeAlert = false
    @State private var currentMaxWeight: Double = 100.0

    private var averageType: AverageType {
        AverageType(rawValue: averageTypeRaw) ?? .arithmetic
    }

    // Separated views to prevent list re-calculation on typing
    private var pendingTasks: [StudyTask] { tasks.filter { !$0.isCompleted } }
    private var completedTasks: [StudyTask] { tasks.filter { $0.isCompleted } }


    var body: some View {
        Group {
            if tasks.isEmpty {
                emptyState
            } else {
                TaskListViewContent(
                    pendingTasks: pendingTasks,
                    completedTasks: completedTasks,
                    completeTask: completeTask
                )
            }
        }
        .themeBackground()
        .navigationTitle("Tasks")
#if os(iOS)
        .globalHamburgerMenu(currentTab: $currentTab)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddTask.toggle() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
#else
            ToolbarItem {
                Button { showingAddTask.toggle() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
#endif
        }
        .sheet(isPresented: $showingAddTask) {
            AddEditTaskView()
        }
        .alert("Add Grade", isPresented: $showingGradeAlert) {
            TextField("Grade (e.g. 8.5)", text: $gradeInput)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
            if averageType.needsWeight {
                TextField("Weight % (max \(Int(currentMaxWeight.rounded())))", text: $weightInput)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            Button("Save") {
                if let task = taskToGrade {
                    if let grade = Double(gradeInput.replacingOccurrences(of: ",", with: ".")) {
                        let clamped = min(max(grade, 1.0), Double(gradeRangeMax))
                        task.grade = clamped
                    }
                    if averageType.needsWeight,
                       let weight = Double(weightInput.replacingOccurrences(of: ",", with: ".")) {
                        task.gradeWeight = min(max(weight, 0.0), currentMaxWeight)
                    }
                    task.isCompleted = true
                }
                gradeInput = ""
                weightInput = ""
                taskToGrade = nil
            }
            Button("Skip") {
                taskToGrade?.isCompleted = true
                gradeInput = ""
                weightInput = ""
                taskToGrade = nil
            }
            Button("Cancel", role: .cancel) {
                gradeInput = ""
                weightInput = ""
                taskToGrade = nil
            }
        } message: {
            if averageType.needsWeight {
                Text("Enter the grade and its weight (percentage) for this task.")
            } else {
                Text("Would you like to record a grade for this task?")
            }
        }
    }

    // MARK: - Complete with grade prompt

    private func completeTask(_ task: StudyTask) {
        if task.isCompleted {
            // Uncompleting — just toggle
            withAnimation(AppTheme.bouncy) { task.isCompleted = false }
            task.grade = nil
            task.gradeWeight = nil
        } else {
            // Show grade input alert
            taskToGrade = task
            gradeInput = ""
            weightInput = ""
            
            // Compute max weight once
            let otherTasks = tasks.filter { $0.id != task.id && $0.subjectName == task.subjectName && $0.isCompleted && $0.gradeWeight != nil }
            let currentSum = otherTasks.compactMap { $0.gradeWeight }.reduce(0, +)
            currentMaxWeight = max(0.0, 100.0 - currentSum)
            
            showingGradeAlert = true
#if os(iOS)
            Haptic.success()
#endif
        }
    }

    // (Moved to TaskListViewContent)

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#FF9F0A") ?? .orange, Color(hex: "#FF453A") ?? .red],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .pulsating()

            GradientText("No Tasks", font: .title2.bold(),
                         colors: [Color(hex: "#FF9F0A") ?? .orange, Color(hex: "#FF453A") ?? .red])

            Text("Add assignments and homework here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extracted Task List Content (Prevents re-renders on keystrokes)

struct TaskListViewContent: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("useBottomTabBar") private var useBottomTabBar = true
    
    let pendingTasks: [StudyTask]
    let completedTasks: [StudyTask]
    let completeTask: (StudyTask) -> Void
    
    @State private var editingTask: StudyTask?
    
    var body: some View {
        List {
            if !pendingTasks.isEmpty {
                Section {
                    ForEach(pendingTasks) { task in
                        TaskRow(task: task, onToggle: { completeTask(task) }, onEdit: { editingTask = task })
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation(AppTheme.smooth) {
                                        modelContext.delete(task)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    completeTask(task)
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Label("To Do", systemImage: "circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
            }

            if !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in
                        TaskRow(task: task, onToggle: { completeTask(task) }, onEdit: { editingTask = task })
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation(AppTheme.smooth) {
                                        modelContext.delete(task)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    completeTask(task)
                                } label: {
                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.orange)
                            }
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
#if os(iOS)
        .safeAreaPadding(.bottom, useBottomTabBar ? 80 : 0)
#endif
        .sheet(item: $editingTask) { task in
            AddEditTaskView(editingTask: task)
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @Bindable var task: StudyTask
    @AppStorage("gradeRangeMax") private var gradeRangeMax = 10
    @Environment(ThemeManager.self) private var themeManager
    var onToggle: () -> Void
    var onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : task.color)
                    .font(.title3)
                    .scaleEffect(task.isCompleted ? 1.15 : 1.0)
                    .animation(AppTheme.bouncy, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            Button {
                onEdit()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)

                        if let detail = task.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(task.dueDate, style: .date)
                            if !task.subjectName.isEmpty {
                                Text("·")
                                Image(systemName: "book.fill")
                                    .font(.caption2)
                                Text(task.subjectName)
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let grade = task.grade {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", grade))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(gradeColor(grade))
                                if let weight = task.gradeWeight {
                                    Text("(\(Int(weight))%)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(task.color.opacity(0.6))
                            .frame(width: 4, height: 32)
                    }
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.themeMode == .custom ? themeManager.customButtonColor : task.color.opacity(task.isCompleted ? 0.02 : 0.05))
        )
    }

    private func gradeColor(_ grade: Double) -> Color {
        let good = Double(gradeRangeMax) * 0.7
        let pass = Double(gradeRangeMax) * 0.6
        if grade >= good { return .green }
        if grade >= pass { return .orange }
        return .red
    }
}

// MARK: - Add/Edit Task View

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ClassPreset.name) private var presets: [ClassPreset]

    var linkedClass: SchoolClass? = nil
    var editingTask: StudyTask? = nil

    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    @State private var selectedColor = "#FF453A"
    @State private var customColor: Color = Color(hex: "#FF453A") ?? .red
    @State private var selectedSubject: String = ""

    private var taskColor: Color { Color(hex: selectedColor) ?? .red }
    private var canSave: Bool { !title.isEmpty && !selectedSubject.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Subject Picker (mandatory)
                    taskFormSection(title: String(localized: "Subject"), icon: "book.circle.fill", iconColors: [.indigo, .purple]) {
                        if presets.isEmpty {
                            Text("Create a class first to add subjects.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(presets) { preset in
                                        Button {
                                            withAnimation(AppTheme.smooth) {
                                                selectedSubject = preset.name
                                                selectedColor = preset.hexColor
                                                customColor = preset.color
                                            }
#if os(iOS)
                                            Haptic.selection()
#endif
                                        } label: {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(preset.color)
                                                    .frame(width: 8, height: 8)
                                                Text(preset.name)
                                                    .font(.subheadline.bold())
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedSubject == preset.name
                                                    ? AnyShapeStyle(preset.color.opacity(0.15))
                                                    : AnyShapeStyle(Color.secondary.opacity(0.08))
                                            )
                                            .foregroundStyle(selectedSubject == preset.name ? preset.color : .primary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(selectedSubject == preset.name ? preset.color.opacity(0.3) : .clear, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Task Details
                    taskFormSection(title: String(localized: "Task Details"), icon: "pencil.circle.fill", iconColors: [.blue, .cyan]) {
                        HStack(spacing: 10) {
                            Image(systemName: "textformat")
                                .foregroundStyle(taskColor)
                                .frame(width: 22)
                            TextField("Task Title", text: $title)
                                .textFieldStyle(.plain)
                                .font(.headline)
                        }
                        Divider().padding(.leading, 36)
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                                .frame(width: 22)
                                .padding(.top, 4)
                            TextField("Notes (optional)", text: $detail, axis: .vertical)
                                .lineLimit(3...5)
                                .textFieldStyle(.plain)
                        }
                    }

                    // MARK: Linked Class (when opened from ClassDetailView)
                    if let cls = linkedClass {
                        taskFormSection(title: String(localized: "Linked Class"), icon: "link.circle.fill", iconColors: [.green, .mint]) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(cls.color)
                                    .frame(width: 12, height: 12)
                                Text(cls.name)
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    // MARK: Due Date
                    taskFormSection(title: String(localized: "Due Date"), icon: "calendar.circle.fill", iconColors: [.orange, .yellow]) {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.graphical)
                    }

                    // MARK: Color
                    taskFormSection(title: String(localized: "Color"), icon: "paintpalette.fill", iconColors: [.purple, .pink]) {
                        VStack(spacing: 16) {
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
                    
                    // MARK: Delete Task Button
                    if let taskToDelete = editingTask {
                        Button(role: .destructive) {
                            withAnimation(AppTheme.smooth) {
                                modelContext.delete(taskToDelete)
                                dismiss()
                            }
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red.opacity(0.1))
                        )
                        .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(nsOrUIColor: .secondarySystemBackground))
            .navigationTitle(editingTask != nil ? "Edit Task" : "New Task")
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                canSave
                                    ? taskColor
                                    : Color.secondary.opacity(0.3),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let task = editingTask {
                    title = task.title
                    detail = task.detail ?? ""
                    dueDate = task.dueDate
                    selectedColor = task.hexColor
                    customColor = task.color
                    selectedSubject = task.subjectName
                } else if let cls = linkedClass {
                    // Pre-select subject if no editing task but created from a specific class
                    selectedSubject = cls.name
                    selectedColor = cls.hexColor
                    customColor = cls.color
                }
            }
        }
    }

    // MARK: - Form Section Helper

    private func taskFormSection<Content: View>(
        title: String,
        icon: String,
        iconColors: [Color],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

    private func save() {
        if let task = editingTask {
            task.title = title
            task.detail = detail.isEmpty ? nil : detail
            task.dueDate = dueDate
            task.hexColor = selectedColor
            task.linkedClass = linkedClass ?? task.linkedClass
            task.subjectName = selectedSubject
        } else {
            let task = StudyTask(
                title: title,
                detail: detail.isEmpty ? nil : detail,
                dueDate: dueDate,
                hexColor: selectedColor,
                linkedClass: linkedClass,
                subjectName: selectedSubject
            )
            modelContext.insert(task)
        }
        dismiss()
    }
}
