import SwiftUI
import AppKit

// MARK: - Onboarding Feature Page Model

struct OnboardingPage: Identifiable {
    let id: Int
    let badge: String
    let title: String
    let tagLine: String
    let description: String
    let systemImage: String
    let accentGradient: [Color]
    let previewSpec: IconSpec
    let highlights: [(icon: String, text: String)]
}

// MARK: - Welcome & Onboarding View (Refined Professional + Fun Aesthetic)

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding_v1") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var hoverTilt: CGSize = .zero
    @State private var isHovering: Bool = false
    @ObservedObject private var store = IconStore.shared

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            badge: "WELCOME TO FOLDERLAB",
            title: "Your Folders, Reimagined.",
            tagLine: "Say goodbye to generic blue icons forever.",
            description: "FolderLab is your bespoke macOS studio to craft, skin, and stamp folders with handcrafted gradients, tactile textures, and pixel-perfect Retina detail.",
            systemImage: "paintpalette.fill",
            accentGradient: [Color(hex: "#00C6FF") ?? .cyan, Color(hex: "#0072FF") ?? .blue],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#00C6FF") ?? .cyan
                s.color2 = Color(hex: "#0072FF") ?? .blue
                s.symbolName = "sparkles"
                s.glyphColor = .white
                return s
            }(),
            highlights: [
                ("wand.and.stars", "Instant live preview across all native macOS sizes"),
                ("cursorarrow.rays", "Drag any folder from Finder to stage & compare live"),
                ("arrow.counterclockwise", "100% reversible anytime with 1-click default restore")
            ]
        ),
        OnboardingPage(
            id: 1,
            badge: "DESKTOP HARMONY",
            title: "Match Your Desktop Wallpaper.",
            tagLine: "Sample vibrant palettes straight from your screen.",
            description: "With 1 click, FolderLab samples dominant and accent tones from your active wallpaper—generating 7 tailored themes that blend effortlessly into your desktop.",
            systemImage: "desktopcomputer",
            accentGradient: [Color(hex: "#38EF7D") ?? .green, Color(hex: "#11998E") ?? .teal],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#38EF7D") ?? .green
                s.color2 = Color(hex: "#11998E") ?? .teal
                s.symbolName = "desktopcomputer"
                s.liquidGlass = true
                s.glassOpacity = 0.42
                return s
            }(),
            highlights: [
                ("eye.fill", "Supports dynamic Light & Dark wallpaper shifts automatically"),
                ("slider.horizontal.3", "7 distinct handcrafted themes per wallpaper extraction"),
                ("paintpalette.fill", "Directly click color swatches to apply custom flap tones")
            ]
        ),
        OnboardingPage(
            id: 2,
            badge: "CREATIVE CRAFT",
            title: "Peek Inside & Tactile Finishes.",
            tagLine: "Skeuomorphic joy meets modern Apple precision.",
            description: "Tuck documents, code, photos, or vinyl records peeking out from the front flap. Add tactile grain, carbon fiber, debossed stamps, or frosted liquid glass.",
            systemImage: "tray.and.arrow.up.fill",
            accentGradient: [Color(hex: "#FF8A5B") ?? .orange, Color(hex: "#EA3B7A") ?? .pink],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#FF8A5B") ?? .orange
                s.color2 = Color(hex: "#EA3B7A") ?? .pink
                s.peekInsideEnabled = true
                s.peekContentType = .code
                s.texture = .leather
                s.textureOpacity = 0.22
                s.glyphKind = .text
                s.text = "PRO"
                s.nameplateEnabled = true
                s.nameplateText = "SRC"
                return s
            }(),
            highlights: [
                ("doc.text.fill", "Peek Inside presets: Documents, Code, Photos & Vinyl"),
                ("square.grid.3x3.topleft.filled", "Carbon fiber, brushed titanium, tactile grain & dot matrix"),
                ("tag.fill", "Authentic retro embossed nameplates & brass plaques")
            ]
        ),
        OnboardingPage(
            id: 3,
            badge: "SEAMLESS WORKFLOW",
            title: "Drag. Style. Done.",
            tagLine: "Customizing your workspace has never felt this good.",
            description: "Drop any folder onto the studio stage, pick your favorite vibe or hit Surprise Me, and click Apply. Your Mac desktop is now unmistakably yours.",
            systemImage: "checkmark.seal.fill",
            accentGradient: [Color(hex: "#8E54E9") ?? .purple, Color(hex: "#4776E6") ?? .blue],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#8E54E9") ?? .purple
                s.color2 = Color(hex: "#4776E6") ?? .blue
                s.symbolName = "heart.fill"
                s.glyphColor = .white
                return s
            }(),
            highlights: [
                ("arrow.down.doc.fill", "1-Tap Apply to Target Folder with instant desktop refresh"),
                ("arrow.triangle.2.circlepath", "Shareable .folderlab preset files to export and share"),
                ("gearshape.fill", "Custom dock app icons in Clear, Dark, Light & Tinted")
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 36) {
                // Left Interactive Preview Stage
                VStack(spacing: 16) {
                    ZStack {
                        // Ambient Radial Glow behind the icon
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        pages[currentPage].accentGradient.first?.opacity(0.38) ?? .clear,
                                        pages[currentPage].accentGradient.last?.opacity(0.12) ?? .clear,
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 130
                                )
                            )
                            .frame(width: 250, height: 250)
                            .blur(radius: 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                        // Responsive 3D Tilt Stage Preview (ID forces clean smooth transition on page change)
                        IconCanvas(spec: pages[currentPage].previewSpec, size: 175)
                            .id(pages[currentPage].id)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: .black.opacity(0.24), radius: 22, y: 12)
                            .rotation3DEffect(
                                .degrees(isHovering ? Double(hoverTilt.width * 14) : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .rotation3DEffect(
                                .degrees(isHovering ? Double(-hoverTilt.height * 14) : 0),
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.92).combined(with: .opacity),
                                removal: .scale(scale: 1.05).combined(with: .opacity)
                            ))
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                                        isHovering = true
                                        let nx = (location.x / 175) - 0.5
                                        let ny = (location.y / 175) - 0.5
                                        hoverTilt = CGSize(width: nx, height: ny)
                                    }
                                case .ended:
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isHovering = false
                                        hoverTilt = .zero
                                    }
                                }
                            }
                    }
                    .frame(width: 240, height: 240)

                    // Feature Badge Pill
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                        Text(pages[currentPage].badge)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4.5)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.85))
                    .foregroundStyle(pages[currentPage].accentGradient.first ?? .primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(
                            pages[currentPage].accentGradient.first?.opacity(0.35) ?? Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                    )
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
                .frame(width: 260)

                // Right Copy & Highlights
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pages[currentPage].title)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.primary)

                        Text(pages[currentPage].tagLine)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: pages[currentPage].accentGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    Text(pages[currentPage].description)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Highlights List
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(pages[currentPage].highlights.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(pages[currentPage].accentGradient.first?.opacity(0.15) ?? Color.accentColor.opacity(0.15))
                                        .frame(width: 20, height: 20)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(pages[currentPage].accentGradient.first ?? .accentColor)
                                }

                                Text(item.text)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(.primary.opacity(0.9))
                            }
                        }
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 36)
            .padding(.top, 36)
            .padding(.bottom, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

            Divider()

            // Bottom Navigation Bar
            HStack {
                // Page Indicator Dots
                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentPage = idx
                            }
                        } label: {
                            Capsule()
                                .fill(currentPage == idx ? (pages[currentPage].accentGradient.first ?? Color.accentColor) : Color.secondary.opacity(0.28))
                                .frame(width: currentPage == idx ? 22 : 6, height: 6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Back Button
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentPage -= 1
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                }

                // Primary Action Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                        dismiss()
                        store.notify("Welcome to FolderLab! Ready to customize 📁✨")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentPage == pages.count - 1 ? "Start Styling" : "Continue")
                            .font(.system(size: 12.5, weight: .bold))
                        Image(systemName: currentPage == pages.count - 1 ? "arrow.right.circle.fill" : "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: pages[currentPage].accentGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: pages[currentPage].accentGradient.first?.opacity(0.35) ?? .clear, radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
        }
        .frame(width: 670, height: 425)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
