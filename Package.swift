// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CodexQuotaOrb",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CodexQuotaOrb", targets: ["CodexQuotaOrb"])
    ],
    targets: [
        .executableTarget(
            name: "CodexQuotaOrb",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
