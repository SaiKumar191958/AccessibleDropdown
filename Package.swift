// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AccessibleDropdown",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AccessibleDropdown",
            targets: ["AccessibleDropdown"]
        )
    ],
    targets: [
        .target(
            name: "AccessibleDropdown",
            path: "Sources/AccessibleDropdown"
        ),
        .testTarget(
            name: "AccessibleDropdownTests",
            dependencies: ["AccessibleDropdown"],
            path: "Tests/AccessibleDropdownTests"
        )
    ]
)
