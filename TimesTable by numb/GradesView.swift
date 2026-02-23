import SwiftUI
import SwiftData

struct GradesView: View {
    @Query(sort: \ClassPreset.name) private var presets: [ClassPreset]
    @Query private var tasks: [StudyTask]
    @AppStorage("averageType") private var averageTypeRaw = AverageType.arithmetic.rawValue
    @AppStorage("gradeRangeMax") private var gradeRangeMax = 10

    // Edit grade state
    @State private var taskToEdit: StudyTask?
    @State private var editGradeInput = ""
    @State private var editWeightInput = ""
    @State private var showingEditAlert = false

    private var averageType: AverageType {
        AverageType(rawValue: averageTypeRaw) ?? .arithmetic
    }

    private var gradedTasks: [StudyTask] {
        tasks.filter { $0.isCompleted && $0.grade != nil }
    }

    private var subjects: [(preset: ClassPreset, grades: [StudyTask], average: Double)] {
        presets.compactMap { preset in
            let subjectGrades = gradedTasks.filter { $0.subjectName == preset.name }
            guard !subjectGrades.isEmpty else { return nil }
            let avg: Double
            if averageType.needsWeight {
                let pairs = subjectGrades.compactMap { task -> (value: Double, weight: Double)? in
                    guard let g = task.grade else { return nil }
                    return (value: g, weight: task.gradeWeight ?? 1.0)
                }
                avg = averageType.computeWeighted(pairs)
            } else {
                avg = averageType.compute(subjectGrades.compactMap(\.grade))
            }
            return (preset: preset, grades: subjectGrades, average: avg)
        }
    }

    private var overallAverage: Double? {
        let graded = gradedTasks
        guard !graded.isEmpty else { return nil }
        if averageType.needsWeight {
            let pairs = graded.compactMap { task -> (value: Double, weight: Double)? in
                guard let g = task.grade else { return nil }
                return (value: g, weight: task.gradeWeight ?? 1.0)
            }
            return averageType.computeWeighted(pairs)
        } else {
            return averageType.compute(graded.compactMap(\.grade))
        }
    }

    private var maxAllowedWeight: Double {
        guard let task = taskToEdit else { return 100.0 }
        let otherTasks = tasks.filter { $0.id != task.id && $0.subjectName == task.subjectName && $0.isCompleted && $0.gradeWeight != nil }
        let currentSum = otherTasks.compactMap { $0.gradeWeight }.reduce(0, +)
        return max(0.0, 100.0 - currentSum)
    }

    var body: some View {
        Group {
            if subjects.isEmpty {
                emptyState
            } else {
                gradesList
            }
        }
        .navigationTitle("Grades")
        .alert("Edit Grade", isPresented: $showingEditAlert) {
            TextField("Grade (e.g. 8.5)", text: $editGradeInput)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
            if averageType.needsWeight {
                TextField("Weight % (max \(Int(maxAllowedWeight.rounded())))", text: $editWeightInput)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            Button("Save") {
                if let task = taskToEdit,
                   let grade = Double(editGradeInput.replacingOccurrences(of: ",", with: ".")) {
                    task.grade = min(max(grade, 1.0), Double(gradeRangeMax))
                    if averageType.needsWeight,
                       let weight = Double(editWeightInput.replacingOccurrences(of: ",", with: ".")) {
                        task.gradeWeight = min(max(weight, 0.0), maxAllowedWeight)
                    }
                }
                editGradeInput = ""
                editWeightInput = ""
                taskToEdit = nil
            }
            Button("Remove Grade", role: .destructive) {
                taskToEdit?.grade = nil
                taskToEdit?.gradeWeight = nil
                editGradeInput = ""
                editWeightInput = ""
                taskToEdit = nil
            }
            Button("Cancel", role: .cancel) {
                editGradeInput = ""
                editWeightInput = ""
                taskToEdit = nil
            }
        } message: {
            if let task = taskToEdit {
                Text("Edit the grade for \"\(task.title)\"")
            }
        }
    }

    // MARK: - Edit grade action

    private func editGrade(for task: StudyTask) {
        taskToEdit = task
        editGradeInput = task.grade.map { String(format: "%.1f", $0) } ?? ""
        editWeightInput = task.gradeWeight.map { String(format: "%.0f", $0) } ?? ""
        showingEditAlert = true
    }

    // MARK: - Grades List

    private var gradesList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall average card
                if let avg = overallAverage {
                    overallAverageCard(avg)
                        .padding(.top, 8)
                }

                // Per-subject cards
                ForEach(subjects, id: \.preset.id) { subject in
                    subjectCard(subject)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .themeBackground()
    }

    // MARK: - Overall Average

    private func overallAverageCard(_ average: Double) -> some View {
        VStack(spacing: 8) {
            Text("Overall Average")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", average))
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(
                    LinearGradient(
                        colors: gradeGradient(average),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(averageType.displayName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsOrUIColor: .tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Subject Card

    private func subjectCard(_ subject: (preset: ClassPreset, grades: [StudyTask], average: Double)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(subject.preset.color)
                    .frame(width: 12, height: 12)
                Text(subject.preset.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", subject.average))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(gradeColor(subject.average))
            }

            Divider()

            // Individual grades
            ForEach(subject.grades) { task in
                Button {
                    editGrade(for: task)
                } label: {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        if let weight = task.gradeWeight {
                            Text("\(Int(weight))%")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        if let grade = task.grade {
                            Text(String(format: "%.1f", grade))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(gradeColor(grade))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsOrUIColor: .tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(subject.preset.color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#30D158") ?? .green, Color(hex: "#0A84FF") ?? .blue],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .pulsating()

            GradientText("No Grades", font: .title2.bold(),
                         colors: [Color(hex: "#30D158") ?? .green, Color(hex: "#0A84FF") ?? .blue])

            Text("Complete tasks and add grades to see your averages here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: Double) -> Color {
        let good = Double(gradeRangeMax) * 0.7
        let pass = Double(gradeRangeMax) * 0.6
        if grade >= good { return .green }
        if grade >= pass { return .orange }
        return .red
    }

    private func gradeGradient(_ grade: Double) -> [Color] {
        let good = Double(gradeRangeMax) * 0.7
        let pass = Double(gradeRangeMax) * 0.6
        if grade >= good { return [Color(hex: "#30D158") ?? .green, Color(hex: "#34C759") ?? .green] }
        if grade >= pass { return [Color(hex: "#FF9F0A") ?? .orange, Color(hex: "#FFD60A") ?? .yellow] }
        return [Color(hex: "#FF453A") ?? .red, Color(hex: "#FF6961") ?? .red]
    }
}
