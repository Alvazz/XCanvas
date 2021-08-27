// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCanvas",
    platforms: [.macOS(.v10_11)],
    products: [
        .library(name: "XCanvas", targets: ["XCanvas"]),
    ],
    targets: [
        .target(name: "XCanvas", path: "Sources"),
        .testTarget(name: "XCanvasTests", dependencies: ["XCanvas"]),
    ]
)
