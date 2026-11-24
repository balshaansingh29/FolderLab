import SwiftUI
import AppKit

// MARK: - Update Sheet View (Presented on Check for Updates)

public struct UpdateSheetView: View {
    @ObservedObject var updater = UpdateManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                if let appImg = AppIconManager.shared.loadIconComposerImage(for: .light) {
                    Image(nsImage: appImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .shadow(color: .purple.opacity(0.35), radius: 4, y: 1)
                } else {
                    IconCanvas(spec: .appIconLight, size: 36)
                        .shadow(color: .purple.opacity(0.3), radius: 4, y: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Software Update")
                        .font(.system(size: 15, weight: .bold))
                    Text("FolderLab v\(UpdateManager.currentVersion)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    updater.isUpdateSheetPresented = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Content Area
            VStack(spacing: 16) {
                switch updater.state {
                case .idle:
                    idleView
                case .checking:
                    checkingView
                case .upToDate(let version, let lastChecked):
                    upToDateView(version: version, date: lastChecked)
                case .updateAvailable(let release):
                    updateAvailableView(release: release)
                case .downloading(let progress, let bytesWritten, let totalBytes):
                    downloadingView(progress: progress, written: bytesWritten, total: totalBytes)
                case .installing(let status):
                    installingView(status: status)
                case .installed(let version, let appURL):
                    installedView(version: version, appURL: appURL)
                case .readyToInstall(let fileURL, let version):
                    readyToInstallView(fileURL: fileURL, version: version)
                case .error(let message):
                    errorView(message: message)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))

            Divider()

            // Footer
            HStack {
                if case .updateAvailable(let release) = updater.state {
                    Button("Release Page") {
                        updater.openReleasePage(release)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                }

                Spacer()

                footerButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 480, height: 340)
    }

    // MARK: - Subviews

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Ready to check for updates")
                .font(.system(size: 13, weight: .medium))
            Button("Check Now") {
                updater.checkForUpdates()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    private var checkingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.regular)
            Text("Checking GitHub for the latest release…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func upToDateView(version: String, date: Date) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 4) {
                Text("FolderLab is Up to Date")
                    .font(.system(size: 14, weight: .bold))
                Text("Version \(version) is currently the newest available version.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Last checked: \(date.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }

    private func updateAvailableView(release: GitHubRelease) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(release.name ?? "FolderLab \(release.tagName)")
                            .font(.system(size: 13, weight: .bold))
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.blue, in: Capsule())
                    }

                    if let asset = release.dmgAsset ?? release.zipAsset {
                        Text("Ready to install • \(asset.name) (\(asset.formattedSize))")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            // Release Notes snippet
            if let notes = release.body, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Release Highlights:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ScrollView {
                        Text(notes)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 105)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private func downloadingView(progress: Double, written: Int64, total: Int64) -> some View {
        VStack(spacing: 14) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 320)

            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                let writtenMB = Double(written) / (1024.0 * 1024.0)
                let totalMB = Double(total) / (1024.0 * 1024.0)
                Text(String(format: "%.1f MB / %.1f MB", writtenMB, totalMB))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 320)

            Text("Downloading update installer directly from GitHub…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Button("Cancel") {
                updater.cancelDownload()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func installingView(status: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.regular)

            VStack(spacing: 4) {
                Text(status)
                    .font(.system(size: 14, weight: .bold))
                Text("Mounting installer, replacing previous application bundle, and verifying security permissions…")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }

    private func installedView(version: String, appURL: URL) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 4) {
                Text("FolderLab \(version) Installed! 🎉")
                    .font(.system(size: 15, weight: .bold))
                Text("Successfully updated in:\n\(appURL.path)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Click 'Relaunch Now' to restart with the new version.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
    }

    private func readyToInstallView(fileURL: URL, version: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.green)
            }

            Text("Update Downloaded & Opened! 🎉")
                .font(.system(size: 13, weight: .bold))

            Text("The \(fileURL.lastPathComponent) installer was mounted.\nDrag FolderLab into /Applications to complete the update.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button("Re-open DMG") {
                    updater.installDownloadedPackage(fileURL: fileURL)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("Update Check Failed")
                .font(.system(size: 13, weight: .bold))

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button("Retry") {
                updater.checkForUpdates()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    // MARK: - Footer Buttons

    @ViewBuilder
    private var footerButtons: some View {
        switch updater.state {
        case .idle, .error:
            Button("Check Again") {
                updater.checkForUpdates()
            }
            .buttonStyle(.bordered)

            Button("Close") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.borderedProminent)

        case .checking:
            Button("Cancel") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.bordered)

        case .upToDate:
            Button("Done") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

        case .updateAvailable(let release):
            Button("Later") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.bordered)

            Button {
                updater.downloadAndInstall(release: release)
            } label: {
                Label("Update Now", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

        case .downloading, .installing:
            EmptyView()

        case .installed(_, let appURL):
            Button("Later") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.bordered)

            Button {
                updater.relaunchApp(at: appURL)
            } label: {
                Label("Relaunch Now", systemImage: "arrow.clockwise.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

        case .readyToInstall(let fileURL, let version):
            Button("Cancel") {
                updater.isUpdateSheetPresented = false
                dismiss()
            }
            .buttonStyle(.bordered)

            Button {
                updater.performAutomaticInstall(fileURL: fileURL, version: version)
            } label: {
                Label("Install Now", systemImage: "arrow.down.app.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }
}
