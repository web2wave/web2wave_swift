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
    dependencies: [
           .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git", from: "6.13.0"),
           .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.16.0")
       ],
    targets: [
        .target(
            name: "Web2Wave",
        dependencies: [
            .product(name: "AppsFlyerLib", package: "AppsFlyerFramework"),
            .product(name: "RevenueCat", package: "purchases-ios-spm")
        ]),
    ]
)
