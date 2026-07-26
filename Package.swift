// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "StorageAtlas",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "StorageAtlas", targets: ["StorageAtlas"])
    ],
    targets: [
        .executableTarget(
            name: "StorageAtlas",
            path: "Sources/StorageAtlas"
        ),
        .testTarget(
            name: "StorageAtlasTests",
            dependencies: ["StorageAtlas"],
            path: "Tests/StorageAtlasTests"
        )
    ]
)
