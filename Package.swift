// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FolderLab",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "FolderLab",
            path: "Sources/FolderLab",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
