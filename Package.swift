// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftScreenShot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SwiftScreenShot",
            targets: ["SwiftScreenShot"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SwiftScreenShot",
            dependencies: [],
            path: "Sources",
            exclude: [
                "SwiftScreenShot/Resources/Info.plist",
                "SwiftScreenShot/Resources/SwiftScreenShot-Bridging-Header.h"
            ]
        )
    ]
)
