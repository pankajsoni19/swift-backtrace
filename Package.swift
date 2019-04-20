// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "swift-backtrace",
    products: [
        .library(
            name: "Backtrace",
            targets: ["Backtrace"]),
    ],
    dependencies: [],
    targets: [
        .systemLibrary(name: "CBacktrace"),
        .target(
            name: "Backtrace",
            dependencies: [.target(name: "CBacktrace")]),
        .testTarget(
            name: "BacktraceTests",
            dependencies: ["Backtrace"])
    ]
)
