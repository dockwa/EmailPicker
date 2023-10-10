// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmailPicker",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "EmailPicker",
            targets: ["EmailPicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dockwa/CLTokenInputView.git", from: "3.0.4")
    ],
    targets: [
        .target(
            name: "EmailPicker",
            dependencies: ["CLTokenInputView"]),
        .testTarget(
            name: "EmailPickerTests",
            dependencies: ["EmailPicker"]),
    ]
)
