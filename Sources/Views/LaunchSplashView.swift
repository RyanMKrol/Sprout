import SwiftUI

struct LaunchSplashView: View {
    @State private var isFloating = false
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            // Full-bleed launch gradient background
            SproutTheme.launchGradient
                .ignoresSafeArea()

            VStack {
                // Soft radial white glow (300Ø, white@0.08) upper-center
                ZStack {
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.08), location: 0),
                            .init(color: Color.white.opacity(0), location: 1),
                        ]),
                        center: .init(x: 0.5, y: 0.2),
                        startRadius: 0,
                        endRadius: 150
                    )

                    VStack(spacing: 24) {
                        Spacer()

                        // 114×114 radius-32 frosted tile
                        ZStack {
                            // Tile background (white@0.12 fill)
                            Color.white.opacity(0.12)

                            // Seedling icon (58pt in cream)
                            ChromeIcon.seedling.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 58, height: 58)
                                .foregroundColor(SproutTheme.cream)
                        }
                        .frame(width: 114, height: 114)
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.32), radius: 50, x: 0, y: 22)
                        .offset(y: isFloating ? -5 : 5)
                        .animation(
                            .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                            value: isFloating
                        )

                        // "Sprout" wordmark (36pt Bricolage, #F4F1E7)
                        Text("Sprout")
                            .font(SproutFont.display(36))
                            .foregroundColor(Color(hex: 0xF4F1E7))

                        Spacer()

                        // 26Ø spinner at 72 from bottom
                        ZStack {
                            // Background ring (white@0.22)
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 2.5)

                            // Rotating cream arc
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: 0.3)
                                    .stroke(SproutTheme.cream, lineWidth: 2.5)
                            }
                            .rotationEffect(.degrees(isSpinning ? 360 : 0))
                            .animation(
                                .linear(duration: 0.9).repeatForever(autoreverses: false),
                                value: isSpinning
                            )
                        }
                        .frame(width: 26, height: 26)
                        .padding(.bottom, 72)
                    }
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            isFloating = true
            isSpinning = true
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LaunchSplashView()
}
#endif

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
