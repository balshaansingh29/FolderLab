import SwiftUI
import AppKit

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var iconManager = AppIconManager.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                if let img = iconManager.loadIconComposerImage(for: iconManager.activeResolvedVariant) {
                    Image(nsImage: img)
                        .resizable()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: .blue.opacity(0.35), radius: 5, y: 2)
                } else {
                    IconCanvas(spec: activeSpec, size: 42)
                        .shadow(color: .blue.opacity(0.35), radius: 5, y: 2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("FolderLab Settings")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text("Version \(UpdateManager.currentVersion) • Native macOS Icon Studio")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    // Software Updates Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Software Updates", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)

                            Spacer()

                            Button {
                                updateManager.checkForUpdates(userInitiated: true)
                            } label: {
                                if updateManager.state == .checking {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Check for Updates")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(updateManager.state == .checking || updateManager.isDownloading)
                        }

                        // Current Status Line
                        HStack(spacing: 8) {
                            statusIcon
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(statusSummaryText)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.primary)

                                if let date = updateManager.lastCheckDate {
                                    Text("Last checked: \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            if case .updateAvailable = updateManager.state {
                                Button("Update…") {
                                    updateManager.isUpdateSheetPresented = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Toggle(isOn: $autoCheckForUpdates) {
                            Text("Automatically check for updates on startup")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding(14)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // About & Community Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About & Community")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("FolderLab is an open-source macOS studio released under the MIT License. Crafted with SwiftUI & AppKit for high performance.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://github.com/balshaansingh29/FolderLab")!) {
                                Label("GitHub Repository", systemImage: "link")
                                    .font(.system(size: 11, weight: .medium))
                            }

                            Link(destination: URL(string: "https://github.com/balshaansingh29/FolderLab/releases")!) {
                                Label("Release Notes", systemImage: "sparkles")
                                    .font(.system(size: 11, weight: .medium))
                            }

                            Link(destination: URL(string: "https://github.com/balshaansingh29/FolderLab/issues")!) {
                                Label("Report an Issue", systemImage: "exclamationmark.bubble")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(14)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 520, height: 380)
    }

    // MARK: - Status Helpers

    @ViewBuilder
    private var statusIcon: some View {
        switch updateManager.state {
        case .idle:
            Image(systemName: "checkmark.shield")
                .foregroundStyle(.secondary)
        case .checking:
            ProgressView()
                .controlSize(.mini)
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .updateAvailable:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.blue)
        case .downloading:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.blue)
        case .readyToInstall:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var statusSummaryText: String {
        switch updateManager.state {
        case .idle:
            return "FolderLab v\(UpdateManager.currentVersion) is ready"
        case .checking:
            return "Checking for newer versions on GitHub…"
        case .upToDate(let ver, _):
            return "FolderLab v\(ver) is up to date"
        case .updateAvailable(let release):
            return "New version available: \(release.tagName)"
        case .downloading(let progress, _, _):
            return "Downloading update (\(Int(progress * 100))%)…"
        case .readyToInstall(_, let ver):
            return "\(ver) is ready to install (DMG opened)"
        case .error(let msg):
            return msg
        }
    }

    private var activeSpec: IconSpec {
        let current = (iconManager.selectedVariant == AppIconVariant.automatic.rawValue)
            ? iconManager.activeResolvedVariant
            : (AppIconVariant(rawValue: iconManager.selectedVariant) ?? .light)

        switch current {
        case .dark: return .appIconDark
        case .clearLight, .clearDark: return .appIconClear
        case .tinted: return .appIconTinted
        default: return .appIconLight
        }
    }
}
