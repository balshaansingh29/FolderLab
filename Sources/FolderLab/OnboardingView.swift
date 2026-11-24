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

// MARK: - Welcome & Onboarding View

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding_v1") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var isAnimatingIcon: Bool = false
    @ObservedObject private var store = IconStore.shared

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            badge: "WELCOME TO FOLDERLAB",
            title: "Your Finder Folders, Reimagined.",
            tagLine: "Say goodbye to boring blue folders forever.",
            description: "FolderLab is your bespoke macOS studio to craft, skin, and stamp custom folder icons that give your Mac instant personality and order.",
            systemImage: "paintpalette.fill",
            accentGradient: [Color(hex: "#38EF7D") ?? .green, Color(hex: "#11998E") ?? .blue],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#38EF7D") ?? .green
                s.color2 = Color(hex: "#11998E") ?? .blue
                s.symbolName = "sparkles"
                s.glyphColor = .white
                return s
            }(),
            highlights: [
                ("wand.and.stars", "Instant live preview across all native macOS sizes"),
                ("cursorarrow.rays", "Drag any folder directly to stage and skin in real-time"),
                ("arrow.counterclockwise", "100% reversible anytime with 1-click restore")
            ]
        ),
        OnboardingPage(
            id: 1,
            badge: "DELIGHTFUL INTEGRATION",
            title: "Match Your Desktop Wallpaper.",
            tagLine: "Harmonious themes sampled right from your screen.",
            description: "With 1 click, FolderLab samples the dominant and accent colors of your active macOS wallpaper, crafting tailor-made palettes that melt into your desktop setup.",
            systemImage: "desktopcomputer",
            accentGradient: [Color(hex: "#5B86E5") ?? .blue, Color(hex: "#36D1DC") ?? .cyan],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#36D1DC") ?? .cyan
                s.color2 = Color(hex: "#5B86E5") ?? .blue
                s.symbolName = "desktopcomputer"
                s.liquidGlass = true
                s.glassOpacity = 0.42
                return s
            }(),
            highlights: [
                ("eye.fill", "Supports dynamic light & dark wallpaper shifts automatically"),
                ("slider.horizontal.3", "7 distinct handcrafted themes per wallpaper extraction"),
                ("paintpalette", "Directly copy or apply extracted color swatch dots")
            ]
        ),
        OnboardingPage(
            id: 2,
            badge: "CREATIVE DEPTH",
            title: "Peek Inside & Authentic Textures.",
            tagLine: "Skeuomorphic joy meets modern macOS aesthetics.",
            description: "Tuck documents, code, photos, or vinyl records peeking out from the front flap. Add tactile grain, brushed metal, debossed stamps, or frosted liquid glass.",
            systemImage: "tray.and.arrow.up.fill",
            accentGradient: [Color(hex: "#EA3B7A") ?? .pink, Color(hex: "#FF8A5B") ?? .orange],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#FF8A5B") ?? .orange
                s.color2 = Color(hex: "#EA3B7A") ?? .pink
                s.peekInsideEnabled = true
                s.peekContentType = .code
                s.texture = .leather
                s.textureOpacity = 0.25
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
            badge: "EFFORTLESS WORKFLOW",
            title: "Drag. Style. Done.",
            tagLine: "Customizing your files has never been this satisfying.",
            description: "Drop any folder onto the studio stage, pick your favorite vibe or hit Surprise Me, and click Apply. Your Mac desktop will never look the same.",
            systemImage: "checkmark.seal.fill",
            accentGradient: [Color.purple, Color.blue],
            previewSpec: {
                var s = IconSpec()
                s.color1 = Color(hex: "#A855F7") ?? .purple
                s.color2 = Color(hex: "#3B82F6") ?? .blue
                s.symbolName = "heart.fill"
                s.glyphColor = .white
                return s
            }(),
            highlights: [
                ("arrow.down.doc.fill", "1-Tap Apply to Target Folder with instant desktop refresh"),
                ("arrow.triangle.2.circlepath", "Shareable .folderlab preset files to export and share"),
                ("gearshape", "Custom dock app icons in Clear, Dark, Light and Tinted")
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Main Content Body
            HStack(spacing: 36) {
                // Left interactive preview stage
                VStack(spacing: 16) {
                    ZStack {
                        // Ambient radial glow behind preview
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: pages[currentPage].accentGradient.map { $0.opacity(0.35) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 220)
                            .blur(radius: 28)

                        // 3D-styled interactive icon preview
                        IconCanvas(spec: pages[currentPage].previewSpec, size: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: .black.opacity(0.28), radius: 20, y: 12)
                            .scaleEffect(isAnimatingIcon ? 1.04 : 0.98)
                            .rotationEffect(.degrees(isAnimatingIcon ? 2.5 : -2.5))
                            .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: isAnimatingIcon)
                    }
                    .frame(width: 240, height: 240)
                    .onAppear {
                        isAnimatingIcon = true
                    }

                    // Live badge
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(pages[currentPage].badge)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(pages[currentPage].accentGradient.first ?? .primary)
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
                }
                .frame(width: 260)

                // Right copy & feature highlights
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pages[currentPage].title)
                            .font(.system(size: 24, weight: .bold))
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

                    // Key highlights list
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(Array(pages[currentPage].highlights.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(pages[currentPage].accentGradient.first ?? .accentColor)
                                    .frame(width: 18, height: 18)

                                Text(item.text)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(.primary.opacity(0.88))
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

            Divider()

            // Bottom Navigation Footer
            HStack {
                // Page indicator dots
                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        Circle()
                            .fill(currentPage == idx ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: currentPage == idx ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }

                Spacer()

                // Skip / Back button
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            currentPage -= 1
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                }

                // Primary Next / Get Started button
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
                            .font(.system(size: 13, weight: .semibold))
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
                    .shadow(color: pages[currentPage].accentGradient.first?.opacity(0.3) ?? .clear, radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
        }
        .frame(width: 660, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
