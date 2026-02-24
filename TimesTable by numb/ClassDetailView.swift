import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct ClassDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var schoolClass: SchoolClass

    @State private var showingEditClass = false
    @State private var showingAddTask = false
    @State private var showingFilePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingDeleteConfirm = false
    @State private var editingTask: StudyTask?

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Gradient Header
                headerBanner
                    .padding(.bottom, 8)

                // MARK: Info Chips
                infoChips
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                // MARK: Tasks Section
                sectionCard(title: "Tasks", icon: "checklist") {
                    if schoolClass.tasks.isEmpty {
                        HStack {
                            Text("No tasks yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(schoolClass.tasks.sorted(by: { $0.dueDate < $1.dueDate })) { task in
                            taskRow(task, onEdit: { editingTask = task })
                            if task.id != schoolClass.tasks.sorted(by: { $0.dueDate < $1.dueDate }).last?.id {
                                Divider().padding(.leading, 32)
                            }
                        }
                    }

                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(schoolClass.color)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // MARK: Attachments Section
                sectionCard(title: "Attachments", icon: "paperclip") {
                    if !schoolClass.attachmentPaths.isEmpty {
                        ForEach(schoolClass.attachmentPaths, id: \.self) { path in
                            AttachmentRow(path: path) {
                                withAnimation(AppTheme.smooth) {
                                    schoolClass.attachmentPaths.removeAll { $0 == path }
                                }
                            }
                            if path != schoolClass.attachmentPaths.last {
                                Divider()
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Photo", systemImage: "photo.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(schoolClass.color)
                        }
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("File", systemImage: "doc.badge.plus")
                                .font(.subheadline.bold())
                                .foregroundStyle(schoolClass.color)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // MARK: Delete
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Class")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(schoolClass.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditClass = true
                } label: {
                    Text("Edit")
                        .bold()
                        .foregroundStyle(schoolClass.color)
                }
            }
        }
        .sheet(isPresented: $showingEditClass) {
            AddEditClassView(existingClass: schoolClass)
        }
        .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(linkedClass: schoolClass)
        }
        .sheet(item: $editingTask) { task in
            AddEditTaskView(linkedClass: schoolClass, editingTask: task)
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotos, matching: .images)
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await savePhotos(newItems) }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .data],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls { saveFile(url) }
            }
        }
        .confirmationDialog("Delete this class?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(schoolClass)
                dismiss()
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.headerGradient(for: schoolClass.color))
                .frame(height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: schoolClass.color.opacity(0.3), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(schoolClass.name)
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("\(timeFormatter.string(from: schoolClass.startTime)) – \(timeFormatter.string(from: schoolClass.endTime))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Info Chips

    private var infoChips: some View {
        let items: [(String, String)] = [
            (schoolClass.room ?? "", "mappin.circle.fill"),
            (schoolClass.teacher ?? "", "person.circle.fill"),
            (schoolClass.notes ?? "", "note.text"),
        ].filter { !$0.0.isEmpty }

        return FlowLayout(spacing: 8) {
            ForEach(items, id: \.0) { text, icon in
                Label(text, systemImage: icon)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, 2)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(Color.secondary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Task Row

    private func taskRow(_ task: StudyTask, onEdit: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(AppTheme.bouncy) {
                    task.isCompleted.toggle()
                }
#if os(iOS)
                if task.isCompleted { Haptic.success() }
#endif
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : schoolClass.color)
                    .scaleEffect(task.isCompleted ? 1.15 : 1.0)
                    .animation(AppTheme.bouncy, value: task.isCompleted)
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        Text(task.dueDate, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func savePhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let filename = UUID().uuidString + ".jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            try? data.write(to: url)
            schoolClass.attachmentPaths.append(url.path)
        }
        selectedPhotos = []
    }

    private func saveFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.copyItem(at: url, to: dest)
        schoolClass.attachmentPaths.append(dest.path)
    }
}

// MARK: - Flow Layout (for info chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, width: proposal.width ?? .infinity)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, width: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, width: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Attachment Row

struct AttachmentRow: View {
    let path: String
    let onDelete: () -> Void

    private var url: URL { URL(fileURLWithPath: path) }
    private var isImage: Bool {
        ["jpg", "jpeg", "png", "heic"].contains(url.pathExtension.lowercased())
    }

    var body: some View {
        HStack(spacing: 10) {
#if os(iOS)
            if isImage, let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                fileIcon
            }
#else
            if isImage, let data = try? Data(contentsOf: url),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                fileIcon
            }
#endif
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var fileIcon: some View {
        Image(systemName: "doc.fill")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 40, height: 40)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
