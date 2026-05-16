// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppleTVRemote",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AppleTVRemote",
            path: "Sources/AppleTVRemote",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"], .when(platforms: [.macOS]))
            ]
        )
    ]
)
