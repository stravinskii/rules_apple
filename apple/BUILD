load(":cc_toolchain_forwarder.bzl", "cc_toolchain_forwarder")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

# TODO(b/180572694): Remove ios_sim_arm64 after platforms based toolchain resolution supported.
# Create a set of public config_settings that can be used in select()s.
[
    config_setting(
        name = arch,
        values = {"cpu": arch},
    )
    for arch in [
        "darwin_x86_64",
        "darwin_arm64",
        "darwin_arm64e",
        "ios_i386",
        "ios_x86_64",
        "ios_armv7",
        "ios_arm64",
        "ios_sim_arm64",
        "tvos_x86_64",
        "tvos_arm64",
        "watchos_i386",
        "watchos_arm64",
        "watchos_arm64_32",
        "watchos_armv7k",
    ]
]

bzl_library(
    name = "apple",
    srcs = ["apple.bzl"],
    deps = [
        "//apple/internal:apple_framework_import",
        "//apple/internal:apple_universal_binary",
        "//apple/internal:apple_xcframework_import",
        "//apple/internal:xcframework_rules",
    ],
)

bzl_library(
    name = "apple_binary",
    srcs = ["apple_binary.bzl"],
    deps = [
        "//apple/internal:linking_support",
        "//apple/internal:rule_attrs",
        "//apple/internal:rule_factory",
    ],
)

bzl_library(
    name = "apple_static_library",
    srcs = ["apple_static_library.bzl"],
    deps = [
        ":providers",
        "//apple/internal:linking_support",
        "//apple/internal:rule_attrs",
        "//apple/internal:rule_factory",
        "//apple/internal:transition_support",
    ],
)

bzl_library(
    name = "aspects",
    srcs = ["aspects.bzl"],
    deps = [
        "//apple/internal/aspects:framework_provider_aspect",
    ],
)

bzl_library(
    name = "cc_toolchain_forwarder",
    srcs = ["cc_toolchain_forwarder.bzl"],
    deps = [
        ":providers",
        "@bazel_tools//tools/cpp:toolchain_utils",
    ],
)

bzl_library(
    name = "common",
    srcs = ["common.bzl"],
)

bzl_library(
    name = "dtrace",
    srcs = ["dtrace.bzl"],
    deps = [
        "//apple/internal/utils:bundle_paths",
        "@bazel_skylib//lib:dicts",
        "@bazel_skylib//lib:paths",
        "@build_bazel_apple_support//lib:apple_support",
    ],
)

bzl_library(
    name = "ios",
    srcs = ["ios.bzl"],
    deps = [
        "//apple/internal:apple_product_type",
        "//apple/internal:ios_rules",
        "//apple/internal/testing:apple_test_assembler",
        "//apple/internal/testing:build_test_rules",
        "//apple/internal/testing:ios_rules",
    ],
)

bzl_library(
    name = "macos",
    srcs = ["macos.bzl"],
    deps = [
        "//apple/internal:macos_binary_support",
        "//apple/internal:macos_rules",
        "//apple/internal/testing:apple_test_assembler",
        "//apple/internal/testing:build_test_rules",
        "//apple/internal/testing:macos_rules",
    ],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
)

bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
)

bzl_library(
    name = "resources",
    srcs = ["resources.bzl"],
    deps = [
        "//apple/internal/resource_rules:apple_bundle_import",
        "//apple/internal/resource_rules:apple_core_data_model",
        "//apple/internal/resource_rules:apple_core_ml_library",
        "//apple/internal/resource_rules:apple_resource_bundle",
        "//apple/internal/resource_rules:apple_resource_group",
    ],
)

bzl_library(
    name = "tvos",
    srcs = ["tvos.bzl"],
    deps = [
        "//apple/internal:tvos_rules",
        "//apple/internal/testing:apple_test_assembler",
        "//apple/internal/testing:build_test_rules",
        "//apple/internal/testing:tvos_rules",
    ],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
)

bzl_library(
    name = "versioning",
    srcs = ["versioning.bzl"],
    deps = [
        ":providers",
        "//apple/internal:apple_toolchains",
        "@bazel_skylib//lib:dicts",
    ],
)

bzl_library(
    name = "watchos",
    srcs = ["watchos.bzl"],
    deps = [
        "//apple/internal:watchos_rules",
        "//apple/internal/testing:apple_test_assembler",
        "//apple/internal/testing:build_test_rules",
        "//apple/internal/testing:watchos_rules",
    ],
)

cc_toolchain_forwarder(
    name = "default_cc_toolchain_forwarder",
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]) + [
        "//apple/build_settings:for_bazel_tests",
        "//apple/internal:for_bazel_tests",
        "//apple/testing:for_bazel_tests",
    ],
    visibility = ["//:__pkg__"],
)
