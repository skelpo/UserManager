// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "users",
    products: [
        .library(name: "App", targets: ["App"]),
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0-rc"),
//        .package(url: "https://github.com/skelpo/aws.git", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.9.0"),
        .package(url: "https://github.com/vapor-community/sendgrid-provider.git", from: "3.0.0"),
        .package(url: "https://github.com/skelpo/lingo-provider.git", from: "2.0.0-rc.1.1"),
        .package(url: "https://github.com/skelpo/JWTDataProvider.git", from: "0.10.0-rc.2"),
        .package(url: "git@github.com:skelpo/JWTVapor.git", from: "0.5.0"),
        .package(url: "https://github.com/skelpo/SkelpoMiddleware.git", from: "1.4.0-rc.3.1")
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL", "JWT", "CryptoSwift", "SendGrid", "LingoVapor", "JWTDataProvider", "JWTVapor", "SkelpoMiddleware"],
                exclude: [
                    "Config",
                    "Public",
                    "Resources",
                    ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

