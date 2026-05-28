// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Marginalia",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Marginalia", targets: ["Marginalia"])
    ],
    targets: [
        .executableTarget(
            name: "Marginalia",
            path: "Sources/Marginalia",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources/en.lproj"),
                .process("Resources/tr.lproj")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
