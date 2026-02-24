import SwiftUI

enum TutorialStep: Int, CaseIterable, Identifiable {
    case addClass = 0
    case homeNavigation = 1
    case bottomTabs = 2
    case settingsTutorial = 3
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .addClass: return String(localized: "Add Classes")
        case .homeNavigation: return String(localized: "Navigate Days")
        case .bottomTabs: return String(localized: "Switch Views")
        case .settingsTutorial: return String(localized: "Make It Yours")
        }
    }
    
    var description: String {
        switch self {
        case .addClass: return String(localized: "Tap the plus button (top right) to add a new class or task to your schedule.")
        case .homeNavigation: return String(localized: "Use this bar to quickly jump back to Today or view different days of the week.")
        case .bottomTabs: return String(localized: "Quickly switch between Schedule, Tasks, Grades, and Settings.")
        case .settingsTutorial: return String(localized: "We'll now take you to Settings, where you can customize themes, colors, and background images!")
        }
    }
}

// Preference Keys to collect UI element frames
struct TutorialFrameKey: PreferenceKey {
    static var defaultValue: [TutorialStep: CGRect] = [:]
    
    static func reduce(value: inout [TutorialStep: CGRect], nextValue: () -> [TutorialStep: CGRect]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

extension View {
    func tutorialTarget(_ step: TutorialStep) -> some View {
        self.background(GeometryReader { geo in
            Color.clear.preference(key: TutorialFrameKey.self, value: [step: geo.frame(in: .global)])
        })
    }
}

struct TutorialOverlayView: View {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    let targetFrames: [TutorialStep: CGRect]
    
    @State private var currentStepIndex = 0
    @State private var isAnimatingArrow = false
    @State private var containerSize: CGSize = .zero
    
    var currentStep: TutorialStep {
        TutorialStep(rawValue: currentStepIndex) ?? .addClass
    }
    
    // Returns the exact frame if SwiftUI found it, or an educated guess if it was hidden in a Toolbar
    private func getFrame(for step: TutorialStep, in size: CGSize) -> CGRect? {
        if let frame = targetFrames[step], frame.width > 0 && frame.height > 0 {
            return frame
        }
        
        // Fallbacks for Toolbar items that evade GeometryReader
        switch step {
        case .addClass:
            #if os(iOS)
            return CGRect(x: size.width - 60, y: 55, width: 44, height: 44)
            #else
            return CGRect(x: size.width - 64, y: 20, width: 44, height: 44)
            #endif
        case .homeNavigation:
            return CGRect(x: size.width / 2 - 100, y: 120, width: 200, height: 80)
        case .bottomTabs:
            #if os(iOS)
            return CGRect(x: 20, y: size.height - 100, width: size.width - 40, height: 70)
            #else
            return nil
            #endif
        case .settingsTutorial:
            #if os(iOS)
            return CGRect(x: size.width - 90, y: size.height - 100, width: 80, height: 70)
            #else
            return nil
            #endif
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let frame = getFrame(for: currentStep, in: size)
            let isTopHalf = (frame?.maxY ?? 0) < size.height / 2
            
            ZStack {
                // Darker overlay
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .mask {
                        if let f = frame {
                            Rectangle()
                                .fill(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .frame(width: f.width + 16, height: f.height + 16)
                                        .position(x: f.midX, y: f.midY)
                                        .blendMode(.destinationOut)
                                )
                        } else {
                            Rectangle().fill(.white)
                        }
                    }
                    .allowsHitTesting(true)
                
                // Popover Panel (Adobe Photoshop style)
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title2)
                        Text(currentStep.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(currentStepIndex + 1)/\(TutorialStep.allCases.count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Text(currentStep.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if currentStepIndex < TutorialStep.allCases.count - 1 {
                                    currentStepIndex += 1
                                } else {
                                    hasSeenTutorial = true
                                    NotificationCenter.default.post(name: Notification.Name("NavigateToSettings"), object: nil)
                                }
                            }
                        } label: {
                            Text(currentStepIndex < TutorialStep.allCases.count - 1 ? String(localized: "Next") : String(localized: "Let's Go!"))
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                // Photoshop uses opaque, clean, high-contrast tooltips
    #if os(iOS)
                .background(Color(uiColor: .systemBackground))
    #else
                .background(Color(nsColor: .windowBackgroundColor))
    #endif
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .frame(width: min(340, size.width - 40))
                .position(
                    x: size.width / 2,
                    y: frame != nil ? (isTopHalf ? frame!.maxY + 140 : frame!.minY - 140) : size.height / 2
                )
                
                // Animated Highlight Pointer Arrow
                if let f = frame {
                    Image(systemName: isTopHalf ? "arrow.up" : "arrow.down")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        .position(
                            x: f.midX,
                            y: isTopHalf ? f.maxY + (isAnimatingArrow ? 30 : 15) : f.minY - (isAnimatingArrow ? 30 : 15)
                        )
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isAnimatingArrow.toggle()
                }
            }
        }
        .ignoresSafeArea() // Critical fix for coordinate offset bug
    }
}

#if os(macOS)
// AppKit screensize equivalent helper
import AppKit
extension NSScreen {
    static var mainBounds: CGRect {
        return NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
    }
}
struct UIScreen {
    static let main = UIScreen()
    var bounds: CGRect { NSScreen.mainBounds }
}
#else
import UIKit
#endif
