// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The standalone UIKit package: `LiquidMenu`, native `UIMenu` popups presented
// at an anchor on an overlay above your app.
//
// This manifest lives at the REPO ROOT on purpose: SwiftPM can only resolve a
// git URL whose repository root contains a `Package.swift`, so this is what
// makes `https://github.com/rehmatsg/liquid-menu.git` installable in Xcode.
// The manifest is thin — every source file lives under `liquid-menu-swift/`.
// The Flutter plugin's own package (under `liquid_menu/ios/`) compiles that
// same folder through a symlink, so the core exists exactly once with no
// vendored copy to drift.
let package = Package(
    name: "liquid-menu",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .library(name: "LiquidMenu", targets: ["LiquidMenu"])
    ],
    targets: [
        .target(
            name: "LiquidMenu",
            path: "liquid-menu-swift/Sources/LiquidMenu",
            resources: [
                // Ships a privacy manifest declaring no data collection and no
                // required-reason API usage (it uses only public APIs).
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "LiquidMenuTests",
            dependencies: ["LiquidMenu"],
            path: "liquid-menu-swift/Tests/LiquidMenuTests"
        )
    ]
)
