import SwiftUI
import AppKit

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var iconManager = AppIconManager.shared
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

                    Text("Version 1.0.0 • Native macOS Icon Studio & Icon Composer")
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
                VStack(alignment: .leading, spacing: 22) {
                    // About & Community
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About & Community")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("FolderLab is an open-source macOS application released under the MIT License. Crafted with SwiftUI & AppKit for high performance.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://github.com/yourusername/folderlab")!) {
                                Label("GitHub Repository", systemImage: "link")
                                    .font(.system(size: 11, weight: .medium))
                            }

                            Link(destination: URL(string: "https://github.com/yourusername/folderlab/issues")!) {
                                Label("Report an Issue", systemImage: "exclamationmark.bubble")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(16)
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
        .frame(width: 500, height: 320)
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
