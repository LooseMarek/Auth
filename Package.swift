// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Auth",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AuthShared", targets: ["AuthShared"]),
        .library(name: "AuthClient", targets: ["AuthClient"]),
        .library(name: "AuthServer", targets: ["AuthServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.2"),
        .package(url: "https://github.com/vapor/fluent", from: "4.13.0"),
        .package(url: "https://github.com/vapor/jwt-kit", from: "5.5.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.121.4"),
    ],
    targets: [
        .target(
            name: "AuthShared",
            dependencies: [],
            path: "Sources/AuthShared"
        ),
        .testTarget(
            name: "AuthSharedTests",
            dependencies: ["AuthShared"],
            path: "Tests/AuthSharedTests"
        ),
        .target(
            name: "AuthClient",
            dependencies: ["AuthShared",.product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),.product(name: "SnapshotTesting", package: "swift-snapshot-testing")],
            path: "Sources/AuthClient",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AuthClientTests",
            dependencies: ["AuthClient"],
            path: "Tests/AuthClientTests"
        ),
        .testTarget(
            name: "AuthClientSnapshotTests",
            dependencies: [
                "AuthClient",
                "AuthShared",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/AuthClientSnapshotTests",
            exclude: ["__Snapshots__"]
        ),
        .target(
            name: "AuthServer",
            dependencies: ["AuthShared",.product(name: "Vapor", package: "vapor"),.product(name: "JWTKit", package: "jwt-kit"),.product(name: "Fluent", package: "fluent")],
            path: "Sources/AuthServer"
        ),
        .testTarget(
            name: "AuthServerTests",
            dependencies: [
                "AuthServer",
                .product(name: "XCTVapor", package: "vapor"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],
            path: "Tests/AuthServerTests"
        ),
    ]
)
