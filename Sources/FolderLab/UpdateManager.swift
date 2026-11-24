import Foundation
import SwiftUI
import AppKit

// MARK: - GitHub Release Models

public struct GitHubRelease: Decodable, Identifiable, Sendable {
    public var id: String { tagName }
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }

    public var cleanVersion: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\n\r"))
    }

    public var dmgAsset: GitHubAsset? {
        assets.first { $0.name.lowercased().hasSuffix(".dmg") }
    }

    public var zipAsset: GitHubAsset? {
        assets.first { $0.name.lowercased().hasSuffix(".zip") }
    }
}

public struct GitHubAsset: Decodable, Identifiable, Sendable {
    public var id: String { browserDownloadUrl }
    public let name: String
    public let size: Int
    public let browserDownloadUrl: String
    public let contentType: String

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case browserDownloadUrl = "browser_download_url"
        case contentType = "content_type"
    }

    public var formattedSize: String {
        let mb = Double(size) / (1024.0 * 1024.0)
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Update State

public enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate(version: String, lastChecked: Date)
    case updateAvailable(release: GitHubRelease)
    case downloading(progress: Double, bytesWritten: Int64, totalBytes: Int64)
    case installing(status: String)
    case installed(version: String, appURL: URL)
    case readyToInstall(fileURL: URL, version: String)
    case error(message: String)

    public static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.checking, .checking):
            return true
        case (.upToDate(let v1, _), .upToDate(let v2, _)):
            return v1 == v2
        case (.updateAvailable(let r1), .updateAvailable(let r2)):
            return r1.tagName == r2.tagName
        case (.downloading(let p1, _, _), .downloading(let p2, _, _)):
            return abs(p1 - p2) < 0.001
        case (.installing(let s1), .installing(let s2)):
            return s1 == s2
        case (.installed(let v1, let u1), .installed(let v2, let u2)):
            return v1 == v2 && u1 == u2
        case (.readyToInstall(let u1, let v1), .readyToInstall(let u2, let v2)):
            return u1 == u2 && v1 == v2
        case (.error(let m1), .error(let m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

// MARK: - Update Manager

@MainActor
public final class UpdateManager: NSObject, ObservableObject {
    public static let shared = UpdateManager()

    public static let repositoryOwner = "balshaansingh29"
    public static let repositoryName = "FolderLab"
    public static let currentVersion: String = {
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !ver.isEmpty {
            return ver
        }
        return "0.6"
    }()

    @Published public var state: UpdateState = .idle
    @Published public var hasCheckedOnce = false
    @Published public var lastCheckDate: Date? {
        didSet {
            if let date = lastCheckDate {
                UserDefaults.standard.set(date, forKey: "folderlab_last_update_check")
            }
        }
    }

    @Published public var isUpdateSheetPresented = false

    private var downloadTask: URLSessionDownloadTask?
    private var downloadObservation: NSKeyValueObservation?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config, delegate: nil, delegateQueue: .main)
    }()

    override private init() {
        super.init()
        if let storedDate = UserDefaults.standard.object(forKey: "folderlab_last_update_check") as? Date {
            self.lastCheckDate = storedDate
        }
    }

    // MARK: - Check for Updates

    public func checkForUpdates(showModal: Bool = false) {
        guard state != .checking && !isDownloading else { return }

        state = .checking
        if showModal {
            isUpdateSheetPresented = true
        }

        let endpoint = "https://api.github.com/repos/\(Self.repositoryOwner)/\(Self.repositoryName)/releases/latest"
        guard let url = URL(string: endpoint) else {
            state = .error(message: "Invalid update endpoint URL.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("FolderLab-Updater/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.state = .error(message: "Received invalid response from server.")
                    return
                }

                if httpResponse.statusCode == 404 {
                    // No releases found
                    self.state = .upToDate(version: Self.currentVersion, lastChecked: Date())
                    self.lastCheckDate = Date()
                    self.hasCheckedOnce = true
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    self.state = .error(message: "GitHub API error (status \(httpResponse.statusCode)).")
                    return
                }

                let decoder = JSONDecoder()
                let release = try decoder.decode(GitHubRelease.self, from: data)

                self.lastCheckDate = Date()
                self.hasCheckedOnce = true

                if Self.isVersion(release.cleanVersion, higherThan: Self.currentVersion) {
                    self.state = .updateAvailable(release: release)
                } else {
                    self.state = .upToDate(version: Self.currentVersion, lastChecked: Date())
                }
            } catch {
                self.state = .error(message: "Failed to check for updates: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Download & Install

    public var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }

    public func downloadAndInstall(release: GitHubRelease) {
        guard let asset = release.dmgAsset ?? release.zipAsset,
              let downloadURL = URL(string: asset.browserDownloadUrl) else {
            // Open release in browser as fallback
            openReleasePage(release)
            return
        }

        state = .downloading(progress: 0.0, bytesWritten: 0, totalBytes: Int64(asset.size))

        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let destinationURL = downloadsDir.appendingPathComponent(asset.name)

        // Clean up previous download if present
        try? FileManager.default.removeItem(at: destinationURL)

        let task = urlSession.downloadTask(with: downloadURL) { [weak self] tempURL, response, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.downloadObservation?.invalidate()
                self.downloadObservation = nil
                self.downloadTask = nil

                if let error = error {
                    self.state = .error(message: "Download failed: \(error.localizedDescription)")
                    return
                }

                guard let tempURL = tempURL else {
                    self.state = .error(message: "Temporary download file missing.")
                    return
                }

                do {
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    // Automatically install directly once downloaded!
                    self.performAutomaticInstall(fileURL: destinationURL, version: release.tagName)
                } catch {
                    self.state = .error(message: "Failed to save downloaded file: \(error.localizedDescription)")
                }
            }
        }

        downloadObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor in
                guard let self = self, case .downloading = self.state else { return }
                self.state = .downloading(
                    progress: progress.fractionCompleted,
                    bytesWritten: progress.completedUnitCount,
                    totalBytes: progress.totalUnitCount > 0 ? progress.totalUnitCount : Int64(asset.size)
                )
            }
        }

        self.downloadTask = task
        task.resume()
    }

    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadObservation?.invalidate()
        downloadObservation = nil
        state = .idle
    }

    // MARK: - Automatic In-Place Installation

    public func performAutomaticInstall(fileURL: URL, version: String) {
        self.state = .installing(status: "Installing FolderLab \(version)…")

        Task.detached(priority: .userInitiated) {
            let fileManager = FileManager.default
            let ext = fileURL.pathExtension.lowercased()

            // 1. Determine destination URL
            let targetURL: URL
            let applicationsFolder = URL(fileURLWithPath: "/Applications/FolderLab.app")
            let runningAppURL = Bundle.main.bundleURL

            if runningAppURL.path.hasPrefix("/Applications") {
                targetURL = applicationsFolder
            } else if fileManager.isWritableFile(atPath: "/Applications") {
                targetURL = applicationsFolder
            } else if runningAppURL.pathExtension.lowercased() == "app" && fileManager.isWritableFile(atPath: runningAppURL.deletingLastPathComponent().path) {
                targetURL = runningAppURL
            } else {
                targetURL = applicationsFolder
            }

            var extractedAppURL: URL? = nil
            var mountPointToCleanup: URL? = nil
            var tempDirToCleanup: URL? = nil

            do {
                if ext == "dmg" {
                    // Mount DMG silently to temporary directory
                    let mountPoint = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("FolderLabMount_\(UUID().uuidString)")
                    try fileManager.createDirectory(at: mountPoint, withIntermediateDirectories: true)
                    mountPointToCleanup = mountPoint

                    let attachProc = Process()
                    attachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                    attachProc.arguments = ["attach", fileURL.path, "-nobrowse", "-mountpoint", mountPoint.path, "-quiet"]
                    try attachProc.run()
                    attachProc.waitUntilExit()

                    if attachProc.terminationStatus != 0 {
                        throw NSError(domain: "FolderLabUpdate", code: Int(attachProc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to mount DMG installer image."])
                    }

                    let potentialApp = mountPoint.appendingPathComponent("FolderLab.app")
                    if fileManager.fileExists(atPath: potentialApp.path) {
                        extractedAppURL = potentialApp
                    } else {
                        let contents = try fileManager.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil)
                        extractedAppURL = contents.first { $0.pathExtension.lowercased() == "app" }
                    }
                } else {
                    // Extract ZIP using ditto
                    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("FolderLabExtract_\(UUID().uuidString)")
                    try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                    tempDirToCleanup = tempDir

                    let unzipProc = Process()
                    unzipProc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                    unzipProc.arguments = ["-x", "-k", fileURL.path, tempDir.path]
                    try unzipProc.run()
                    unzipProc.waitUntilExit()

                    let potentialApp = tempDir.appendingPathComponent("FolderLab.app")
                    if fileManager.fileExists(atPath: potentialApp.path) {
                        extractedAppURL = potentialApp
                    } else {
                        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                        extractedAppURL = contents.first { $0.pathExtension.lowercased() == "app" }
                    }
                }

                guard let sourceApp = extractedAppURL, fileManager.fileExists(atPath: sourceApp.path) else {
                    throw NSError(domain: "FolderLabUpdate", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not locate FolderLab.app inside downloaded archive."])
                }

                // If target app already exists, move it aside temporarily
                let backupURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("FolderLab_Backup_\(UUID().uuidString).app")
                if fileManager.fileExists(atPath: targetURL.path) {
                    try? fileManager.removeItem(at: backupURL)
                    try fileManager.moveItem(at: targetURL, to: backupURL)
                }

                // Copy new app to target location using ditto to preserve all metadata and signatures
                let copyProc = Process()
                copyProc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                copyProc.arguments = [sourceApp.path, targetURL.path]
                try copyProc.run()
                copyProc.waitUntilExit()

                if copyProc.terminationStatus != 0 {
                    // Rollback backup if copy failed
                    if fileManager.fileExists(atPath: backupURL.path) {
                        try? fileManager.moveItem(at: backupURL, to: targetURL)
                    }
                    throw NSError(domain: "FolderLabUpdate", code: Int(copyProc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to copy updated FolderLab.app to \(targetURL.path)."])
                }

                // Strip quarantine attributes
                let xattrProc = Process()
                xattrProc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattrProc.arguments = ["-cr", targetURL.path]
                try? xattrProc.run()
                xattrProc.waitUntilExit()

                // Remove backup
                try? fileManager.removeItem(at: backupURL)

                // Cleanup mount point / temp
                if let mountPoint = mountPointToCleanup {
                    let detachProc = Process()
                    detachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                    detachProc.arguments = ["detach", mountPoint.path, "-quiet", "-force"]
                    try? detachProc.run()
                    detachProc.waitUntilExit()
                    try? fileManager.removeItem(at: mountPoint)
                }
                if let tempDir = tempDirToCleanup {
                    try? fileManager.removeItem(at: tempDir)
                }

                await MainActor.run {
                    self.state = .installed(version: version, appURL: targetURL)
                }
            } catch {
                // Cleanup on error
                if let mountPoint = mountPointToCleanup {
                    let detachProc = Process()
                    detachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                    detachProc.arguments = ["detach", mountPoint.path, "-quiet", "-force"]
                    try? detachProc.run()
                    detachProc.waitUntilExit()
                    try? fileManager.removeItem(at: mountPoint)
                }
                if let tempDir = tempDirToCleanup {
                    try? fileManager.removeItem(at: tempDir)
                }

                await MainActor.run {
                    self.state = .error(message: "Automatic install failed: \(error.localizedDescription)")
                }
            }
        }
    }

    public func relaunchApp(at appURL: URL) {
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = "while kill -0 " + String(pid) + " 2>/dev/null; do sleep 0.2; done; open -n \"" + appURL.path + "\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", script]
        try? proc.run()
        NSApp.terminate(nil)
    }

    public func installDownloadedPackage(fileURL: URL) {
        if fileURL.pathExtension.lowercased() == "dmg" {
            // Open/mount DMG directly
            NSWorkspace.shared.open(fileURL)
        } else {
            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    public func openReleasePage(_ release: GitHubRelease? = nil) {
        let urlString = release?.htmlUrl ?? "https://github.com/\(Self.repositoryOwner)/\(Self.repositoryName)/releases"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Semantic Version Comparison

    public static func isVersion(_ remote: String, higherThan local: String) -> Bool {
        let rParts = remote.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\n\r"))
            .split(separator: ".")
            .compactMap { Int($0) }
        let lParts = local.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\n\r"))
            .split(separator: ".")
            .compactMap { Int($0) }

        let count = max(rParts.count, lParts.count)
        for i in 0..<count {
            let r = i < rParts.count ? rParts[i] : 0
            let l = i < lParts.count ? lParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
}
