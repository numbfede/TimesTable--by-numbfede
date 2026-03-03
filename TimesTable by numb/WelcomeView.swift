import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentSlide = 0
    @State private var offset: CGFloat = 0
    
    // Aesthetic animations
    @State private var isAnimatingGradients = false
    
    var body: some View {
        ZStack {
            // Animated Liquid Background
            animatedBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Content Cards Carousel
                TabView(selection: $currentSlide) {
                    onboardingSlide(
                        icon: "calendar.badge.clock",
                        title: String(localized: "Welcome to TimesTable+"),
                        description: String(localized: "Your premium schedule, beautifully organized.\nKeep track of your classes and study hours with elegance."),
                        color: .blue
                    ).tag(0)
                    
                    onboardingSlide(
                        icon: "paintpalette.fill",
                        title: String(localized: "Deeply Yours"),
                        description: String(localized: "Customize everything.\nChoose dynamic themes, custom colors, and animated backgrounds that match your style."),
                        color: .purple
                    ).tag(1)
                    
                    onboardingSlide(
                        icon: "graduationcap.fill",
                        title: String(localized: "Achieve More"),
                        description: String(localized: "Track tasks, assignments, and grades intelligently.\nWe'll handle the math, you focus on the results."),
                        color: .green
                    ).tag(2)
                }
#if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
#endif
                .frame(maxHeight: 450)
                
                Spacer()
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == currentSlide ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == currentSlide ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentSlide)
                    }
                }
                .padding(.bottom, 16)
                
                // Animated Next/Get Started Button
                nextButton
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Animated Liquid Background
    private var animatedBackground: some View {
        ZStack {
            Color.black // Base deep background
            
            // Floating coloured orbs mimicking Liquid Glass
            Circle()
                .fill(Color.blue.opacity(0.6))
                .blur(radius: 80)
                .offset(x: isAnimatingGradients ? -100 : 100, y: isAnimatingGradients ? -150 : 100)
                .frame(width: 300, height: 300)
            
            Circle()
                .fill(Color.purple.opacity(0.6))
                .blur(radius: 80)
                .offset(x: isAnimatingGradients ? 150 : -100, y: isAnimatingGradients ? 150 : -100)
                .frame(width: 250, height: 250)
            
            Circle()
                .fill(Color.indigo.opacity(0.5))
                .blur(radius: 90)
                .offset(x: isAnimatingGradients ? -50 : 50, y: isAnimatingGradients ? 200 : -200)
                .frame(width: 350, height: 350)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                isAnimatingGradients.toggle()
            }
        }
    }
    
    // MARK: - Slide Component
    private func onboardingSlide(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 70, weight: .thin))
                .foregroundStyle(
                    LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.bounce, options: .repeating)
            
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 30)
                .lineSpacing(4)
        }
        .padding(40)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                if currentSlide < 2 {
                    currentSlide += 1
                } else {
                    completeOnboarding()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(currentSlide < 2 ? String(localized: "Next") : String(localized: "Get Started"))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Image(systemName: currentSlide < 2 ? "arrow.right" : "sparkles")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .contentShape(Capsule())
    }
    
    private func completeOnboarding() {
        hasSeenWelcome = true
        dismiss()
    }
}
