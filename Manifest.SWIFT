// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "DDiffExtensions",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ddiff", targets: ["DDiffExtensions"]),
    ],
    dependencies: [
        // Add dependencies if needed
    ],
    targets: [
        .target(
            name: "DDiffExtensions",
            dependencies: []
        ),
        .testTarget(
            name: "DDiffExtensionsTests",
            dependencies: ["DDiffExtensions"]
        ),
    ]
)