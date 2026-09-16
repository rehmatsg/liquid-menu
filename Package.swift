// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Test-harness manifest for the `LiquidMenu` core that lives inside the
// Flutter plugin at `liquid_menu/ios/liquid_menu/Sources/LiquidMenu`.
//
// The plugin's own manifest can't be resolved standalone — it depends on the
// `FlutterFramework` package that only exists inside a Flutter app build — so
// this root manifest is what runs the core's unit tests:
//
//   xcodebuild test -scheme liquid-menu -destination 'platform=iOS Simulator,name=iPhone 17'
//
// It deliberately declares no library product: liquid-menu is a Flutter
// plugin, not a standalone Swift package.
let package = Package(
    name: "liquid-menu",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .target(
            name: "LiquidMenu",
            path: "liquid_menu/ios/liquid_menu/Sources/LiquidMenu",
            resources: [
                // Ships a privacy manifest declaring no data collection and no
                // required-reason API usage (it uses only public APIs).
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "LiquidMenuTests",
            dependencies: ["LiquidMenu"],
            path: "liquid_menu/ios/liquid_menu/Tests/LiquidMenuTests"
        )
    ]
)
