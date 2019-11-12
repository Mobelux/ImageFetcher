// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageFetcher",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ImageFetcher",
            targets: ["ImageFetcher"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://4d292b0f26f1c9affe7db75b52f11c893af22499:x-oauth-basic@github.com/Mobelux/DataOperation.git", from: "1.1.0"),
         .package(url: "https://4d292b0f26f1c9affe7db75b52f11c893af22499:x-oauth-basic@github.com/Mobelux/DiskCache.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ImageFetcher",
            dependencies: ["DataOperation", "DiskCache"]),
        .testTarget(
            name: "ImageFetcherTests",
            dependencies: ["ImageFetcher"]),
    ]
)
