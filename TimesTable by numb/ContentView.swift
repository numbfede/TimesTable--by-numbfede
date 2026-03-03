import SwiftUI
import SwiftData

// MARK: - Navigation Destinations (iOS hamburger menu)

enum iOSTab: String, CaseIterable {
    case home = "Home"
    case tasks = "Tasks"
    case grades = "Grades"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "calendar"
        case .tasks: return "checklist"
        case .grades: return "chart.bar.doc.horizontal"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Root Content View

struct ContentView: View {
    @State private var selectedDay: Int = {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }()

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var tutorialFrames: [TutorialStep: CGRect] = [:]

    var body: some View {
        Group {
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
        .onPreferenceChange(TutorialFrameKey.self) { frames in
            self.tutorialFrames = frames
        }
#if os(iOS)
        .fullScreenCover(isPresented: .init(get: { !hasSeenWelcome }, set: { _ in })) {
            WelcomeView()
        }
#else
        .sheet(isPresented: .init(get: { !hasSeenWelcome }, set: { _ in })) {
            WelcomeView()
                .frame(minWidth: 600, minHeight: 450)
        }
#endif
        .overlay {
            if hasSeenWelcome && !hasSeenTutorial {
                TutorialOverlayView(targetFrames: tutorialFrames)
            }
        }
    }

#if os(iOS)
    @Environment(ThemeManager.self) private var themeManager
    @State private var currentTab: iOSTab = .home
    @AppStorage("useBottomTabBar") private var useBottomTabBar = true

    private var iOSRootView: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch currentTab {
                case .home:
                    NavigationStack {
                        ScheduleView(selectedDay: $selectedDay, currentTab: $currentTab)
                            .toolbarBackground(.hidden, for: .navigationBar)
                    }
                case .tasks:
                    NavigationStack {
                        TaskListView(currentTab: $currentTab)
                            .toolbarBackground(.hidden, for: .navigationBar)
                    }
                case .grades:
                    NavigationStack {
                        GradesView(currentTab: $currentTab)
                            .toolbarBackground(.hidden, for: .navigationBar)
                    }
                case .settings:
                    NavigationStack {
                        SettingsView(currentTab: $currentTab)
                            .toolbarBackground(.hidden, for: .navigationBar)
                    }
                }
            }
            .safeAreaPadding(.bottom, useBottomTabBar ? 80 : 0) // Spazio per la tab bar
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if useBottomTabBar {
                // Custom Floating Tab Bar
                FloatingTabBar(activeTab: $currentTab)
                    .tutorialTarget(.bottomTabs)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToSettings"))) { _ in
            withAnimation {
                currentTab = .settings
            }
        }
    }
#endif
}

// MARK: - Global Hamburger Menu (iOS only)

#if os(iOS)
struct GlobalHamburgerMenu: ViewModifier {
    @Binding var currentTab: iOSTab
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage("useBottomTabBar") private var useBottomTabBar = true

    func body(content: Content) -> some View {
        content
            .toolbar {
                if !useBottomTabBar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button {
                                currentTab = .home
                            } label: {
                                Label("Schedule", systemImage: "calendar")
                            }
                            Button {
                                currentTab = .tasks
                            } label: {
                                Label("Tasks", systemImage: "checklist")
                            }
                            Button {
                                currentTab = .grades
                            } label: {
                                Label("Grades", systemImage: "chart.bar.doc.horizontal")
                            }
                            Button {
                                currentTab = .settings
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
            }
    }
}

extension View {
    func globalHamburgerMenu(currentTab: Binding<iOSTab>) -> some View {
#if os(iOS)
        modifier(GlobalHamburgerMenu(currentTab: currentTab))
#else
        self
#endif
    }
}
#endif

// MARK: - Floating Tab Bar (iOS only)

#if os(iOS)
struct FloatingTabBar: View {
    @Binding var activeTab: iOSTab
    @Environment(ThemeManager.self) private var themeManager
    @Namespace private var animation
    @State private var barWidth: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(iOSTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
                        activeTab = tab
                    }
                    Haptic.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                            .frame(height: 24)
                        Text(tab.rawValue)
                            .font(.caption2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    // Il colore dipenderà se la tab è attiva o meno
                    .foregroundStyle(activeTab == tab ? .white : .primary.opacity(0.5))
                    // Sfondo animato (solo per il tab selezionato)
                    .background {
                        if activeTab == tab {
                            Capsule()
                                .fill(themeManager.accentColor)
                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                .shadow(color: themeManager.accentColor.opacity(0.4), radius: 8, y: 4)
                        }
                    }
                    // Effetto "Liquid" al click
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .modifier(SettingsTutorialTarget(tab: tab))
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { barWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, w in barWidth = w }
            }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard barWidth > 0 else { return }
                    let tabWidth = barWidth / CGFloat(iOSTab.allCases.count)
                    let x = min(max(value.location.x, 0), barWidth - 1)
                    let index = Int(x / tabWidth)
                    let tabs = iOSTab.allCases
                    let newTab = tabs[index]
                    
                    if activeTab != newTab {
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.65, blendDuration: 0)) {
                            activeTab = newTab
                        }
                        Haptic.selection()
                    }
                }
        )
        .padding(6)
        .background {
            Capsule()
                .fill(.clear)
        }
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

private struct SettingsTutorialTarget: ViewModifier {
    let tab: iOSTab
    
    func body(content: Content) -> some View {
        if tab == .settings {
            content.tutorialTarget(.settingsTutorial)
        } else {
            content
        }
    }
}
#endif

// MARK: - Sidebar (macOS only)

#if os(macOS)
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
#endif

// MARK: - Schedule View

struct ScheduleView: View {
    @Binding var selectedDay: Int
#if os(iOS)
    @Binding var currentTab: iOSTab
#endif
    @Query(sort: \SchoolClass.startTime) private var classes: [SchoolClass]
    @State private var showingAddClass = false
    @AppStorage("showWeekends") private var showWeekends = true
    @AppStorage("numberOfWeeks") private var numberOfWeeks = 1
    @AppStorage("repeatingWeeksEnabled") private var repeatingWeeksEnabled = false
    @AppStorage("useBottomTabBar") private var useBottomTabBar = true

    @State private var selectedWeek: Int = 1

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.scenePhase) private var scenePhase
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
        
        let cal = Calendar.current
        let mapped = filtered.map { sc -> (classItem: SchoolClass, start: Int, end: Int) in
            let startComp = cal.dateComponents([.hour, .minute], from: sc.startTime)
            let endComp = cal.dateComponents([.hour, .minute], from: sc.endTime)
            let startMins = (startComp.hour ?? 0) * 60 + (startComp.minute ?? 0)
            let endMins = (endComp.hour ?? 0) * 60 + (endComp.minute ?? 0)
            return (classItem: sc, start: startMins, end: endMins)
        }
        
        return mapped.sorted { a, b in
            if a.start != b.start {
                return a.start < b.start
            }
            return a.end < b.end
        }.map { $0.classItem }
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
#if os(iOS)
        .globalHamburgerMenu(currentTab: $currentTab)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddClass.toggle() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .tutorialTarget(.addClass)
                }
            }
#else
            if !isLandscape {
                ToolbarItem {
                    Button { showingAddClass.toggle() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .tutorialTarget(.addClass)
                    }
                }
            }
#endif
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
            .tutorialTarget(.homeNavigation)
            .onChange(of: selectedDay) { _, newVal in
                withAnimation(AppTheme.smooth) {
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
        }
        .onChange(of: classes) { _, newClasses in
            WidgetDataManager.shared.updateWidgetData(classes: newClasses)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WidgetDataManager.shared.updateWidgetData(classes: classes)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .background {
            if themeManager.themeMode == .custom {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(themeManager.customButtonColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                            .strokeBorder(schoolClass.color.opacity(0.15), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(.clear)
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppTheme.cardRadius))
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
