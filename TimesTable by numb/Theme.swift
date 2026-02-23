import SwiftUI

// MARK: - Vivid Color Palette

enum AppTheme {

    // 12 vibrant class colors — electric, bold, eye-catching
    static let palette: [(hex: String, name: String)] = [
        ("#0A84FF", "Electric Blue"),
        ("#FF453A", "Coral Red"),
        ("#30D158", "Emerald"),
        ("#FFD60A", "Amber"),
        ("#BF5AF2", "Violet"),
        ("#FF375F", "Magenta"),
        ("#64D2FF", "Cyan"),
        ("#FF6482", "Rose"),
        ("#5E5CE6", "Indigo"),
        ("#32D74B", "Lime"),
        ("#FF9F0A", "Tangerine"),
        ("#AC8E68", "Mocha"),
    ]

    // MARK: Gradients

    /// Background gradient for the main window (subtle, dark-mode aware)
    static func backgroundGradient(scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "#0C0C1D") ?? .black, Color(hex: "#1A1A2E") ?? .black],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "#F2F2F7") ?? .white, Color(hex: "#E5E5EA") ?? .white],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    /// Card gradient from a class color — primary → 20% lighter
    static func cardGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    /// Accent strip gradient (vertical, for card left edge)
    static func stripGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.5)],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// Header gradient for detail views
    static func headerGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.9), color.opacity(0.4)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: Animations

    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let quick  = Animation.easeOut(duration: 0.2)

    // MARK: Shadows — use as: .modifier(AppTheme.cardShadowModifier(color))

    // MARK: Corner Radii

    static let cardRadius: CGFloat = 16
    static let chipRadius: CGFloat = 10
    static let pillRadius: CGFloat = 20
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardRadius

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.cardRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Ring (for color picker selection)

struct GlowRing: ViewModifier {
    let color: Color
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: isSelected ? 3 : 0)
                    .padding(-4)
            )
            .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: isSelected ? 6 : 0)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(AppTheme.bouncy, value: isSelected)
    }
}

extension View {
    func glowRing(color: Color, isSelected: Bool) -> some View {
        modifier(GlowRing(color: color, isSelected: isSelected))
    }
}

// MARK: - Haptic Feedback Helper

#if os(iOS)
enum Haptic {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
#endif

// MARK: - Pulsating Modifier (for empty states)

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 0.95)
            .opacity(isPulsing ? 1.0 : 0.6)
            .onAppear {
                // Delay to let initial layout settle, then start pulsing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
}

extension View {
    func pulsating() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Gradient Text

struct GradientText: View {
    let text: LocalizedStringKey
    let font: Font
    let colors: [Color]

    init(_ text: LocalizedStringKey, font: Font = .title2.bold(), colors: [Color] = [Color(hex: "#0A84FF") ?? .blue, Color(hex: "#BF5AF2") ?? .purple]) {
        self.text = text
        self.font = font
        self.colors = colors
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
    }
}

// MARK: - App Custom Background

struct ThemeBackground: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var ignoreImage: Bool = false

    var body: some View {
        Group {
            if themeManager.themeMode == .custom {
                if !ignoreImage && themeManager.hasCustomBackgroundImage, let data = themeManager.backgroundImageData {
#if os(iOS)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        themeManager.customBackgroundColor.ignoresSafeArea()
                    }
#else
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        themeManager.customBackgroundColor.ignoresSafeArea()
                    }
#endif
                } else {
                    themeManager.customBackgroundColor.ignoresSafeArea()
                }
            } else {
                AppTheme.backgroundGradient(scheme: colorScheme)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - View Extension for Background

extension View {
    func themeBackground(ignoreImage: Bool = false) -> some View {
        self.background(ThemeBackground(ignoreImage: ignoreImage))
    }
}
