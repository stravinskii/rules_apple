load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

licenses(["notice"])

swift_library(
    name = "Sources",
    srcs = [
        "Sources/AppDelegate.swift",
    ],
    data = [
        "Resources/Main.storyboard",
    ],
)

ios_application(
    name = "HelloWorldSwift",
    app_icons = ["//examples/resources:PhoneAppIcon.xcassets"],
    bundle_id = "com.example.hello-world-swift",
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [":Info.plist"],
    launch_storyboard = "//examples/resources:Launch.storyboard",
    minimum_os_version = "11.0",
    deps = [":Sources"],
)

# Not normally needed, just done for rules_apple's examples so a
# 'bazel test examples/...' ensures all Examples still build.
build_test(
    name = "ExamplesBuildTest",
    targets = [":HelloWorldSwift"],
)
