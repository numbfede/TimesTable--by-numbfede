import SwiftUI
import SwiftData
import AppIntents
import UniformTypeIdentifiers
import PhotosUI

// MARK: - Image Source Selection Modifier

struct ImagePickersModifier: ViewModifier {
    let themeManager: ThemeManager
    @Binding var showingImagePickerOptions: Bool
    @Binding var showingImagePicker: Bool
    @Binding var showingFilePicker: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            // Photos App logic
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            themeManager.backgroundImageData = data
                            themeManager.notifyChange()
                        }
                    }
                }
            }
            // Local Files/Finder logic
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    // Try getting the security scoped resource if iOS sandboxed it
                    let startedAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if startedAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    if let data = try? Data(contentsOf: url) {
                        themeManager.backgroundImageData = data
                        themeManager.notifyChange()
                    }
                }
            }
    }
}

struct SettingsView: View {
#if os(iOS)
    @Binding var currentTab: iOSTab
#endif

    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    @Query private var classes: [SchoolClass]
    @Query private var tasks: [StudyTask]
    @Query(sort: \ClassPreset.name) private var presets: [ClassPreset]

    @AppStorage("showWeekends") private var showWeekends = true
    @AppStorage("numberOfWeeks") private var numberOfWeeks = 1
    @AppStorage("repeatingWeeksEnabled") private var repeatingWeeksEnabled = false
    @AppStorage("averageType") private var averageTypeRaw = AverageType.arithmetic.rawValue
    @AppStorage("gradeRangeMax") private var gradeRangeMax = 10
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderOffset") private var reminderOffset = 10
    @AppStorage("iCloudEnabled") private var iCloudEnabled = false
    @AppStorage("defaultClassDuration") private var defaultClassDuration = 60
    @AppStorage("defaultStartTime") private var defaultStartTime = 480
    @AppStorage("useBottomTabBar") private var useBottomTabBar = true

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = true
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = true

    @ObservedObject private var notifManager = NotificationManager.shared

    @State private var showingResetConfirm = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingImportPicker = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var presetToDelete: ClassPreset?
    @State private var showingDeletePreset = false
    
    // Easter Egg Dev Mode
    @State private var devModeTaps = 0
    @State private var showingDevAlert = false
    
    // Custom theme pickers state
    @State private var showingImagePickerOptions = false
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
#if os(macOS)
        macOSSettings
            .modifier(ImagePickersModifier(
                themeManager: themeManager,
                showingImagePickerOptions: $showingImagePickerOptions,
                showingImagePicker: $showingImagePicker,
                showingFilePicker: $showingFilePicker,
                selectedPhotoItem: $selectedPhotoItem
            ))
#else
        iOSSettings
            .modifier(ImagePickersModifier(
                themeManager: themeManager,
                showingImagePickerOptions: $showingImagePickerOptions,
                showingImagePicker: $showingImagePicker,
                showingFilePicker: $showingFilePicker,
                selectedPhotoItem: $selectedPhotoItem
            ))
#endif
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    themeManager.backgroundImageData = data
                    themeManager.notifyChange()
                }
            }
        }
    }
    
    // MARK: - macOS layout
#if os(macOS)
    private var macOSSettings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Appearance
                settingsGroup(title: "Appearance", icon: "paintpalette.fill", iconColors: [.purple, .pink]) {
                    Picker("Theme Mode", selection: Bindable(themeManager).themeMode) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    ColorPicker("Accent Color", selection: Bindable(themeManager).accentColor)
                    
                    if themeManager.themeMode == .custom {
                        Divider()
                        Text("Custom Theme Options").font(.headline)
                        ColorPicker("Background Color", selection: Bindable(themeManager).customBackgroundColor)
                        ColorPicker("Button/Card Color", selection: Bindable(themeManager).customButtonColor)
                        ColorPicker("Icon/Text Color", selection: Bindable(themeManager).customIconColor)
                        
                        Divider()
                        HStack {
                            Text("Background Image")
                            Spacer()
                            if themeManager.hasCustomBackgroundImage {
                                Button("Remove Image") {
                                    themeManager.backgroundImageData = nil
                                    themeManager.notifyChange()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                            Menu("Select Image...") {
                                Button("Photos App") { showingImagePicker = true }
                                Button("Files / Finder") { showingFilePicker = true }
                            }
                            .menuStyle(.borderlessButton)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                settingsGroup(title: String(localized: "Schedule"), icon: "calendar", iconColors: [.blue, .cyan]) {
                    Toggle("Show Weekends", isOn: $showWeekends)
                    Divider()
                    HStack {
                        Text("Default Start Time")
                        Spacer()
                        Picker("", selection: $defaultStartTime) {
                            ForEach(Array(stride(from: 480, through: 690, by: 30)), id: \.self) { mins in
                                Text(timeString(from: mins)).tag(mins)
                            }
                        }
                        .labelsHidden()
                    }
                    Divider()
                    HStack {
                        Text("Default Class Duration")
                        Spacer()
                        Picker("", selection: $defaultClassDuration) {
                            ForEach(Array(stride(from: 30, through: 240, by: 30)), id: \.self) { mins in
                                Text(durationString(from: mins)).tag(mins)
                            }
                        }
                        .labelsHidden()
                    }
                    Divider()
                    Toggle("Repeating Weeks", isOn: $repeatingWeeksEnabled)
                    if repeatingWeeksEnabled {
                        Divider()
                        HStack {
                            Text("Repeat Every")
                            Spacer()
                            Picker("", selection: $numberOfWeeks) {
                                Text("1 \(String(localized: "week"))").tag(1)
                                Text("2 \(String(localized: "weeks"))").tag(2)
                                Text("3 \(String(localized: "weeks"))").tag(3)
                                Text("4 \(String(localized: "weeks"))").tag(4)
                            }
                            .labelsHidden()
                        }
                    } else {
                        Divider()
                        Stepper(value: $numberOfWeeks, in: 1...4) {
                            HStack {
                                Text("Number of Weeks")
                                Spacer()
                                Text("\(numberOfWeeks)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                // MARK: Subjects
                if !presets.isEmpty {
                    settingsGroup(title: String(localized: "Subjects"), icon: "book.fill", iconColors: [.indigo, .purple]) {
                        ForEach(presets) { preset in
                            HStack {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 10, height: 10)
                                Text(preset.name)
                                    .font(.subheadline)
                                if let teacher = preset.teacher, !teacher.isEmpty {
                                    Spacer()
                                    Text(teacher)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    withAnimation(AppTheme.smooth) {
                                        modelContext.delete(preset)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            if preset.id != presets.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                // MARK: Grades
                settingsGroup(title: String(localized: "Grades"), icon: "chart.bar.doc.horizontal", iconColors: [.green, .blue]) {
                    HStack {
                        Text("Average Type")
                        Spacer()
                        Picker("", selection: $averageTypeRaw) {
                            ForEach(AverageType.allCases) { type in
                                Text(type.displayName).tag(type.rawValue)
                            }
                        }
                        .labelsHidden()
                    }
                    Divider()
                    HStack {
                        Text("Grade Scale")
                        Spacer()
                        Picker("", selection: $gradeRangeMax) {
                            Text("1 – 5").tag(5)
                            Text("1 – 6").tag(6)
                            Text("1 – 10").tag(10)
                            Text("1 – 20").tag(20)
                            Text("1 – 30").tag(30)
                            Text("1 – 100").tag(100)
                        }
                        .labelsHidden()
                    }
                }

                settingsGroup(title: "Share & Backup", icon: "square.and.arrow.up", iconColors: [.green, .mint]) {
                    Button {
                        do {
                            exportURL = try ExportManager.shared.exportToURL(classes: classes, tasks: tasks)
                            showingExportSheet = true
                        } catch {
                            importErrorMessage = error.localizedDescription
                            showingImportError = true
                        }
                    } label: {
                        Label("Export Timetable", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Timetable", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.link)
                }

                settingsGroup(title: "iCloud", icon: "icloud.fill", iconColors: [.blue, .indigo]) {
                    Toggle("iCloud Sync", isOn: $iCloudEnabled)
                    if iCloudEnabled {
                        Label("Restart the app to apply iCloud changes.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                settingsGroup(title: "Reset", icon: "trash.fill", iconColors: [.red, .orange]) {
                    Button(role: .destructive) {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset Timetable", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.link)
                    Text("This will permanently delete all classes and tasks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                settingsGroup(title: "About", icon: "info.circle.fill", iconColors: [.gray, .secondary]) {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("TimesTable+")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            devModeTaps += 1
                            if devModeTaps >= 10 {
                                resetOnboarding()
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                do {
                    try ExportManager.shared.importFrom(url: url, context: modelContext)
                } catch {
                    importErrorMessage = error.localizedDescription
                    showingImportError = true
                }
            }
        }
        .confirmationDialog("Reset Timetable", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) { resetAll() }
        } message: {
            Text("All classes and tasks will be permanently deleted. This cannot be undone.")
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .confirmationDialog("Delete Subject", isPresented: $showingDeletePreset, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let preset = presetToDelete {
                    modelContext.delete(preset)
                }
                presetToDelete = nil
            }
        } message: {
            if let preset = presetToDelete {
                Text("Delete \"\(preset.name)\"? This will not delete classes or tasks linked to this subject.")
            }
        }
    }
#endif

    // MARK: - iOS layout
#if os(iOS)
    private var iOSSettings: some View {
        Form {
            // MARK: Appearance
            Section {
                Picker("Theme Mode", selection: Bindable(themeManager).themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                ColorPicker("Accent Color", selection: Bindable(themeManager).accentColor)
                
                Toggle("Use Bottom Tab Bar", isOn: $useBottomTabBar)
                
                if themeManager.themeMode == .custom {
                    Text("Custom Theme Options")
                        .font(.headline)
                        .listRowBackground(Color.clear)
                        .padding(.top, 8)
                    
                    ColorPicker("Background Color", selection: Bindable(themeManager).customBackgroundColor)
                    ColorPicker("Button/Card Color", selection: Bindable(themeManager).customButtonColor)
                    ColorPicker("Icon/Text Color", selection: Bindable(themeManager).customIconColor)
                    
                    HStack {
                        Text("Background Image")
                        Spacer()
                        if themeManager.hasCustomBackgroundImage {
                            Button("Remove") {
                                themeManager.backgroundImageData = nil
                                themeManager.notifyChange()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        Menu("Select...") {
                            Button("Photos App") { showingImagePicker = true }
                            Button("Files / Finder") { showingFilePicker = true }
                        }
                        .menuStyle(.automatic)
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Label("Appearance", systemImage: "paintpalette.fill")
            }

            Section {
                Toggle("Show Weekends", isOn: $showWeekends)
                
                Picker("Default Start Time", selection: $defaultStartTime) {
                    ForEach(Array(stride(from: 480, through: 690, by: 30)), id: \.self) { mins in
                        Text(timeString(from: mins)).tag(mins)
                    }
                }
                
                Picker("Default Class Duration", selection: $defaultClassDuration) {
                    ForEach(Array(stride(from: 30, through: 240, by: 30)), id: \.self) { mins in
                        Text(durationString(from: mins)).tag(mins)
                    }
                }
                
                Toggle("Repeating Weeks", isOn: $repeatingWeeksEnabled)
                if repeatingWeeksEnabled {
                    HStack {
                        Text("Repeat Every")
                        Spacer()
                        Picker("", selection: $numberOfWeeks) {
                            Text("1 \(String(localized: "week"))").tag(1)
                            Text("2 \(String(localized: "weeks"))").tag(2)
                            Text("3 \(String(localized: "weeks"))").tag(3)
                            Text("4 \(String(localized: "weeks"))").tag(4)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                } else {
                    Stepper(value: $numberOfWeeks, in: 1...4) {
                        HStack {
                            Text("Number of Weeks")
                            Spacer()
                            Text("\(numberOfWeeks)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Label("Schedule", systemImage: "calendar")
            }

            // MARK: Subjects
            if !presets.isEmpty {
                Section {
                    ForEach(presets) { preset in
                        HStack {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 10, height: 10)
                            Text(preset.name)
                            if let teacher = preset.teacher, !teacher.isEmpty {
                                Spacer()
                                Text(teacher)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation(AppTheme.smooth) {
                                    modelContext.delete(preset)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Label("Subjects", systemImage: "book.fill")
                }
            }

            // MARK: Grades
            Section {
                Picker("Average Type", selection: $averageTypeRaw) {
                    ForEach(AverageType.allCases) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }
                Picker("Grade Scale", selection: $gradeRangeMax) {
                    Text("1 – 5").tag(5)
                    Text("1 – 6").tag(6)
                    Text("1 – 10").tag(10)
                    Text("1 – 20").tag(20)
                    Text("1 – 30").tag(30)
                    Text("1 – 100").tag(100)
                }
            } header: {
                Label("Grades", systemImage: "chart.bar.doc.horizontal")
            }

            Section {
                Toggle("Class Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                await notifManager.requestAuthorization()
                                if notifManager.isAuthorized {
                                    classes.forEach { notifManager.scheduleNotification(for: $0) }
                                } else {
                                    notificationsEnabled = false
                                }
                            }
                        } else {
                            notifManager.removeAllNotifications()
                        }
                    }
                if notificationsEnabled {
                    Stepper(value: $reminderOffset, in: 1...30) {
                        HStack {
                            Text("Notify before")
                            Spacer()
                            Text("\(reminderOffset) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: reminderOffset) { _, _ in
                        Task {
                            if notifManager.isAuthorized {
                                classes.forEach { notifManager.scheduleNotification(for: $0) }
                            }
                        }
                    }
                    if !notifManager.isAuthorized {
                        Label("Permission denied. Enable in Settings.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            } header: {
                Label("Notifications", systemImage: "bell.badge.fill")
            }

            Section {
                Toggle("iCloud Sync", isOn: $iCloudEnabled)
                if iCloudEnabled {
                    Label("Restart the app to apply iCloud changes.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("iCloud", systemImage: "icloud.fill")
            } footer: {
                Text("Enable iCloud sync to keep your timetable updated across all your devices.")
            }

            Section {
                Button {
                    do {
                        exportURL = try ExportManager.shared.exportToURL(classes: classes, tasks: tasks)
                        showingExportSheet = true
                    } catch {
                        importErrorMessage = error.localizedDescription
                        showingImportError = true
                    }
                } label: {
                    Label("Export Timetable", systemImage: "square.and.arrow.up")
                }
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Import Timetable", systemImage: "square.and.arrow.down")
                }
            } header: {
                Label("Share & Backup", systemImage: "square.and.arrow.up.on.square")
            }

            Section {
                SiriTipView(intent: NextClassIntent(), isVisible: .constant(true))
                SiriTipView(intent: TodayScheduleIntent(), isVisible: .constant(true))
            } header: {
                Label("Siri & Shortcuts", systemImage: "waveform")
            }

            Section {
                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Reset Timetable", systemImage: "trash.fill")
                            .foregroundStyle(.white)
                            .font(.subheadline.bold())
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF453A") ?? .red, Color(hex: "#FF375F") ?? .pink],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } footer: {
                Text("This will permanently delete all classes and tasks.")
            }
            
            Section {
                VStack(spacing: 4) {
                    Text("TimesTable+")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    devModeTaps += 1
                    if devModeTaps >= 10 {
                        resetOnboarding()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .themeBackground(ignoreImage: true)
        .listRowBackground(themeManager.themeMode == .custom ? themeManager.customButtonColor : Color(uiColor: .secondarySystemGroupedBackground))
        .foregroundStyle(themeManager.themeMode == .custom ? themeManager.customIconColor : .primary)
        .navigationTitle("Settings")
#if os(iOS)
        .globalHamburgerMenu(currentTab: $currentTab)
        .safeAreaPadding(.bottom, useBottomTabBar ? 80 : 0)
#endif
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                do {
                    try ExportManager.shared.importFrom(url: url, context: modelContext)
                } catch {
                    importErrorMessage = error.localizedDescription
                    showingImportError = true
                }
            }
        }
        .confirmationDialog("Reset Timetable", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) { resetAll() }
        } message: {
            Text("All classes and tasks will be permanently deleted. This cannot be undone.")
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .alert(String(localized: "Developer Mode"), isPresented: $showingDevAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(String(localized: "App onboarding flags have been reset. Close and reopen the app to view the Welcome Screen!"))
        }
    }
#endif

    // MARK: - Helpers

    private func resetOnboarding() {
        hasSeenWelcome = false
        hasSeenTutorial = false
        devModeTaps = 0
        showingDevAlert = true
    }

    private func timeString(from minutes: Int) -> String {
        let hour = minutes / 60
        let min = minutes % 60
        return String(format: "%02d:%02d", hour, min)
    }

    private func durationString(from minutes: Int) -> String {
        let hour = minutes / 60
        let min = minutes % 60
        if hour == 0 { return "\(min) min" }
        if min == 0 { return "\(hour) hr" }
        return "\(hour) hr \(min) min"
    }

    private func resetAll() {
        notifManager.removeAllNotifications()
        classes.forEach { modelContext.delete($0) }
        tasks.forEach { modelContext.delete($0) }
    }

    // Reusable settings group for macOS
    private func settingsGroup<Content: View>(
        title: String,
        icon: String,
        iconColors: [Color],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(colors: iconColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - macOS Settings Group helper (kept for backward compat)

#if os(macOS)
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
        }
    }
}
#endif

// MARK: - Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheet: View {
    let url: URL
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text(url.lastPathComponent)
                .font(.headline)
            ShareLink(item: url) {
                Label("Share…", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
#endif
