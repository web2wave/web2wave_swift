// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Web2Wave",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Web2Wave",
            targets: ["Web2Wave"]),
    ],
    targets: [
        .target(
            name: "Web2Wave"),

    ]
)
