// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageFetcher",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ImageFetcher",
            targets: ["ImageFetcher"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/Mobelux/DataOperation", from: "1.1.0"),
         .package(url: "https://github.com/Mobelux/DiskCache", from: "1.1.0"),
         .package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ImageFetcher",
            dependencies: [
                "DataOperation",
                "DiskCache",
                .product(
                    name: "Crypto",
                    package: "swift-crypto")]),
        .testTarget(
            name: "ImageFetcherTests",
            dependencies: ["ImageFetcher"]),
    ]
)
