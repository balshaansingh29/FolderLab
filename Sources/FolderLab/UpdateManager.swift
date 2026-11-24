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
        return "0.2"
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

    public func checkForUpdates(userInitiated: Bool = false) {
        guard state != .checking && !isDownloading else { return }

        state = .checking
        if userInitiated {
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
                    if !userInitiated {
                        // Notify user unobtrusively
                        self.isUpdateSheetPresented = true
                    }
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
                    self.state = .readyToInstall(fileURL: destinationURL, version: release.tagName)
                    // Automatically prompt or mount
                    self.installDownloadedPackage(fileURL: destinationURL)
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
