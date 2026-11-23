import SwiftUI
import AppKit
import Combine

// MARK: - App Icon Appearance Modes (Apple HIG & Icon Composer)

enum AppIconVariant: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"
    case clearLight = "Clear (Light)"
    case clearDark = "Clear (Dark)"
    case tinted = "Tinted"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Default (Light)"
        case .dark: return "Dark"
        case .clearLight: return "Clear (Light)"
        case .clearDark: return "Clear (Dark)"
        case .tinted: return "Tinted"
        }
    }

    var iconName: String {
        switch self {
        case .automatic: return "sparkles.rectangle.stack.fill"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .clearLight: return "sun.and.horizon.fill"
        case .clearDark: return "sparkles"
        case .tinted: return "paintbrush.pointed.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .automatic: return "Follows macOS System Icon & Widget setting live"
        case .light: return "Official Apple Light/Default appearance"
        case .dark: return "Icon Composer Dark Mode rendition"
        case .clearLight: return "Crystal liquid glass for Light mode"
        case .clearDark: return "Dark smoked liquid glass (as shown in photo)"
        case .tinted: return "Icon Composer Tinted Slate rendition"
        }
    }
}

// MARK: - App Icon Manager (Automatic System Sync & Icon Composer Loader)

@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    @Published var selectedVariant: String {
        didSet {
            UserDefaults.standard.set(selectedVariant, forKey: "iconlab_app_icon_variant")
        }
    }

    @Published private(set) var activeResolvedVariant: AppIconVariant = .light
    @Published private(set) var currentSystemTheme: String = "Default"

    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []
    private var imageCache: [String: NSImage] = [:]

    init() {
        self.selectedVariant = UserDefaults.standard.string(forKey: "iconlab_app_icon_variant") ?? AppIconVariant.automatic.rawValue
        let initialTheme = detectSystemTheme()
        self.currentSystemTheme = initialTheme

        let initialTarget: AppIconVariant
        if self.selectedVariant == AppIconVariant.automatic.rawValue {
            initialTarget = resolveSystemTheme(initialTheme)
        } else {
            initialTarget = AppIconVariant(rawValue: self.selectedVariant) ?? .light
        }

        self.activeResolvedVariant = initialTarget
        applyIcon(initialTarget)

        startObserving()
    }

    func setVariant(_ variant: AppIconVariant) {
        selectedVariant = variant.rawValue
        let target: AppIconVariant
        if variant == .automatic {
            target = resolveSystemTheme(currentSystemTheme)
        } else {
            target = variant
        }

        activeResolvedVariant = target
        applyIcon(target)
    }

    func forceApplyCurrentIcon() {
        applyIcon(activeResolvedVariant)
    }

    func sync() {
        let systemTheme = detectSystemTheme()
        if currentSystemTheme != systemTheme {
            currentSystemTheme = systemTheme
        }

        let target: AppIconVariant
        if selectedVariant == AppIconVariant.automatic.rawValue {
            target = resolveSystemTheme(systemTheme)
        } else {
            target = AppIconVariant(rawValue: selectedVariant) ?? .light
        }

        if activeResolvedVariant != target {
            activeResolvedVariant = target
        }
        applyIcon(target)
    }

    private var isDarkAppearance: Bool {
        if let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) {
            return match == .darkAqua
        }
        let styleVal = CFPreferencesCopyValue("AppleInterfaceStyle" as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? String
        return styleVal == "Dark"
    }

    func detectSystemTheme() -> String {
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        // Read AppleIconAppearanceTheme (e.g. RegularDark, RegularLight, ClearDark, ClearLight, TintedDark, TintedLight, Dark, Default)
        let themeVal = (CFPreferencesCopyValue("AppleIconAppearanceTheme" as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? String)
            ?? (CFPreferencesCopyAppValue("AppleIconAppearanceTheme" as CFString, kCFPreferencesAnyApplication) as? String)

        if let theme = themeVal, !theme.isEmpty {
            return theme
        }

        // When AppleIconAppearanceTheme is not set, macOS is on "Default"
        return "Default"
    }

    func resolveSystemTheme(_ theme: String) -> AppIconVariant {
        let t = theme.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Clear mode: Support both Clear Dark and Clear Light (Liquid Glass)
        if t.contains("clear") {
            if t.contains("dark") {
                return .clearDark
            } else if t.contains("light") {
                return .clearLight
            } else {
                return isDarkAppearance ? .clearDark : .clearLight
            }
        }

        // 2. Tinted mode: Matches "tint" or "tinted" or "tinteddark" or "tintedlight"
        if t.contains("tint") {
            return .tinted
        }

        // 3. Dark icon mode:
        // In macOS settings, choosing "Dark" writes "RegularDark" (regular dark appearance) or "Dark".
        if t.contains("dark") {
            return .dark
        }

        // 4. Default / Light icon mode:
        // In macOS settings, choosing "Default" removes the key (nil) or writes "RegularLight" or "Default".
        return .light
    }

    func applyIcon(_ variant: AppIconVariant) {
        if let img = loadIconComposerImage(for: variant) {
            NSApplication.shared.applicationIconImage = img
            NSApp.dockTile.display()
        } else {
            let spec: IconSpec
            switch variant {
            case .light, .automatic: spec = .appIconLight
            case .dark: spec = .appIconDark
            case .clearLight, .clearDark: spec = .appIconClear
            case .tinted: spec = .appIconTinted
            }
            if let memoryIcon = IconExporter.nsImage(spec, pixels: 512) {
                NSApplication.shared.applicationIconImage = memoryIcon
                NSApp.dockTile.display()
            }
        }
    }

    func loadIconComposerImage(for variant: AppIconVariant) -> NSImage? {
        let actual = (variant == .automatic) ? activeResolvedVariant : variant
        let baseName: String
        switch actual {
        case .light, .automatic: baseName = "AppIcon_Light"
        case .dark: baseName = "AppIcon_Dark"
        case .clearLight: baseName = "AppIcon_ClearLight"
        case .clearDark: baseName = "AppIcon_ClearDark"
        case .tinted: baseName = "AppIcon_Tinted"
        }

        if let cached = imageCache[baseName] {
            return cached
        }

        // 1. Check Bundle.module
        if let url = Bundle.module.url(forResource: baseName, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            imageCache[baseName] = img
            return img
        }

        // 2. Check Bundle.main
        if let url = Bundle.main.url(forResource: baseName, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            imageCache[baseName] = img
            return img
        }

        return nil
    }

    private func startObserving() {
        // 1. Real-time AppKit effective appearance observation
        NSApp.publisher(for: \.effectiveAppearance)
            .sink { [weak self] _ in
                Task { @MainActor in self?.sync() }
            }
            .store(in: &cancellables)

        // 2. Observe system theme notifications
        let dist = DistributedNotificationCenter.default()
        let names = [
            "AppleIconAppearanceThemeChangedNotification",
            "AppleInterfaceThemeChangedNotification",
            "AppleColorPreferencesChangedNotification"
        ]
        for name in names {
            let obs = dist.addObserver(
                forName: NSNotification.Name(name),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.sync() }
            }
            observers.append(obs)
        }

        // 3. Observe App becoming active & screen parameter changes
        let actObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.sync() }
        }
        observers.append(actObs)

        let scrObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.sync() }
        }
        observers.append(scrObs)

        // 4. Polling timer (every 1.0s) to react if macOS writes to preferences without a notification
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in self?.sync() }
            }
            .store(in: &cancellables)
    }
}
