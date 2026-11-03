// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-7.3.1"),
        .package(name: "file_picker_darwin", path: "../.packages/file_picker_darwin-2.4.0"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.7.1"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.15.2"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.7.1"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.3"),
        .package(name: "fluttertoast", path: "../.packages/fluttertoast-10.0.2"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.4.3"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+14"),
        .package(name: "location", path: "../.packages/location-10.0.2"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.2"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.6.4"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.3.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.6.1"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.4+1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.2"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.12.3"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "file-picker-darwin", package: "file_picker_darwin"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "fluttertoast", package: "fluttertoast"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "location", package: "location"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
