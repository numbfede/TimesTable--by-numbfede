import SwiftUI
import SwiftData

// MARK: - Navigation Destinations (iOS hamburger menu)

enum AppDestination: Hashable {
    case tasks
    case grades
    case settings
}

// MARK: - Root Content View

struct ContentView: View {
    @State private var selectedDay: Int = {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }()

        var body: some View {
            #if os(iOS)
                iOSRootView
            #else
                NavigationSplitView {
            SidebarView(selectedDay: $selectedDay)
        } detail: {
            ScheduleView(selectedDay: $selectedDay)
        }
#endif
    }

#if os(iOS)
    @Environment(ThemeManager.self) private var themeManager
    @State private var navigationPath = NavigationPath()

    private var iOSRootView: some View {
        NavigationStack(path: $navigationPath) {
            ScheduleView(selectedDay: $selectedDay)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button {
                                navigationPath.append(AppDestination.tasks)
                            } label: {
                                Label("Tasks", systemImage: "checklist")
                            }
                            Button {
                                navigationPath.append(AppDestination.grades)
                            } label: {
                                Label("Grades", systemImage: "chart.bar.doc.horizontal")
                            }
                            Button {
                                navigationPath.append(AppDestination.settings)
                            } label: {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                    }
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .tasks:
                        TaskListView()
                    case .grades:
                        GradesView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
#endif
}

// MARK: - Sidebar (macOS only)

struct SidebarView: View {
    @Binding var selectedDay: Int

    var body: some View {
        List {
            NavigationLink {
                ScheduleView(selectedDay: $selectedDay)
            } label: {
                Label { Text("Schedule") } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            NavigationLink {
                TaskListView()
            } label: {
                Label { Text("Tasks") } icon: {
                    Image(systemName: "checklist")
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            NavigationLink {
                GradesView()
            } label: {
                Label { Text("Grades") } icon: {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
            NavigationLink {
                SettingsView()
            } label: {
                Label { Text("Settings") } icon: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(
                            LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            }
        }
        .navigationTitle("TimesTable+")
    }
}

// MARK: - Schedule View

struct ScheduleView: View {
    @Binding var selectedDay: Int
    @Query(sort: \SchoolClass.startTime) private var classes: [SchoolClass]
    @State private var showingAddClass = false
    @AppStorage("showWeekends") private var showWeekends = true
    @AppStorage("numberOfWeeks") private var numberOfWeeks = 1
    @AppStorage("repeatingWeeksEnabled") private var repeatingWeeksEnabled = false

    @State private var selectedWeek: Int = 1

    @Environment(\.horizontalSizeClass) private var hSizeClass
#if os(iOS)
    @State private var orientation = UIDevice.current.orientation
#endif

    private var isLandscape: Bool {
#if os(iOS)
        return orientation.isLandscape
#else
        return false
#endif
    }

    // Use Calendar API for auto-localized day names
    private var dayTags: [(Int, String, String)] {
        let cal = Calendar.current
        let short = cal.shortWeekdaySymbols    // ["Sun","Mon",..."Sat"]
        let veryShort = cal.veryShortWeekdaySymbols
        // App uses 1=Mon...7=Sun; Calendar uses 0=Sun,1=Mon...6=Sat
        let all: [(Int, String, String)] = (1...7).map { tag in
            let calIndex = tag % 7  // 1→1, 2→2, ..., 6→6, 7→0
            return (tag, short[calIndex], veryShort[calIndex])
        }
        return showWeekends ? all : Array(all.prefix(5))
    }

    private var todayIndex: Int {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }

    /// Determine current cycle week when repeating is enabled
    private var currentCycleWeek: Int {
        let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
        return ((weekOfYear - 1) % numberOfWeeks) + 1
    }

    func classesFor(day: Int) -> [SchoolClass] {
        let filtered: [SchoolClass]
        if numberOfWeeks > 1 {
            filtered = classes.filter { $0.dayOfWeek == day && $0.weekIndex == selectedWeek }
        } else {
            filtered = classes.filter { $0.dayOfWeek == day }
        }
        
        return filtered.sorted { a, b in
            let cal = Calendar.current
            let aComp = cal.dateComponents([.hour, .minute], from: a.startTime)
            let bComp = cal.dateComponents([.hour, .minute], from: b.startTime)
            
            let aTime = (aComp.hour ?? 0) * 60 + (aComp.minute ?? 0)
            let bTime = (bComp.hour ?? 0) * 60 + (bComp.minute ?? 0)
            
            if aTime != bTime {
                return aTime < bTime
            } else {
                let aEnd = cal.dateComponents([.hour, .minute], from: a.endTime)
                let bEnd = cal.dateComponents([.hour, .minute], from: b.endTime)
                return ((aEnd.hour ?? 0) * 60 + (aEnd.minute ?? 0)) < ((bEnd.hour ?? 0) * 60 + (bEnd.minute ?? 0))
            }
        }
    }

    var body: some View {
        Group {
            if isLandscape {
                WeekGridView()
            } else {
                portraitView
            }
        }
        .themeBackground()
        .navigationTitle(isLandscape ? "Week View" : "Schedule")
        .toolbar {
            if !isLandscape {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddClass.toggle() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
#else
                ToolbarItem {
                    Button { showingAddClass.toggle() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
#endif
            }
        }
        .sheet(isPresented: $showingAddClass) {
            AddEditClassView(defaultWeekIndex: selectedWeek)
        }
        .onAppear {
            if repeatingWeeksEnabled && numberOfWeeks > 1 {
                selectedWeek = currentCycleWeek
            }
        }
#if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
#endif
    }

    @Environment(ThemeManager.self) private var themeManager

    private var portraitView: some View {
        VStack(spacing: 0) {
            if numberOfWeeks > 1 {
                weekPickerBar
            }
            dayPickerBar
            
#if os(iOS)
            TabView(selection: $selectedDay) {
                ForEach(dayTags, id: \.0) { tag, _, _ in
                    dayContent(for: tag)
                        .tag(tag)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
#else
            dayContent(for: selectedDay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
        }
    }
    
    @ViewBuilder
    private func dayContent(for day: Int) -> some View {
        let dayClasses = classesFor(day: day)
        if dayClasses.isEmpty {
            emptyState
        } else {
            classList(for: dayClasses)
        }
    }

    // MARK: Week Picker (pills)

    private var weekPickerBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...numberOfWeeks, id: \.self) { week in
                    Button {
                        withAnimation(AppTheme.smooth) {
                            selectedWeek = week
                        }
#if os(iOS)
                        Haptic.selection()
#endif
                    } label: {
                        HStack(spacing: 4) {
                            Text("W\(week)")
                                .font(.subheadline.bold())
                            if repeatingWeeksEnabled && week == currentCycleWeek {
                                Circle()
                                    .fill(Color(hex: "#30D158") ?? .green)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedWeek == week
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                    startPoint: .leading, endPoint: .trailing
                                  ))
                                : AnyShapeStyle(Color.secondary.opacity(0.1))
                        )
                        .foregroundStyle(selectedWeek == week ? .white : .primary)
                        .clipShape(Capsule())
                        .shadow(color: selectedWeek == week ? themeManager.accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: Day Picker (animated pills)

    private var dayPickerBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(dayTags, id: \.0) { tag, label, _ in
                        Button {
                            withAnimation(AppTheme.smooth) {
                                selectedDay = tag
                            }
#if os(iOS)
                            Haptic.selection()
#endif
                        } label: {
                            VStack(spacing: 4) {
                                Text(label)
                                    .font(.subheadline.bold())
                                // Today dot
                                Circle()
                                    .fill(tag == todayIndex ? Color(hex: "#FF453A") ?? .red : .clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(width: 52, height: 52)
                            .background(
                                Group {
                                    if selectedDay == tag {
                                        LinearGradient(
                                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    } else {
                                        Color.secondary.opacity(0.1)
                                    }
                                }
                            )
                            .foregroundStyle(selectedDay == tag ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: selectedDay == tag ? themeManager.accentColor.opacity(0.3) : .clear, radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                        .id(tag)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .onChange(of: selectedDay) { _, newVal in
                withAnimation(AppTheme.smooth) {
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
        }
    }

    // MARK: Class List

    private func classList(for classes: [SchoolClass]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(classes) { sc in
                    NavigationLink {
                        ClassDetailView(schoolClass: sc)
                    } label: {
                        ClassRow(schoolClass: sc)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .pulsating()

            GradientText("No Classes", font: .title2.bold(), colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)])

            Text("Tap + to add a class for this day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Class Row (Glass Card)

struct ClassRow: View {
    let schoolClass: SchoolClass
    @State private var isPressed = false
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack(spacing: 0) {
            // Gradient accent strip
            RoundedRectangle(cornerRadius: 3)
                .fill(AppTheme.stripGradient(for: schoolClass.color))
                .frame(width: 5)
                .padding(.vertical, 6)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(schoolClass.name)
                        .font(.headline)
                        .foregroundStyle(themeManager.themeMode == .custom ? themeManager.customIconColor : .primary)

                    HStack(spacing: 10) {
                        if let room = schoolClass.room, !room.isEmpty {
                            Label(room, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let teacher = schoolClass.teacher, !teacher.isEmpty {
                            Label(teacher, systemImage: "person.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 12)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(schoolClass.startTime, style: .time)
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(themeManager.themeMode == .custom ? themeManager.customIconColor : .primary)
                    Text(schoolClass.endTime, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(themeManager.themeMode == .custom ? themeManager.customButtonColor : schoolClass.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .strokeBorder(schoolClass.color.opacity(0.15), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: schoolClass.color.opacity(0.12), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(AppTheme.bouncy, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }) {}
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SchoolClass.self, StudyTask.self], inMemory: true)
}
