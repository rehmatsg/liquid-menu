// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Test-harness manifest for the Flutter-free UIKit core that lives inside the
// plugin at `ios/liquid_menu/Sources/liquid_menu`.
//
// The plugin's own manifest can't be resolved standalone — it depends on the
// `FlutterFramework` package that only exists inside a Flutter app build — so
// this root manifest re-declares just the core sources (an explicit `sources:`
// list — everything except the three bridge files) as a module with the same
// name, which is what runs the core's unit tests:
//
//   xcodebuild test -scheme liquid_menu-Package -destination 'platform=iOS Simulator,name=iPhone 17'
//
// It deliberately declares no library product: this is a Flutter plugin, not
// a standalone Swift package.
let package = Package(
    name: "liquid_menu",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .target(
            name: "liquid_menu",
            path: "ios/liquid_menu/Sources/liquid_menu",
            // The Flutter-free core. The bridge files (LiquidMenuPlugin,
            // WireModels, WireDecoding) import Flutter and only build inside
            // an app — adding a core file? list it here too.
            sources: [
                "LiquidMenu.swift",
                "MenuAnchorControl.swift",
                "MenuBuilder.swift",
                "MenuModels.swift",
                "MenuOverlayHost.swift",
                "MenuPresenter.swift"
            ],
            resources: [
                // Ships a privacy manifest declaring no data collection and no
                // required-reason API usage (it uses only public APIs).
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "LiquidMenuTests",
            dependencies: ["liquid_menu"],
            path: "ios/liquid_menu/Tests/LiquidMenuTests"
        )
    ]
)
