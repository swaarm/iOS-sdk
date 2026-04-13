// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwaarmSdk",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "SwaarmSdk",
            targets: ["SwaarmSdk"]
        ),
    ],
    targets: [
        .target(
            name: "SwaarmSdk",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "SwaarmSdkTests",
            dependencies: ["SwaarmSdk"]
        ),
    ]
)
