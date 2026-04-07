// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "OpenSSLSPM",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "OpenSSL",
            targets: ["OpenSSL"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "OpenSSL",
            path: "OpenSSL.xcframework"
        ),
    ]
)
