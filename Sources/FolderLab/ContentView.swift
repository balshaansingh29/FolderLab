import SwiftUI
import AppKit

// MARK: - Icon Store & State

@MainActor
final class IconStore: ObservableObject {
    static let shared = IconStore()
    @Published var spec = IconSpec()
    @Published var statusMessage = ""
    @Published var isStatusError = false
    @Published var showStatusToast = false
    @Published var canvasBackdrop: CanvasBackdrop = .studio
    @Published var canvasScale: CGFloat = 1.0

    // MARK: - Undo & Redo (v0.2)
    private var undoStack: [IconSpec] = []
    private var redoStack: [IconSpec] = []
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    func snapshotUndo() {
        undoStack.append(spec)
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()
        updateUndoRedo()
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(spec)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec = prev
        }
        updateUndoRedo()
        notify("Undo")
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(spec)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec = next
        }
        updateUndoRedo()
        notify("Redo")
    }

    private func updateUndoRedo() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - Recents History Shelf (v0.2)
    @Published var recentSpecs: [IconSpec] = []

    func addToRecents(_ specToAdd: IconSpec) {
        recentSpecs.removeAll { $0 == specToAdd }
        recentSpecs.insert(specToAdd, at: 0)
        if recentSpecs.count > 10 {
            recentSpecs.removeLast()
        }
        saveRecents()
    }

    func loadRecents() {
        if let data = UserDefaults.standard.data(forKey: "folderlab_recents"),
           let presets = try? JSONDecoder().decode([FolderLabPreset].self, from: data) {
            self.recentSpecs = presets.map { IconSpec.fromPreset($0) }
        }
    }

    private func saveRecents() {
        let presets = recentSpecs.map { $0.toPreset(name: "Recent") }
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "folderlab_recents")
        }
    }

    // MARK: - Smart Folder Suggestions (v0.2)
    @Published var activeSuggestion: FolderSuggestion? = nil

    func checkSmartSuggestion(for url: URL) {
        if let suggestion = SmartFolderSuggester.suggest(for: url) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                self.activeSuggestion = suggestion
            }
        }
    }

    func applySuggestion(_ suggestion: FolderSuggestion) {
        snapshotUndo()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec.color1 = suggestion.color1
            spec.color2 = suggestion.color2
            if let c3 = suggestion.color3 {
                spec.useThreeColorGradient = true
                spec.color3 = c3
            } else {
                spec.useThreeColorGradient = false
            }
            spec.texture = suggestion.texture
            spec.cornerBadge = suggestion.badge
            spec.glyphKind = .symbol
            spec.symbolName = suggestion.symbolName
            activeSuggestion = nil
        }
        addToRecents(spec)
        notify("Applied smart '\(suggestion.title)' style! 🪄")
    }

    init() {
        loadRecents()
    }

    private var toastWorkItem: DispatchWorkItem?

    func applyStyle(_ style: IconStyle) {
        snapshotUndo()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec = IconSpec.styled(style, keepingGlyphFrom: spec)
        }
        notify("Applied style: \(style.rawValue)")
    }

    func applyAppIconVariant(_ variant: AppIconVariant) {
        let chosen: IconSpec
        switch variant {
        case .light, .automatic: chosen = .appIconLight
        case .dark: chosen = .appIconDark
        case .clearLight, .clearDark: chosen = .appIconClear
        case .tinted: chosen = .appIconTinted
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec = chosen
        }
        AppIconManager.shared.setVariant(variant)
        notify("Applied \(variant.displayName) App Icon 🧪")
    }

    func randomize() {
        snapshotUndo()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            spec = IconSpec.random()
        }
        notify("Generated surprise design! ✨")
    }

    func resetToDefaults() {
        snapshotUndo()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec = IconSpec()
        }
        notify("Reset to default style")
    }

    func copyToClipboard() {
        addToRecents(spec)
        let msg = IconExporter.copyToClipboard(spec)
        let isErr = msg.contains("Failed")
        notify(msg, isError: isErr)
    }

    func exportPNG() {
        addToRecents(spec)
        let msg = IconExporter.savePNG(spec)
        let isErr = msg.contains("failed") || msg.contains("Could not")
        notify(msg, isError: isErr)
    }

    func exportICNS() {
        addToRecents(spec)
        let msg = IconExporter.saveICNS(spec)
        let isErr = msg.contains("failed") || msg.contains("Could not")
        notify(msg, isError: isErr)
    }

    func exportAppIconSet() {
        let msg = IconExporter.saveAppIconSet(spec)
        let isErr = msg.contains("failed")
        notify(msg, isError: isErr)
    }

    func exportIconComposer() {
        let msg = IconExporter.saveIconComposerDocument(spec)
        let isErr = msg.contains("failed") || msg.contains("Could not")
        notify(msg, isError: isErr)
    }

    @Published var lastTargetFolderURL: URL? = nil

    func apply(to url: URL) {
        lastTargetFolderURL = url
        addToRecents(spec)
        checkSmartSuggestion(for: url)
        let (ok, msg) = IconExporter.apply(spec: spec, to: url)
        notify(msg, isError: !ok)
    }

    func renameFolderDirectly(url: URL, newName: String) {
        do {
            let newURL = try UnicodeStyler.renameFolder(at: url, newName: newName)
            lastTargetFolderURL = newURL
            notify("Renamed folder to '\(newName)' in Finder! 🏷️")
        } catch {
            notify("Rename failed: \(error.localizedDescription)", isError: true)
        }
    }

    func applyToItems() {
        let msg = IconExporter.applyToItems(spec)
        let isErr = msg.contains("failed")
        notify(msg, isError: isErr)
    }

    func resetItems() {
        let msg = IconExporter.resetItems()
        let isErr = msg.contains("failed")
        notify(msg, isError: isErr)
    }

    func applyBatchSubfolders() {
        let msg = IconExporter.applyToSubfolders(spec)
        let isErr = msg.contains("failed") || msg.contains("Could not")
        notify(msg, isError: isErr)
    }

    func resetBatchSubfolders() {
        let msg = IconExporter.resetSubfolders()
        let isErr = msg.contains("failed") || msg.contains("Could not")
        notify(msg, isError: isErr)
    }

    func exportThemePreset() {
        let msg = PresetManager.exportPreset(spec: spec, defaultName: "FolderTheme")
        let isErr = msg.contains("Failed")
        notify(msg, isError: isErr)
    }

    func importThemePreset() {
        let (newSpec, msg) = PresetManager.importPreset()
        if let newSpec = newSpec {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                spec = newSpec
            }
        }
        let isErr = msg.contains("Failed")
        notify(msg, isError: isErr)
    }

    func applyFinderTag(_ tag: FinderTagColor) {
        snapshotUndo()
        spec.selectedFinderTag = tag
        spec.syncFinderTag = true
        spec.color1 = tag.primaryColor
        spec.color2 = tag.secondaryColor
        spec.useGradient = true
        notify("Applied Apple \(tag.rawValue) tag theme! 🏷️")
    }

    func loadCustomImage(from url: URL) {
        snapshotUndo()
        guard let data = try? Data(contentsOf: url), let _ = NSImage(data: data) else {
            notify("Could not load image file.", isError: true)
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            spec.customImageData = data
            spec.customImageName = url.lastPathComponent
            spec.glyphKind = .customImage
        }
        notify("Loaded custom stamp image '\(url.lastPathComponent)'! 🖼️")
    }

    func notify(_ message: String, isError: Bool = false) {
        guard message != "Cancelled." && message != "PNG export cancelled." && message != "ICNS export cancelled." else {
            return
        }
        statusMessage = message
        isStatusError = isError
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showStatusToast = true
        }

        toastWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.showStatusToast = false
            }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: item)
    }
}

// MARK: - Canvas Backdrop Modes (Free vs Pro)

enum CanvasBackdrop: String, CaseIterable, Identifiable {
    case studio = "Studio Dark"
    case light = "Studio Light"
    case checkerboard = "Alpha Grid"
    case desktop = "macOS Wallpaper"
    case dock = "Dock Mode"
    case grid = "Blueprint Grid"

    var id: String { rawValue }


    var iconName: String {
        switch self {
        case .studio: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .checkerboard: return "square.grid.3x3.topleft.filled"
        case .desktop: return "display"
        case .dock: return "menubar.dock.rectangle"
        case .grid: return "squareshape.split.3x3"
        }
    }
}


// MARK: - Screen Eyedropper

@MainActor
private enum Eyedropper {
    static var sampler: NSColorSampler?

    static func pick(_ completion: @escaping (Color) -> Void) {
        let s = NSColorSampler()
        sampler = s
        s.show { nsColor in
            Task { @MainActor in sampler = nil }
            if let nsColor {
                completion(Color(nsColor: nsColor))
            }
        }
    }
}

// MARK: - Navigation Tabs

enum InspectorTab: String, CaseIterable, Identifiable {
    case presets = "Themes"
    case canvas = "Colors"
    case glyph = "Stamp"
    case textTab = "Text"
    case export = "Apply"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .presets: return "folder.fill"
        case .canvas: return "paintpalette.fill"
        case .glyph: return "sparkles"
        case .textTab: return "textformat"
        case .export: return "arrow.down.doc.fill"
        }
    }
}


// MARK: - Main ContentView

enum ActiveAppSheet: String, Identifiable {
    case settings
    case update
    var id: String { rawValue }
}

struct ContentView: View {
    @ObservedObject private var store = IconStore.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var activeTab: InspectorTab = .presets
    @State private var activeSheet: ActiveAppSheet? = nil

    private var settingsSheetBinding: Binding<Bool> {
        Binding(
            get: { activeSheet == .settings },
            set: { isShown in
                activeSheet = isShown ? .settings : nil
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main Stage Preview Area
            StudioCanvasView(store: store, showSettingsSheet: settingsSheetBinding)
                .frame(minWidth: 540)

            // Vertical subtle divider
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.6))
                .frame(width: 1)

            // Right Inspector Panel
            InspectorPanelView(store: store, activeTab: $activeTab)
                .frame(width: 420)
        }
        .frame(minWidth: 1060, minHeight: 740)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .update:
                UpdateSheetView()
            }
        }
        .onChange(of: updateManager.isUpdateSheetPresented) { presented in
            if presented {
                activeSheet = .update
            } else if activeSheet == .update {
                activeSheet = nil
            }
        }
        .onChange(of: activeSheet) { current in
            if current != .update {
                updateManager.isUpdateSheetPresented = false
            }
        }
    }
}

// MARK: - Refined Apple HUD Toast (Floats at bottom center above preview strip)

struct StatusToastView: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 9) {
            if isError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 13, weight: .bold))
            } else if message.contains("Surprise") || message.contains("surprise") {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.yellow)
                    .font(.system(size: 13, weight: .bold))
            } else if message.contains("Copied") {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 13, weight: .semibold))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                    .font(.system(size: 13, weight: .bold))
            }

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
        }
    }
}

// MARK: - Studio Canvas View

struct StudioCanvasView: View {
    @ObservedObject var store: IconStore
    @ObservedObject private var updateManager = UpdateManager.shared
    @Binding var showSettingsSheet: Bool
    @State private var hoverTilt = CGSize.zero
    @State private var isHovering = false
    @State private var surpriseRotation: Double = 0
    @State private var isDropTargeted: Bool = false

    var body: some View {
        ZStack {
            // Backdrop environment
            BackdropBackgroundView(mode: store.canvasBackdrop)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top canvas toolbar
                canvasTopToolbar
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                // Smart Folder Suggestion Banner (v0.2)
                if let suggestion = store.activeSuggestion {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 14, weight: .bold))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Smart Suggestion:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(suggestion.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Text(suggestion.reason)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Apply Style") {
                            store.applySuggestion(suggestion)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button {
                            withAnimation { store.activeSuggestion = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.yellow.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 10)

                // Main Stage Icon Display with interactive 3D tilt
                mainIconStage

                Spacer(minLength: 10)

                // Multi-Scale Preview Strip or Dock Mode Preview
                if store.canvasBackdrop == .dock {
                    SimulatedDockView(spec: store.spec)
                        .padding(.bottom, 20)
                } else {
                    MultiScaleStripView(spec: store.spec)
                        .padding(.bottom, 20)
                }
            }
        }
        // Floating HUD status toast positioned in lower viewport — NEVER covers toolbar or Surprise Me button!
        .overlay(alignment: .bottom) {
            if store.showStatusToast {
                StatusToastView(message: store.statusMessage, isError: store.isStatusError)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .padding(.bottom, 115)
            }
        }
    }

    private var canvasTopToolbar: some View {
        HStack(spacing: 8) {
            // App Branding: Fixed size & layoutPriority prevents text truncation in windowed mode
            HStack(spacing: 8) {
                IconCanvas(spec: .appIconLight, size: 24)
                    .shadow(color: .blue.opacity(0.35), radius: 3, y: 1)

                Text("FolderLab")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)

            Spacer(minLength: 8)

            // Backdrop Selector
            HStack(spacing: 2) {
                ForEach(CanvasBackdrop.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.canvasBackdrop = mode
                        }
                    } label: {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(store.canvasBackdrop == mode ? Color.primary : Color.secondary)
                            .frame(width: 25, height: 24)
                            .background {
                                if store.canvasBackdrop == mode {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color.white.opacity(0.18))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(mode.rawValue)
                }
            }
            .padding(2)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
            )

            // Surprise me generator with animated spin feedback
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    surpriseRotation += 360
                }
                store.randomize()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .rotationEffect(.degrees(surpriseRotation))
                    Text("Surprise")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Generate an inspiring randomized design")

            // Undo Button (v0.2)
            Button {
                store.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(store.canUndo ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!store.canUndo)
            .keyboardShortcut("z", modifiers: .command)
            .help("Undo (⌘Z)")

            // Redo Button (v0.2)
            Button {
                store.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(store.canRedo ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!store.canRedo)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .help("Redo (⇧⌘Z)")

            // Quick Copy PNG Button
            Button {
                store.copyToClipboard()
            } label: {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 26, height: 26)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .help("Copy 1024×1024 icon to clipboard")

            // Update Available Badge / Pill
            if case .updateAvailable(let release) = updateManager.state {
                Button {
                    updateManager.isUpdateSheetPresented = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Update \(release.tagName)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(Color.blue.opacity(0.18), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("New version available: \(release.tagName) (Click to update)")
            }

            // Settings Button
            Button {
                showSettingsSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 26, height: 26)

                    if case .updateAvailable = updateManager.state {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 7, height: 7)
                            .offset(x: -2, y: 2)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Settings (⌘,)")
        }
    }

    private var mainIconStage: some View {
        let canvasSize: CGFloat = 340
        return VStack(spacing: 14) {
            ZStack {
                IconCanvas(spec: store.spec, size: canvasSize)
                    .rotation3DEffect(
                        .degrees(isHovering ? Double(hoverTilt.width * 14) : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(isHovering ? Double(-hoverTilt.height * 14) : 0),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                isHovering = true
                                let nx = (location.x / canvasSize) - 0.5
                                let ny = (location.y / canvasSize) - 0.5
                                hoverTilt = CGSize(width: nx, height: ny)
                            }
                        case .ended:
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isHovering = false
                                hoverTilt = .zero
                            }
                        }
                    }

                // Drop target highlight overlay
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                        .background(Color.accentColor.opacity(0.14).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)))
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "folder.badge.gearshape.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.accentColor)
                                Text("Drop Folder Here to Apply!")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                }
            }
            .frame(width: canvasSize + 40, height: canvasSize + 40)
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            var isDir: ObjCBool = false
                            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                                let tags = IconExporter.getFinderTags(for: url)
                                if let firstTag = tags.first, let matched = FinderTagColor.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(firstTag) == .orderedSame }) {
                                    store.applyFinderTag(matched)
                                }
                                store.apply(to: url)
                            } else {
                                let ext = url.pathExtension.lowercased()
                                if ["png", "jpg", "jpeg", "svg", "webp", "icns", "tiff", "gif"].contains(ext) {
                                    store.loadCustomImage(from: url)
                                } else {
                                    store.notify("Please drop a folder to skin, or an image to stamp.", isError: true)
                                }
                            }
                        }
                    }
                }
                return true
            }

            // Quick Action Buttons directly below Folder Preview
            HStack(spacing: 12) {
                Button {
                    store.applyToItems()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.gearshape.fill")
                        Text("Apply to Folder…")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
                .help("Choose any folder on your Mac to give this design")

                Button {
                    store.resetItems()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Folder")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Restore default macOS blue folder icon")
            }

            Text(isDropTargeted ? "Release to customize folder icon in Finder!" : "📁 Drag & drop any folder from Finder onto the canvas to customize instantly")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
        }
    }
}

// MARK: - Multi-Scale Preview Strip

struct MultiScaleStripView: View {
    let spec: IconSpec

    private let scales: [(String, CGFloat, CGFloat)] = [
        ("256px", 256, 68),
        ("128px", 128, 48),
        ("64px", 64, 34),
        ("32px", 32, 22),
        ("16px", 16, 16)
    ]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(scales, id: \.0) { item in
                VStack(spacing: 8) {
                    ZStack {
                        IconCanvas(spec: spec, size: item.2)
                    }
                    .frame(width: 72, height: 72)

                    Text(item.0)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.65))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        }
    }
}

// MARK: - Simulated macOS Dock View

struct SimulatedDockView: View {
    let spec: IconSpec

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 14) {
                // Finder
                dockApp(name: "Finder", icon: "face.smiling.fill", colors: [Color(hex: "#2980B9")!, Color(hex: "#6DD5FA")!])
                // Safari
                dockApp(name: "Safari", icon: "safari.fill", colors: [Color(hex: "#0052D4")!, Color(hex: "#4364F7")!])
                // Messages
                dockApp(name: "Messages", icon: "message.fill", colors: [Color(hex: "#11998E")!, Color(hex: "#38EF7D")!])

                // Custom User App Icon with active dot indicator!
                VStack(spacing: 4) {
                    IconCanvas(spec: spec, size: 56)
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 4, height: 4)
                }
                .help("Your custom icon in the macOS Dock")

                // Music
                dockApp(name: "Music", icon: "music.note", colors: [Color(hex: "#FF416C")!, Color(hex: "#FF4B2B")!])
                // Terminal
                dockApp(name: "Terminal", icon: "terminal.fill", colors: [Color(hex: "#232526")!, Color(hex: "#414345")!])
                // System Settings
                dockApp(name: "Settings", icon: "gearshape.2.fill", colors: [Color(hex: "#8E9EAB")!, Color(hex: "#EEF2F3")!], iconColor: .black.opacity(0.7))

                // Dock Divider
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 48)
                    .padding(.horizontal, 2)

                // Trash
                dockApp(name: "Trash", icon: "trash.fill", colors: [Color(hex: "#757F9A")!, Color(hex: "#D7DDE8")!], iconColor: .black.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            }

            HStack(spacing: 6) {
                Image(systemName: "menubar.dock.rectangle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
                Text("Live macOS Dock Simulation")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func dockApp(name: String, icon: String, colors: [Color], iconColor: Color = .white) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Spacer().frame(height: 4)
        }
        .help(name)
    }
}

// MARK: - Backdrop Background View

struct BackdropBackgroundView: View {
    let mode: CanvasBackdrop

    var body: some View {
        switch mode {
        case .studio:
            ZStack {
                Color(hex: "#121316")!
                RadialGradient(
                    colors: [Color.white.opacity(0.06), Color.clear],
                    center: .center,
                    startRadius: 80,
                    endRadius: 500
                )
            }
        case .desktop:
            LinearGradient(
                colors: [
                    Color(hex: "#1A2A6C")!,
                    Color(hex: "#B21F1F")!,
                    Color(hex: "#FDBB2D")!
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dock:
            LinearGradient(
                colors: [Color(hex: "#0F2027")!, Color(hex: "#203A43")!, Color(hex: "#2C5364")!],
                startPoint: .top,
                endPoint: .bottom
            )
        case .light:
            ZStack {
                Color(hex: "#F5F6F8")!
                RadialGradient(
                    colors: [Color.white, Color(hex: "#E5E7EB")!],
                    center: .center,
                    startRadius: 100,
                    endRadius: 600
                )
            }
        case .grid:
            ZStack {
                Color(hex: "#0F172A")!
                Canvas { context, size in
                    let step: CGFloat = 24
                    for x in stride(from: 0, to: size.width, by: step) {
                        for y in stride(from: 0, to: size.height, by: step) {
                            let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.cyan.opacity(0.18)))
                        }
                    }
                }
            }
        case .checkerboard:
            Canvas { context, size in
                let step: CGFloat = 16
                var dark = false
                for y in stride(from: 0, to: size.height, by: step) {
                    for x in stride(from: 0, to: size.width, by: step) {
                        let rect = CGRect(x: x, y: y, width: step, height: step)
                        let color = dark ? Color(nsColor: .darkGray).opacity(0.2) : Color.clear
                        context.fill(Path(rect), with: .color(color))
                        dark.toggle()
                    }
                    dark.toggle()
                }
            }
            .background(Color(nsColor: .underPageBackgroundColor))
        }
    }
}

// MARK: - Inspector Panel View

struct InspectorPanelView: View {
    @ObservedObject var store: IconStore
    @Binding var activeTab: InspectorTab

    var body: some View {
        VStack(spacing: 0) {

            // Top Tab Selector Bar
            HStack(spacing: 2) {
                ForEach(InspectorTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 11, weight: activeTab == tab ? .bold : .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: activeTab == tab ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if activeTab == tab {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color(nsColor: .controlAccentColor))
                                    .shadow(color: Color(nsColor: .controlAccentColor).opacity(0.35), radius: 3, y: 1)
                            } else {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.clear)
                            }
                        }
                        .foregroundStyle(activeTab == tab ? Color.white : Color.secondary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.65))

            Divider()

            // Tab Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 18) {
                    switch activeTab {
                    case .presets:
                        PresetsInspectorTab(store: store)
                    case .canvas:
                        CanvasInspectorTab(store: store)
                    case .glyph:
                        GlyphInspectorTab(store: store)
                    case .textTab:
                        TextInspectorTab(store: store)
                    case .export:
                        ExportInspectorTab(store: store)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Presets Tab (Includes Light, Dark, Clear, Tinted App Icons)

struct PresetsInspectorTab: View {
    @ObservedObject var store: IconStore
    @State private var selectedTheme: IconStyle? = nil

    private let gradientPalettes: [(String, String, String)] = [
        ("Hyper Blue", "#36D1DC", "#5B86E5"),
        ("Sunset Glow", "#FF8A5B", "#EA3B7A"),
        ("Neon Purple", "#8E54E9", "#4776E6"),
        ("Apple Mint", "#43E97B", "#38F9D7"),
        ("Solar Flare", "#F7971E", "#FFD200"),
        ("Titanium Slate", "#485563", "#29323C"),
        ("Cotton Candy", "#FC5C7D", "#6A82FB"),
        ("Nordic Ice", "#30CFD0", "#330867"),
        ("Cyber Emerald", "#11998E", "#38EF7D"),
        ("Ruby Velvet", "#ED213A", "#93291E"),
        ("Luxury Gold", "#FFE000", "#799F0C"),
        ("Deep Obsidian", "#232526", "#414345")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Creative Tools ("Surprise Me" & "Reset Default")
            InspectorCard {
                InspectorSectionHeader(
                    title: "Creative Tools",
                    subtitle: "Instant smart variations & quick reset",
                    icon: "sparkles",
                    iconColor: .yellow
                )

                HStack(spacing: 12) {
                    Button {
                        selectedTheme = nil
                        store.randomize()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Surprise Me")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedTheme = nil
                        store.resetToDefaults()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Default")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Recently Used Styles Shelf (v0.2)
            if !store.recentSpecs.isEmpty {
                InspectorCard {
                    HStack {
                        InspectorSectionHeader(
                            title: "Recently Applied",
                            subtitle: "Quick restore previous folder styles",
                            icon: "clock.arrow.circlepath",
                            iconColor: .blue
                        )

                        Spacer()

                        Button("Clear") {
                            withAnimation {
                                store.recentSpecs.removeAll()
                                UserDefaults.standard.removeObject(forKey: "folderlab_recents")
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(store.recentSpecs.prefix(8).enumerated()), id: \.offset) { idx, recent in
                                Button {
                                    store.snapshotUndo()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        store.spec = recent
                                    }
                                    store.notify("Loaded recent style #\(idx + 1)")
                                } label: {
                                    VStack(spacing: 3) {
                                        IconCanvas(spec: recent, size: 36)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                                        Text("#\(idx + 1)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(4)
                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                                .help("Restore this recent folder style")
                            }
                        }
                    }
                }
            }

            // Folder Themes Grid
            InspectorCard {
                InspectorSectionHeader(
                    title: "Folder Themes",
                    subtitle: "Handcrafted styles, vibrant gradients & luxury finishes",
                    icon: "folder.fill",
                    iconColor: .accentColor
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(IconStyle.allCases) { style in
                        PresetCardButton(style: style, isSelected: selectedTheme == style) {
                            selectedTheme = style
                            store.applyStyle(style)
                        }
                    }
                }
            }

            // Tactile Surface Textures Grid
            InspectorCard {
                InspectorSectionHeader(
                    title: "Tactile Surface Textures",
                    subtitle: "Visual finishes: carbon fiber, brushed metal, tactile grain & more",
                    icon: "square.grid.3x3.topleft.filled",
                    iconColor: .purple
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(SurfaceTexture.allCases) { tex in
                        TextureCardButton(
                            texture: tex,
                            isSelected: store.spec.texture == tex,
                            folderColor1: store.spec.color1,
                            folderColor2: store.spec.color2
                        ) {
                            store.snapshotUndo()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                store.spec.texture = tex
                                if tex != .none && store.spec.textureOpacity < 0.10 {
                                    store.spec.textureOpacity = 0.22
                                }
                            }
                        }
                    }
                }

                if store.spec.texture != .none {
                    ModernSlider(
                        title: "Texture Contrast / Opacity",
                        value: $store.spec.textureOpacity,
                        range: 0.05...0.60,
                        format: "%.0f",
                        multiplier: 100,
                        unit: "%"
                    )
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            // Designer Color Gradients
            InspectorCard {
                InspectorSectionHeader(
                    title: "Designer Gradients",
                    subtitle: "Harmonious two-tone color transitions",
                    icon: "paintpalette.fill",
                    iconColor: .orange
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(gradientPalettes, id: \.0) { item in
                        let isGradSelected = store.spec.useGradient &&
                            !store.spec.useThreeColorGradient &&
                            store.spec.color1.hexString.lowercased() == item.1.lowercased() &&
                            store.spec.color2.hexString.lowercased() == item.2.lowercased()

                        GradientCardButton(
                            name: item.0,
                            hex1: item.1,
                            hex2: item.2,
                            isSelected: isGradSelected
                        ) {
                            if let c1 = Color(hex: item.1), let c2 = Color(hex: item.2) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.spec.color1 = c1
                                    store.spec.color2 = c2
                                    store.spec.useGradient = true
                                    store.spec.useThreeColorGradient = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PresetCardButton: View {
    let style: IconStyle
    var isSelected: Bool = false
    let action: () -> Void

    private var gradientColors: [Color] {
        switch style {
        case .bigSur: return [Color.white, Color(hex: "#DDE2EC")!]
        case .gradient: return [Color(hex: "#36D1DC")!, Color(hex: "#5B86E5")!]
        case .dark: return [Color(hex: "#3A3D45")!, Color(hex: "#141518")!]
        case .liquidGlass: return [Color(white: 0.28).opacity(0.85), Color(white: 0.10).opacity(0.95)]
        case .tintedMode: return [Color(hex: "#1B1D26")!, Color(hex: "#0B0C10")!]
        case .cyber: return [Color(hex: "#FF007F")!, Color(hex: "#7928CA")!]
        case .sunset: return [Color(hex: "#FF7E5F")!, Color(hex: "#FEB47B")!]
        case .emerald: return [Color(hex: "#11998E")!, Color(hex: "#38EF7D")!]
        case .gold: return [Color(hex: "#FFE000")!, Color(hex: "#799F0C")!]
        case .ruby: return [Color(hex: "#ED213A")!, Color(hex: "#93291E")!]
        case .folder: return [Color(hex: "#6CD0FF")!, Color(hex: "#2F9DF4")!]
        case .glyphOnly: return [Color(hex: "#FF9F0A")!, Color(hex: "#FF375F")!]
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(style.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                            .foregroundStyle(.primary)
                    }

                    Text(styleDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var styleDescription: String {
        switch style {
        case .bigSur: return "Apple native light"
        case .gradient: return "Vivid dynamic"
        case .dark: return "Pro Space Black"
        case .liquidGlass: return "Liquid glass & specular rim"
        case .tintedMode: return "Obsidian with neon glow"
        case .cyber: return "Electric neon"
        case .sunset: return "Warm tangerine"
        case .emerald: return "Mint glass"
        case .gold: return "Champagne metallic"
        case .ruby: return "Vivid crimson"
        case .folder: return "macOS Finder"
        case .glyphOnly: return "Transparent alpha"
        }
    }
}

// MARK: - Texture Card Button (Visual Texture Preview)

struct TextureCardButton: View {
    let texture: SurfaceTexture
    let isSelected: Bool
    let folderColor1: Color
    let folderColor2: Color
    let action: () -> Void

    private var textureDescription: String {
        switch texture {
        case .none: return "Smooth satin clean"
        case .carbon: return "Woven crosshatch"
        case .brushed: return "Anodized horizontal"
        case .leather: return "Tactile pebble grain"
        case .grid: return "Precision dot array"
        case .stripes: return "45° tactile ribs"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                // Live preview swatch showing folder color + texture!
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [folderColor1, folderColor2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if texture != .none {
                        FolderTextureOverlay(texture: texture, opacity: 0.65)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(texture.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(textureDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gradient Card Button

struct GradientCardButton: View {
    let name: String
    let hex1: String
    let hex2: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: hex1) ?? .blue, Color(hex: hex2) ?? .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(hex1) → \(hex2)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Canvas & Finish Tab

struct CanvasInspectorTab: View {
    @ObservedObject var store: IconStore

    private let presetAngles: [Double] = [0, 45, 90, 135, 180, 270]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Folder Color Fill
            InspectorCard {
                InspectorSectionHeader(
                    title: "Folder Colors",
                    subtitle: "Solid tone or high-resolution gradient",
                    icon: "paintpalette.fill",
                    iconColor: .accentColor
                )

                Toggle("Enable Gradient", isOn: $store.spec.useGradient)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .medium))

                if store.spec.useGradient {
                    Toggle("3-Color Multi-Stop Gradient (v0.2)", isOn: $store.spec.useThreeColorGradient)
                        .toggleStyle(.switch)
                        .font(.system(size: 11, weight: .medium))

                    if store.spec.useThreeColorGradient {
                        ColorRowModern(title: "Mid Gradient Color", color: $store.spec.color3)
                    }
                }

                ColorRowModern(title: store.spec.useGradient ? "Front Flap Color" : "Folder Color", color: $store.spec.color1)

                // Native macOS Tag Colors
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentColor)
                        Text("Apple Finder Tag Colors")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Toggle("Write Tag to Finder", isOn: $store.spec.syncFinderTag)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    HStack(spacing: 8) {
                        ForEach(FinderTagColor.allCases) { tag in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    store.applyFinderTag(tag)
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [tag.primaryColor, tag.secondaryColor],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().strokeBorder(store.spec.selectedFinderTag == tag ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .shadow(color: tag.primaryColor.opacity(0.4), radius: 2, y: 1)
                            }
                            .buttonStyle(.plain)
                            .help("Apply Apple \(tag.rawValue) Tag Palette")
                        }
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if store.spec.useGradient {
                    ColorRowModern(title: "Bottom Gradient Color", color: $store.spec.color2)

                    // Angle presets
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(presetAngles, id: \.self) { angle in
                                Button("\(Int(angle))°") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        store.spec.gradientAngle = angle
                                    }
                                }
                                .font(.system(size: 11, weight: store.spec.gradientAngle == angle ? .bold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background {
                                    if store.spec.gradientAngle == angle {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(nsColor: .controlAccentColor).opacity(0.25))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(nsColor: .controlBackgroundColor))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ModernSlider(
                            title: "Gradient Angle",
                            value: $store.spec.gradientAngle,
                            range: 0...360,
                            format: "%.0f",
                            unit: "°",
                            onReset: { store.spec.gradientAngle = 90 }
                        )
                    }

                    // Swap colors button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            let tmp = store.spec.color1
                            store.spec.color1 = store.spec.color2
                            store.spec.color2 = tmp
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Swap Start & End Colors")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }

            // Folder Finishes & Tactile Details
            InspectorCard {
                InspectorSectionHeader(
                    title: "Folder Details & Lighting",
                    subtitle: "Flap highlight rim, liquid glass & drop shadow",
                    icon: "sparkles",
                    iconColor: .cyan
                )

                HStack {
                    Toggle("Front Flap Highlight Rim", isOn: $store.spec.innerRim)
                        .toggleStyle(.switch)
                        .font(.system(size: 12, weight: .medium))
                }

                HStack {
                    Toggle("Finder Drop Shadow", isOn: $store.spec.dropShadow)
                        .toggleStyle(.switch)
                        .font(.system(size: 12, weight: .medium))
                }

                // Liquid Glass Material (iOS 18+ / macOS Sequoia)
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Liquid Glass Folder Skin 🧊", isOn: Binding(
                        get: { store.spec.liquidGlass },
                        set: { val in
                            store.spec.liquidGlass = val
                            if val {
                                store.spec.innerRim = true
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .semibold))

                    if store.spec.liquidGlass {
                        VStack(spacing: 8) {
                            ModernSlider(
                                title: "Glass Translucency",
                                value: $store.spec.glassOpacity,
                                range: 0.15...0.85,
                                format: "%.0f",
                                multiplier: 100,
                                unit: "%",
                                onReset: { store.spec.glassOpacity = 0.45 }
                            )
                            ModernSlider(
                                title: "Specular Rim Bevel",
                                value: $store.spec.specularRimWidth,
                                range: 0.003...0.015,
                                format: "%.1f",
                                multiplier: 500,
                                unit: " pt",
                                onReset: { store.spec.specularRimWidth = 0.008 }
                            )
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Glyph / Symbol Tab

struct GlyphInspectorTab: View {
    @ObservedObject var store: IconStore
    @State private var symbolSearchQuery = ""
    @State private var selectedCategory: SymbolCategory = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InspectorCard {
                InspectorSectionHeader(
                    title: "Glyph Mode",
                    subtitle: "Choose between SF Symbol iconography, monograms, or custom stamps",
                    icon: "star.fill",
                    iconColor: .accentColor
                )

                Picker("Type", selection: $store.spec.glyphKind) {
                    ForEach(GlyphKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            if store.spec.glyphKind == .customImage {
                // Custom Image Stamp (Feature 4)
                InspectorCard {
                    InspectorSectionHeader(
                        title: "Custom Image Stamp",
                        subtitle: "Stamp any PNG, SVG, or graphic onto the folder flap",
                        icon: "photo.badge.plus",
                        iconColor: .indigo
                    )

                    if let data = store.spec.customImageData, let nsImg = NSImage(data: data) {
                        HStack(spacing: 12) {
                            Image(nsImage: nsImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .padding(4)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.spec.customImageName ?? "Custom Image")
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                Text("\(Int(nsImg.size.width)) × \(Int(nsImg.size.height)) px")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Remove") {
                                withAnimation {
                                    store.spec.customImageData = nil
                                    store.spec.customImageName = nil
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        Toggle("Tint to Theme Foreground Color", isOn: $store.spec.customImageTinted)
                            .toggleStyle(.switch)
                            .font(.system(size: 12, weight: .medium))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.accentColor)

                            Text("Drop PNG, JPG, SVG, or ICNS here")
                                .font(.system(size: 12, weight: .semibold))

                            Button("Choose Image File…") {
                                let panel = NSOpenPanel()
                                panel.title = "Select Image to Stamp on Folder"
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = false
                                panel.allowsMultipleSelection = false
                                panel.allowedContentTypes = [.png, .jpeg, .tiff, .svg, .icns]
                                if panel.runModal() == .OK, let url = panel.url {
                                    store.loadCustomImage(from: url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                }
            } else if store.spec.glyphKind == .symbol {
                // SF Symbol Browser
                InspectorCard {
                    InspectorSectionHeader(
                        title: "SF Symbol Browser",
                        subtitle: "Search or browse 140+ curated icons",
                        icon: "magnifyingglass",
                        iconColor: .blue
                    )

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search 140+ symbols...", text: $symbolSearchQuery)
                            .textFieldStyle(.plain)
                        if !symbolSearchQuery.isEmpty {
                            Button {
                                symbolSearchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )

                    // Category Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(SymbolCategory.allCases) { cat in
                                Button(cat.rawValue) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedCategory = cat
                                    }
                                }
                                .font(.system(size: 11, weight: selectedCategory == cat ? .semibold : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    if selectedCategory == cat {
                                        Capsule().fill(Color(nsColor: .controlAccentColor).opacity(0.25))
                                    } else {
                                        Capsule().fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    }
                                }
                                .foregroundStyle(selectedCategory == cat ? Color(nsColor: .controlAccentColor) : Color.primary)
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Curated Symbol Grid
                    let filtered = curatedSymbols(for: selectedCategory, query: symbolSearchQuery)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(filtered, id: \.self) { sym in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    store.spec.symbolName = sym
                                }
                            } label: {
                                Image(systemName: sym)
                                    .font(.system(size: 15))
                                    .frame(width: 36, height: 36)
                                    .background {
                                        if store.spec.symbolName == sym {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color(nsColor: .controlAccentColor))
                                                .shadow(color: Color(nsColor: .controlAccentColor).opacity(0.4), radius: 4, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                                        }
                                    }
                                    .foregroundStyle(store.spec.symbolName == sym ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .help(sym)
                        }
                    }

                    // Direct Symbol Name Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom SF Symbol Name")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("e.g. sparkles or terminal.fill", text: $store.spec.symbolName)
                                .textFieldStyle(.roundedBorder)

                            if NSImage(systemSymbolName: store.spec.symbolName, accessibilityDescription: nil) != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 14))
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 14))
                            }
                        }
                    }

                    // Symbol Rendering Mode
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Symbol Rendering Mode")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("Rendering", selection: $store.spec.symbolMode) {
                            ForEach(SymbolMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Corner Status Mini-Badge (v0.2)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.accentColor)
                            Text("Corner Status Badge (v0.2)")
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            if store.spec.cornerBadge != .none {
                                ColorPicker("", selection: $store.spec.cornerBadgeColor, supportsOpacity: false)
                                    .labelsHidden()
                            }
                        }

                        Picker("Badge", selection: $store.spec.cornerBadge) {
                            ForEach(CornerBadge.allCases) { b in
                                Text(b.rawValue).tag(b)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            } else {
                // Text / Emoji Monogram Mode
                InspectorCard {
                    InspectorSectionHeader(
                        title: "Custom Monogram / Emoji",
                        subtitle: "Type any letter, word or emoji character",
                        icon: "character.textbox",
                        iconColor: .orange
                    )

                    TextField("e.g. A, PRO, 🚀, ⚡️", text: $store.spec.text)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16, weight: .bold))

                    // Typography Font Family (v0.2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Typography Style (v0.2)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("Font", selection: $store.spec.textFontFamily) {
                            ForEach(TextFontFamily.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Stamping Depth Effect (v0.2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Stamping Depth (v0.2)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Picker("Depth", selection: $store.spec.textDepthStyle) {
                            ForEach(TextDepthStyle.allCases) { d in
                                Text(d.rawValue).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Quick suggestions
                    HStack(spacing: 8) {
                        ForEach(["🚀", "⚡️", "💎", "", "⌘", "PRO", "AI", "DEV"], id: \.self) { item in
                            Button(item) {
                                store.spec.text = item
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Glyph Styling (Color, Scale, Shadow, Rotation)
            InspectorCard {
                InspectorSectionHeader(
                    title: "Glyph Styling & Position",
                    subtitle: "Color, size, offset, rotation and soft shadow",
                    icon: "slider.horizontal.3",
                    iconColor: .green
                )

                if store.spec.glyphKind == .text || store.spec.symbolMode != .multicolor {
                    Toggle("Gradient Glyph Fill", isOn: $store.spec.glyphGradient)
                        .toggleStyle(.switch)
                        .font(.system(size: 12, weight: .medium))

                    ColorRowModern(title: store.spec.glyphGradient ? "Color 1" : "Color", color: $store.spec.glyphColor)

                    if store.spec.glyphGradient {
                        ColorRowModern(title: "Color 2", color: $store.spec.glyphColor2)
                    }
                }

                ModernSlider(
                    title: "Opacity",
                    value: $store.spec.glyphOpacity,
                    range: 0.1...1.0,
                    format: "%.0f",
                    multiplier: 100,
                    unit: "%",
                    onReset: { store.spec.glyphOpacity = 0.95 }
                )
                ModernSlider(
                    title: "Scale / Size",
                    value: $store.spec.glyphScale,
                    range: 0.15...0.95,
                    format: "%.0f",
                    multiplier: 100,
                    unit: "%",
                    onReset: { store.spec.glyphScale = 0.52 }
                )
                ModernSlider(
                    title: "Vertical Offset",
                    value: $store.spec.glyphYOffset,
                    range: -0.3...0.3,
                    format: "%.2f",
                    onReset: { store.spec.glyphYOffset = 0.05 }
                )

                ModernSlider(
                    title: "Rotation Angle",
                    value: $store.spec.glyphRotation,
                    range: -180...180,
                    format: "%.0f",
                    unit: "°",
                    onReset: { store.spec.glyphRotation = 0 }
                )

                // Stamping & Engraving Depth Effect
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Stamping & Engraving Depth")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if store.spec.textDepthStyle == .engraved {
                            HStack(spacing: 4) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 9))
                                Text("macOS Deboss")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                            .foregroundStyle(Color.accentColor)
                        }
                    }

                    Picker("Depth", selection: $store.spec.textDepthStyle) {
                        ForEach(TextDepthStyle.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)

                    if store.spec.textDepthStyle == .engraved && store.spec.base == .folder {
                        Toggle("Match Folder Material (Native Deboss)", isOn: $store.spec.glyphEngravedFolderTint)
                            .toggleStyle(.switch)
                            .font(.system(size: 11, weight: .medium))
                            .help("Darkens and debosses symbol directly into folder plastic, matching native macOS folders.")
                    }
                }

                Toggle("Glyph Soft Shadow", isOn: $store.spec.glyphShadow)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }

    private func curatedSymbols(for category: SymbolCategory, query: String) -> [String] {
        let baseList: [String]
        switch category {
        case .all:
            baseList = SymbolCategory.allCases.flatMap { $0.symbols }
        default:
            baseList = category.symbols
        }

        let deduped = Array(NSOrderedSet(array: baseList)) as? [String] ?? baseList
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return deduped
        }
        let q = query.lowercased()
        return deduped.filter { $0.lowercased().contains(q) }
    }
}

// MARK: - Symbol Categories

enum SymbolCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case tools = "Tools & Code"
    case media = "Media & Art"
    case hardware = "Devices"
    case communication = "Connect"
    case badges = "Badges"
    case nature = "Nature & World"

    var id: String { rawValue }

    var symbols: [String] {
        switch self {
        case .all:
            return []
        case .tools:
            return [
                "gearshape.fill", "wrench.and.screwdriver.fill", "hammer.fill", "wand.and.stars",
                "paintbrush.fill", "terminal.fill", "cpu.fill", "cube.transparent.fill",
                "cube.fill", "slider.horizontal.3", "magnifyingglass", "shield.fill",
                "lock.fill", "key.fill", "link", "archivebox.fill",
                "folder.fill", "doc.text.fill", "briefcase.fill", "building.columns.fill"
            ]
        case .media:
            return [
                "paintpalette.fill", "camera.fill", "music.note", "waveform",
                "opticaldisc.fill", "film.fill", "play.rectangle.fill", "speaker.wave.3.fill",
                "headphones", "mic.fill", "photo.fill", "theatermasks.fill",
                "eye.fill", "sparkles", "sun.max.fill", "moon.stars.fill"
            ]
        case .hardware:
            return [
                "macbook", "desktopcomputer", "iphone", "ipad",
                "applewatch", "server.rack", "network", "externaldrive.fill",
                "memorychip.fill", "antenna.radiowaves.left.and.right", "wifi", "bolt.horizontal.fill",
                "command", "option", "keyboard.fill", "printer.fill"
            ]
        case .communication:
            return [
                "bubble.left.and.bubble.right.fill", "envelope.fill", "paperplane.fill", "globe",
                "phone.fill", "video.fill", "bell.fill", "megaphone.fill",
                "person.2.fill", "person.crop.circle.fill", "hands.sparkles.fill", "heart.text.square.fill"
            ]
        case .badges:
            return [
                "star.fill", "heart.fill", "flame.fill", "bolt.fill",
                "crown.fill", "checkmark.seal.fill", "rosette", "trophy.fill",
                "medal.fill", "flag.fill", "gift.fill", "gamecontroller.fill",
                "cart.fill", "bag.fill", "creditcard.fill", "bookmark.fill"
            ]
        case .nature:
            return [
                "leaf.fill", "drop.fill", "tree.fill", "cloud.sun.fill",
                "tornado", "snowflake", "atom", "compass.drawing",
                "map.fill", "airplane", "car.fill", "bicycle", "fuelpump.fill", "tent.fill"
            ]
        }
    }
}

// MARK: - Nameplate & Unicode Card Buttons

struct NameplateCardButton: View {
    let style: NameplateStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )

                    Image(systemName: style.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(styleSubtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var styleSubtitle: String {
        switch style {
        case .textOnly: return "Direct flap typography"
        case .retroTape: return "Dymo plastic embossed"
        case .folderEngraved: return "Native macOS debossed"
        case .glassCapsule: return "Translucent frosted pill"
        case .brassPlate: return "Metallic with corner rivets"
        case .cyberRibbon: return "Obsidian neon glowing"
        case .maskingTape: return "Semi-opaque washi paper"
        case .cleanTag: return "Crisp minimal colored"
        }
    }
}

struct UnicodeStyleCardButton: View {
    let style: UnicodeStyle
    let sampleText: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(style.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(sampleText)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Text & Unicode Renamer Tab (v0.4)

struct TextInspectorTab: View {
    @ObservedObject var store: IconStore
    @State private var renamerInput: String = "My Folder"
    @State private var selectedUnicodeStyle: UnicodeStyle = .boldSans

    private var transformedName: String {
        UnicodeStyler.transform(renamerInput.isEmpty ? "My Folder" : renamerInput, style: selectedUnicodeStyle)
    }

    private let quickLabels = [
        "PROJECTS", "ARCHIVE", "CONFIDENTIAL", "DEV", "2026", "TOP SECRET", "CLIENT", "VAULT", "CODE", "MUSIC"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Feature 1: Folder Nameplate / Label Banner on Icon
            InspectorCard {
                InspectorSectionHeader(
                    title: "Folder Nameplate Banner",
                    subtitle: "Embossed label tape, glass capsule, or brass plate on flap",
                    icon: "tag.fill",
                    iconColor: .purple
                )

                Toggle("Show Nameplate on Folder", isOn: $store.spec.nameplateEnabled)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .semibold))

                if store.spec.nameplateEnabled {
                    Toggle("Move Icon Above Nameplate", isOn: $store.spec.nameplateMoveIconAbove)
                        .toggleStyle(.switch)
                        .font(.system(size: 11, weight: .medium))
                        .help("Automatically shifts the folder logo/icon into the upper flap area so it sits gracefully above the nameplate")

                    // 1-Tap Engraved Match Shortcut
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            store.spec.nameplateStyle = .folderEngraved
                            store.spec.textDepthStyle = .engraved
                            store.spec.glyphEngravedFolderTint = true
                            store.spec.nameplateMoveIconAbove = true
                        }
                        store.notify("Applied macOS Native Folder Engraving! 📁✨")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                            Text("1-Tap Native Engraved Look")
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Text("Icon + Nameplate")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .help("Carves both the icon logo and namebar directly into the folder flap, matching native macOS folders")
                    // Label Text Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Label Banner Text")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("e.g. PROJECTS or ARCHIVE", text: $store.spec.nameplateText)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13, weight: .bold))

                            if !store.spec.nameplateText.isEmpty {
                                Button {
                                    store.spec.nameplateText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Quick Preset Words Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quickLabels, id: \.self) { word in
                                Button(word) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        store.spec.nameplateText = word
                                    }
                                }
                                .font(.system(size: 10, weight: store.spec.nameplateText == word ? .bold : .medium, design: .monospaced))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background {
                                    if store.spec.nameplateText == word {
                                        Capsule().fill(Color(nsColor: .controlAccentColor).opacity(0.25))
                                    } else {
                                        Capsule().fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    }
                                }
                                .foregroundStyle(store.spec.nameplateText == word ? Color.accentColor : Color.primary)
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Nameplate Style Picker Grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Banner Appearance Style")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(NameplateStyle.allCases) { style in
                                NameplateCardButton(
                                    style: style,
                                    isSelected: store.spec.nameplateStyle == style
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        store.spec.nameplateStyle = style
                                        switch style {
                                        case .textOnly:
                                            store.spec.nameplateTextColor = .white
                                        case .retroTape:
                                            store.spec.nameplateColor = Color(hex: "#1A1A1A") ?? .black
                                            store.spec.nameplateTextColor = .white
                                        case .folderEngraved:
                                            store.spec.nameplateColor = Color.black.opacity(0.14)
                                            store.spec.nameplateTextColor = Color.black.opacity(0.55)
                                        case .glassCapsule:
                                            store.spec.nameplateColor = store.spec.color1.darker(0.3)
                                            store.spec.nameplateTextColor = .white
                                        case .brassPlate:
                                            store.spec.nameplateColor = Color(hex: "#E5A93C") ?? .orange
                                            store.spec.nameplateTextColor = Color(hex: "#3D2400") ?? .black
                                        case .cyberRibbon:
                                            store.spec.nameplateColor = Color(hex: "#00F0FF") ?? .cyan
                                            store.spec.nameplateTextColor = Color(hex: "#00F0FF") ?? .cyan
                                        case .maskingTape:
                                            store.spec.nameplateColor = Color(hex: "#F8F4E8") ?? .white
                                            store.spec.nameplateTextColor = Color(hex: "#262626") ?? .black
                                        case .cleanTag:
                                            store.spec.nameplateColor = store.spec.color1
                                            store.spec.nameplateTextColor = .white
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Color Customization
                    if store.spec.nameplateStyle != .textOnly {
                        ColorRowModern(title: "Plate Background", color: $store.spec.nameplateColor)
                    }
                    ColorRowModern(title: "Text Color", color: $store.spec.nameplateTextColor)

                    // Sliders
                    ModernSlider(
                        title: "Vertical Flap Position",
                        value: $store.spec.nameplateYOffset,
                        range: -0.2...0.45,
                        format: "%.2f",
                        onReset: { store.spec.nameplateYOffset = 0.22 }
                    )

                    ModernSlider(
                        title: "Banner Width / Scale",
                        value: $store.spec.nameplateScale,
                        range: 0.35...0.95,
                        format: "%.0f",
                        multiplier: 100,
                        unit: "%",
                        onReset: { store.spec.nameplateScale = 0.72 }
                    )
                }
            }

            // Feature 2: Unicode Folder Renamer
            InspectorCard {
                InspectorSectionHeader(
                    title: "Unicode Folder Renamer",
                    subtitle: "Transform folder names with stylish Unicode typography in Finder",
                    icon: "character.textbox",
                    iconColor: .blue
                )

                // Input Textfield
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original Folder Name")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("Folder name e.g. Documents", text: $renamerInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, weight: .medium))

                        if let target = store.lastTargetFolderURL {
                            Button("Use Active") {
                                renamerInput = target.lastPathComponent
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Load the name of the folder currently active in FolderLab")
                        }
                    }
                }

                // Styled Unicode Output Preview Box
                VStack(alignment: .leading, spacing: 10) {
                    Text("Styled Unicode Result Preview")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(transformedName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .padding(.vertical, 4)

                        HStack(spacing: 8) {
                            Button {
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(transformedName, forType: .string)
                                store.notify("Copied Unicode name '\(transformedName)'! 📋")
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Name")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button {
                                store.spec.nameplateEnabled = true
                                store.spec.nameplateText = transformedName
                                store.notify("Applied '\(transformedName)' to Nameplate! 🏷️")
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "tag.fill")
                                    Text("Set on Nameplate")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                    )
                }

                // Unicode Styles Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose Typography Style")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(UnicodeStyle.allCases) { style in
                            let sample = UnicodeStyler.transform(renamerInput.isEmpty ? "Folder" : renamerInput, style: style)
                            UnicodeStyleCardButton(
                                style: style,
                                sampleText: sample,
                                isSelected: selectedUnicodeStyle == style
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedUnicodeStyle = style
                                }
                            }
                        }
                    }
                }

                // Direct Finder Action Buttons
                VStack(spacing: 10) {
                    Button {
                        let panel = NSOpenPanel()
                        panel.title = "Select Folder to Rename with Unicode Typography"
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let selectedURL = panel.url {
                            store.renameFolderDirectly(url: selectedURL, newName: transformedName)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.badge.gearshape.fill")
                                .font(.system(size: 14))
                            Text("Choose Folder & Rename on Mac…")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .opacity(0.7)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, y: 1.5)
                    }
                    .buttonStyle(.plain)

                    if let targetURL = store.lastTargetFolderURL {
                        Button {
                            store.renameFolderDirectly(url: targetURL, newName: transformedName)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text("Rename Current Folder: '\(targetURL.lastPathComponent)' → '\(transformedName)'")
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Folder Applier & Export Tab

struct ExportInspectorTab: View {
    @ObservedObject var store: IconStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Live Folder Skinning
            InspectorCard {
                InspectorSectionHeader(
                    title: "Folder Applier (Finder Live)",
                    subtitle: "Apply your customized folder icon directly to folders on your Mac",
                    icon: "folder.badge.gearshape.fill",
                    iconColor: .accentColor
                )

                VStack(spacing: 12) {
                    Button {
                        store.applyToItems()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.badge.gearshape.fill")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apply to Folder in Finder…")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Select any folder to skin it with this design instantly")
                                    .font(.system(size: 10))
                                    .opacity(0.85)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.7)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.resetItems()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Restore Default macOS Blue Folder…")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentColor)
                        Text("Or drag & drop any folder from Finder directly onto the stage!")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            // Batch Styler Card (Feature 2)
            InspectorCard {
                InspectorSectionHeader(
                    title: "Batch Styler (Bulk Folders)",
                    subtitle: "Skin multiple selected folders or all subfolders in a parent directory at once",
                    icon: "square.grid.3x3.fill",
                    iconColor: .cyan
                )

                VStack(spacing: 10) {
                    Button {
                        store.applyToItems()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Skin Multiple Folders (Multi-Select)…")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Select multiple folders in Finder to skin them simultaneously")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.applyBatchSubfolders()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Skin All Subfolders in Directory…")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Select a folder (e.g. ~/Developer) and skin every project inside")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.resetBatchSubfolders()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Batch Reset Subfolders to Default…")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Clipboard & Files
            InspectorCard {
                InspectorSectionHeader(
                    title: "Save & Copy",
                    subtitle: "Copy to clipboard for Finder Get Info or save files",
                    icon: "arrow.down.doc.fill",
                    iconColor: .blue
                )

                // Copy to Clipboard Card
                ExportActionCard(
                    title: "Copy to Clipboard",
                    subtitle: "Directly paste (Cmd+V) onto any folder in Finder Get Info (Cmd+I)",
                    buttonText: "Copy 1024px PNG",
                    systemImage: "doc.on.doc.fill",
                    accentGradient: [Color.blue, Color.cyan]
                ) {
                    store.copyToClipboard()
                }

                // Export PNG Card
                ExportActionCard(
                    title: "Master PNG (1024×1024)",
                    subtitle: "Lossless crisp PNG with alpha transparency channel",
                    buttonText: "Save PNG…",
                    systemImage: "photo.fill",
                    accentGradient: [Color.purple, Color.indigo]
                ) {
                    store.exportPNG()
                }

                // Export ICNS Card
                ExportActionCard(
                    title: "Apple .icns Package",
                    subtitle: "Native macOS iconset containing 16px to 1024px @1x & @2x resolutions",
                    buttonText: "Generate .icns…",
                    systemImage: "app.badge.fill",
                    accentGradient: [Color.orange, Color.pink]
                ) {
                    store.exportICNS()
                }
            }

            // Portable Theme Presets (.folderlab)
            InspectorCard {
                InspectorSectionHeader(
                    title: "Shareable Theme Presets (.folderlab)",
                    subtitle: "Export your design as a portable file or import community themes",
                    icon: "square.and.arrow.up.fill",
                    iconColor: .purple
                )

                ExportActionCard(
                    title: "FolderLab Theme Preset (.folderlab)",
                    subtitle: "Export complete folder design including colors, textures, and glyphs into a shareable preset file",
                    buttonText: "Export Preset…",
                    systemImage: "square.and.arrow.up",
                    accentGradient: [Color.green, Color.teal]
                ) {
                    store.exportThemePreset()
                }

                Button {
                    store.importThemePreset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import .folderlab Preset File…")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ExportActionCard: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let systemImage: String
    let accentGradient: [Color]
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Reusable UI Components

struct InspectorSectionHeader: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    var iconColor: Color = .accentColor

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 24, height: 24)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Standardized Inspector Card Container

struct InspectorCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ModernSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"
    var multiplier: Double = 1.0
    var unit: String = ""
    var onReset: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: format, value * multiplier) + unit)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                if let onReset = onReset {
                    Button("Reset") {
                        withAnimation { onReset() }
                    }
                    .font(.system(size: 10, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .padding(.leading, 4)
                }
            }
            Slider(value: $value, in: range)
        }
    }
}

struct ColorRowModern: View {
    let title: String
    @Binding var color: Color
    @State private var hex = ""

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))

            Spacer()

            // Hex Input Field
            TextField("#RRGGBB", text: $hex)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 82)
                .onSubmit {
                    if let c = Color(hex: hex) {
                        color = c
                    } else {
                        hex = color.hexString
                    }
                }

            // Interactive Color Picker
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()

            // Screen Eyedropper Button
            Button {
                Eyedropper.pick { color = $0 }
            } label: {
                Image(systemName: "eyedropper")
                    .font(.system(size: 12))
                    .frame(width: 26, height: 26)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Pick a color from anywhere on your screen")
        }
        .onAppear { hex = color.hexString }
        .onChange(of: color) { newColor in hex = newColor.hexString }
    }
}
