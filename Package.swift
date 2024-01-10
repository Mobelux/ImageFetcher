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
        .library(name: "ImageFetcher", targets: ["ImageFetcher"])
    ],
    dependencies: [
         .package(url: "https://github.com/Mobelux/DiskCache.git", from: "2.0.0"),
         .package(url: "https://github.com/apple/swift-crypto.git", from: "3.2.0")
    ],
    targets: [
        .target(
            name: "ImageFetcher",
            dependencies: [
                "DiskCache",
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "ImageFetcherTests",
            dependencies: [
                "ImageFetcher"
            ]
        )
    ]
)
