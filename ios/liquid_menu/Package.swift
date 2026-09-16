// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The plugin's iOS package — a single `liquid_menu` target holding both the
// bridge (channels + wire decoding, the only `import Flutter` files) and the
// UIKit core (menu models, UIMenu builder, overlay host, presenter).
//
// The library product MUST be named "liquid-menu": the Flutter tool derives
// the product name it links against by hyphenating the plugin name.
//
// Every path this manifest NAMES stays inside the package directory, and that
// is load-bearing: Flutter resolves a plugin through a symlink in the
// consuming app (`ios/Flutter/ephemeral/Packages/.packages/<plugin>`), and
// SwiftPM resolves a manifest's relative paths against that symlink rather
// than the checkout it points into. A path reaching above this directory
// would land in the app's ephemeral folder and fail resolution — which is
// also why `../FlutterFramework` works: through the symlink it lands on the
// sibling `FlutterFramework` package Flutter generates there.
let package = Package(
    name: "liquid_menu",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .library(name: "liquid-menu", targets: ["liquid_menu"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "liquid_menu",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // Ships a privacy manifest declaring no data collection and no
                // required-reason API usage (it uses only public APIs).
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        // Core unit tests — declared here for tidiness but only runnable
        // through the repo-root manifest (this package's FlutterFramework
        // dependency doesn't resolve outside an app build).
        .testTarget(
            name: "LiquidMenuTests",
            dependencies: ["liquid_menu"]
        )
    ]
)
