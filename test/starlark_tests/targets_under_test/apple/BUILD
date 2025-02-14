load(
    "//apple:apple.bzl",
    "apple_dynamic_xcframework_import",
    "apple_static_xcframework",
    "apple_static_xcframework_import",
    "apple_universal_binary",
    "apple_xcframework",
)
load(
    "//test/starlark_tests/rules:generate_xcframework.bzl",
    "generate_dynamic_xcframework",
    "generate_static_xcframework",
)
load(
    "//apple:versioning.bzl",
    "apple_bundle_version",
)
load(
    "//apple:macos.bzl",
    "macos_bundle",
)
load(
    "//apple:resources.bzl",
    "apple_core_data_model",
)
load(
    "@build_bazel_rules_swift//swift:swift_library.bzl",
    "swift_library",
)
load(
    "//test/starlark_tests:common.bzl",
    "common",
)
load(
    "//test/testdata/rules:dummy_test_runner.bzl",
    "dummy_test_runner",
)

licenses(["notice"])

package(
    default_testonly = 1,
    default_visibility = ["//test/starlark_tests:__subpackages__"],
)

# This is a list of Apple targets to be used for Starlark unit tests. These may not build correctly
# since most of them do not have any source dependencies, so they are all tagged as manual and
# notap to avoid them being built/tested when testing the
# //test/... package.

apple_bundle_version(
    name = "manual_1_2_build_1_2_3_version",
    build_version = "1.2.3",
    short_version_string = "1.2",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "manual_1_2_build_1_2_3_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":manual_1_2_build_1_2_3_version",
)

apple_bundle_version(
    name = "only_build_version_1_2_3_version",
    build_version = "1.2.3",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "only_build_version_1_2_3_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":only_build_version_1_2_3_version",
)

apple_bundle_version(
    name = "build_label_substitution_from_fallback_label_version",
    build_label_pattern = "MyApp_{version}_RC0*{candidate}",
    build_version = "{version}.{candidate}",
    capture_groups = {
        # Testing double-escaped regex format. Buildifier errors when using single "\" chars
        # that are not part of Buildifier's known escape sequences.
        "version": "\\d+\\.\\d+",
        "candidate": "\\d+",
    },
    fallback_build_label = "MyApp_99.99_RC99",
    short_version_string = "{version}",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "build_label_substitution_from_fallback_label_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":build_label_substitution_from_fallback_label_version",
)

apple_bundle_version(
    name = "short_version_string_defaults_to_build_version_substitution_version",
    build_label_pattern = "MyApp_{version}_RC0*{candidate}",
    build_version = "{version}.{candidate}",
    capture_groups = {
        "version": "\\d+\\.\\d+",
        "candidate": "\\d+",
    },
    fallback_build_label = "MyApp_1.2_RC03",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "short_version_string_defaults_to_build_version_substitution_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":short_version_string_defaults_to_build_version_substitution_version",
)

apple_bundle_version(
    name = "pattern_referencing_missing_capture_groups_fail",
    build_label_pattern = "MyApp_{version}_RC00",
    build_version = "{version}.{candidate}",
    capture_groups = {
        "version": "\\d+",
    },
    fallback_build_label = "MyApp_1.2_RC03",
    tags = common.fixture_tags,
)

apple_bundle_version(
    name = "build_label_pattern_requires_capture_groups_fail",
    build_label_pattern = "MyApp_{version}_RC0*{candidate}",
    build_version = "{version}.{candidate}",
    fallback_build_label = "MyApp_1.2_RC03",
    tags = common.fixture_tags,
)

apple_bundle_version(
    name = "capture_groups_requires_build_label_pattern_fail",
    build_version = "{version}.{candidate}",
    capture_groups = {
        "foo": "bar",
    },
    fallback_build_label = "MyApp_1.2_RC03",
    tags = common.fixture_tags,
)

apple_bundle_version(
    name = "fallback_build_label_requires_build_label_pattern_fail",
    build_version = "1.2",
    fallback_build_label = "MyApp_1.2_RC03",
    tags = common.fixture_tags,
)

apple_bundle_version(
    name = "no_substitution_if_build_label_not_present_version",
    build_label_pattern = "MyApp_{version}_RC0*{candidate}",
    build_version = "{version}.{candidate}",
    capture_groups = {
        # Testing regex using [] character classes that don't need extra escaping.
        "version": "[0-9]+[.][0-9]+",
        "candidate": "[0-9]+",
    },
    short_version_string = "{version}",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "no_substitution_if_build_label_not_present_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":no_substitution_if_build_label_not_present_version",
)

apple_bundle_version(
    name = "build_label_pattern_does_not_short_circuit_literal_version",
    build_label_pattern = "MyApp_{version}_RC0*{candidate}",
    build_version = "1.2.3",
    capture_groups = {
        "version": "[0-9]+[.][0-9]+",
        "candidate": "[0-9]+",
    },
    short_version_string = "1.2",
    tags = common.fixture_tags,
)

macos_bundle(
    name = "build_label_pattern_does_not_short_circuit_literal_bundle",
    bundle_id = "com.google.example",
    infoplists = ["//test/starlark_tests/resources:Info.plist"],
    minimum_os_version = common.min_os_macos.baseline,
    tags = common.fixture_tags,
    version = ":build_label_pattern_does_not_short_circuit_literal_version",
)

sh_binary(
    name = "ipa_post_processor_verify_codesigning",
    srcs = [
        "ipa_post_processor_verify_codesigning.sh",
    ],
    tags = ["requires-darwin"],
)

apple_core_data_model(
    name = "swift_data_model",
    srcs = [
        "//test/starlark_tests/resources:swift_datamodel",
    ],
)

apple_core_data_model(
    name = "objc_data_model",
    srcs = [
        "//test/starlark_tests/resources:objc_datamodel",
    ],
)

apple_core_data_model(
    name = "combined_swift_objc_data_model",
    srcs = [
        "//test/starlark_tests/resources:objc_datamodel",
        "//test/starlark_tests/resources:swift_datamodel",
    ],
)

apple_core_data_model(
    name = "no_code_generation_data_model",
    srcs = [
        "//test/starlark_tests/resources:no_code_generation_datamodel",
    ],
)

objc_library(
    name = "fmwk_lib",
    srcs = [
        "//test/starlark_tests/resources:shared.h",
        "//test/starlark_tests/resources:shared.m",
    ],
    tags = common.fixture_tags,
)

objc_library(
    name = "objc_lib_with_sdk_dylibs_and_sdk_framework",
    srcs = [
        "//test/starlark_tests/resources:shared.h",
        "//test/starlark_tests/resources:shared.m",
    ],
    linkopts = ["-lc++"],
    sdk_dylibs = ["libsqlite3"],
    sdk_frameworks = ["UIKit"],
    tags = common.fixture_tags,
)

swift_library(
    name = "swift_lib_for_static_xcfmwk",
    srcs = ["DummyFmwk.swift"],
    library_evolution = True,
    module_name = "ios_static_xcfmwk_with_swift",
    tags = common.fixture_tags,
)

swift_library(
    name = "swift_lib_for_static_xcfmwk_with_headers",
    srcs = ["DummyFmwk.swift"],
    generates_header = True,
    library_evolution = True,
    module_name = "ios_static_xcfmwk_with_swift_generated_headers",
    tags = common.fixture_tags,
)

swift_library(
    name = "swift_lib_for_static_xcfmwk_custom_bundle_name",
    srcs = ["DummyFmwk.swift"],
    generates_header = True,
    library_evolution = True,
    module_name = "ios_static_xcfmwk_with_custom_bundle_name",
    tags = common.fixture_tags,
)

swift_library(
    name = "swift_fmwk_lib",
    srcs = [
        "DummyFmwk.swift",
    ],
    library_evolution = True,
    module_name = "ios_dynamic_lipoed_swift_xcframework",
    tags = common.fixture_tags,
)

dummy_test_runner(
    name = "dummy_test_runner",
)

apple_xcframework(
    name = "ios_dynamic_xcframework",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "tvos_dynamic_xcframework",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "tvos": common.min_os_tvos.baseline,
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    tvos = {
        "simulator": [
            "x86_64",
            "arm64",
        ],
        "device": ["arm64"],
    },
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_lipoed_xcframework",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": [
            "arm64",
            "x86_64",
        ],
        "device": [
            "arm64",
            "arm64e",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_lipoed_swift_xcframework",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": [
            "arm64",
            "x86_64",
        ],
        "device": [
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    tags = common.fixture_tags,
    deps = [":swift_fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_exclusively_ipad_device_family",
    bundle_id = "com.google.example",
    families_required = {
        "ios": ["ipad"],
    },
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
        "//test/starlark_tests/resources:Another.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_multiple_infoplists",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
        "//test/starlark_tests/resources:Another.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_with_data_resource_bundle",
    bundle_id = "com.google.example",
    data = [
        "//test/starlark_tests/resources:Another.plist",
        "//test/starlark_tests/resources:resource_bundle",
    ],
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_with_deps_resource_bundle",
    bundle_id = "com.google.example",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [
        ":fmwk_lib",
        "//test/starlark_tests/resources:resource_bundle",
    ],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_stripped",
    bundle_id = "com.google.example",
    exported_symbols_lists = [
        "//test/starlark_tests/resources:ExportAnotherFunctionShared.exp",
    ],
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    linkopts = ["-x"],
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_stripped_two_exported_symbols_lists",
    bundle_id = "com.google.example",
    exported_symbols_lists = [
        "//test/starlark_tests/resources:ExportAnotherFunctionShared.exp",
        "//test/starlark_tests/resources:ExportDontCallMeShared.exp",
    ],
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    linkopts = ["-x"],
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_dead_stripped",
    bundle_id = "com.google.example",
    exported_symbols_lists = [
        "//test/starlark_tests/resources:ExportAnotherFunctionShared.exp",
    ],
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    linkopts = ["-dead_strip"],
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_xcframework(
    name = "ios_swift_xcframework_with_generated_header",
    bundle_id = "com.google.example",
    bundle_name = "SwiftFmwkWithGenHeader",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": [
            "arm64",
            "x86_64",
        ],
        "device": [
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":SwiftFmwkWithGenHeader"],
)

apple_xcframework(
    name = "ios_dynamic_xcframework_with_umbrella_header_conflict",
    bundle_id = "com.google.example",
    bundle_name = "UmbrellaHeaderConflict",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    infoplists = [
        "//test/starlark_tests/resources:Info.plist",
    ],
    ios = {
        "simulator": ["x86_64"],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
        "//test/starlark_tests/resources:UmbrellaHeaderConflict.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_static_xcframework(
    name = "ios_static_xcframework_oldest_supported",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "simulator": [
            "x86_64",
            "arm64",
        ],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.oldest_supported,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_static_xcframework(
    name = "ios_static_xcframework_objc_with_no_public_headers",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "simulator": [
            "x86_64",
            "arm64",
        ],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.oldest_supported,
    },
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

apple_static_xcframework(
    name = "ios_static_xcfmwk_with_avoid_deps",
    avoid_deps = [":StaticFmwkLowerLib"],
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "simulator": [
            "x86_64",
            "arm64",
        ],
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    tags = common.fixture_tags,
    deps = [":StaticFmwkUpperLib"],
)

apple_static_xcframework(
    name = "ios_static_xcfmwk_with_objc_sdk_dylibs_and_and_sdk_frameworks",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "device": ["arm64"],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":objc_lib_with_sdk_dylibs_and_sdk_framework"],
)

apple_static_xcframework(
    name = "ios_static_xcfmwk_with_swift",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "device": ["arm64"],
        "simulator": [
            "x86_64",
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    tags = common.fixture_tags,
    deps = [":swift_lib_for_static_xcfmwk"],
)

apple_static_xcframework(
    name = "ios_static_xcfmwk_with_swift_and_bundle_name",
    bundle_name = "ios_static_xcfmwk_with_custom_bundle_name",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "device": ["arm64"],
        "simulator": [
            "x86_64",
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    tags = common.fixture_tags,
    deps = [":swift_lib_for_static_xcfmwk_custom_bundle_name"],
)

apple_static_xcframework(
    name = "ios_static_xcfmwk_with_swift_generated_headers",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "device": ["arm64"],
        "simulator": [
            "x86_64",
            "arm64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    tags = common.fixture_tags,
    deps = [":swift_lib_for_static_xcfmwk_with_headers"],
)

apple_static_xcframework(
    name = "ios_static_xcframework",
    # TODO(b/239957001): Remove this when the rule no longer forces library
    # evolution.
    features = ["apple.no_legacy_swiftinterface"],
    ios = {
        "simulator": [
            "arm64",
            "x86_64",
        ],
        "device": [
            "arm64",
            "x86_64",
        ],
    },
    minimum_os_versions = {
        "ios": common.min_os_ios.baseline,
    },
    public_hdrs = [
        "//test/starlark_tests/resources:shared.h",
    ],
    tags = common.fixture_tags,
    deps = [":fmwk_lib"],
)

genrule(
    name = "dummy_fmwk_objc_hdr",
    outs = ["DummyFmwk.h"],
    cmd = "echo '#ifndef SDK_FRAMEWORK_H_\n#define SDK_FRAMEWORK_H_\n void doStuff(); \n#endif\n// SDK_FRAMEWORK_H_' > $@",
)

genrule(
    name = "dummy_fmwk_objc_src",
    outs = ["DummyFmwk.m"],
    cmd = "echo '#import <Foundation/Foundation.h>\nvoid doStuff() { NSLog(@\"Framework method called\"); }' > $@",
)

genrule(
    name = "dummy_fmwk_cc_src",
    outs = ["DummyFmwk.c"],
    cmd = "echo '#include <stdio.h>\nvoid doStuff() { printf(\"Framework method called\\n\"); }' > $@",
)

genrule(
    name = "dummy_fmwk_swift_src",
    outs = ["DummyFmwk.swift"],
    cmd = "echo 'import Foundation\n@objc public class SharedClass: NSObject {\n@objc public func doSomethingShared() {\nNSLog(\"Doing something shared!\")\n}\n}\n' > $@",
)

genrule(
    name = "dummy_fmwk_dependent_objc_src",
    outs = ["DummyFmwkDependent.m"],
    cmd = "echo '#import <Foundation/Foundation.h>\nvoid frameworkDependent() { NSLog(@\"frameworkDependent() called\"); }' > $@",
)

genrule(
    name = "dummy_fmwk_dependent_cc_src",
    outs = ["DummyFmwkDependent.c"],
    cmd = "echo '#include <stdio.h>\nvoid frameworkDependent() { printf(\"frameworkDependent() called\\n\"); }' > $@",
)

objc_library(
    name = "StaticFmwkUpperLib",
    srcs = [
        "DummyFmwk.h",
        "DummyFmwk.m",
    ],
    tags = common.fixture_tags,
    deps = [":StaticFmwkLowerLib"],
)

objc_library(
    name = "StaticFmwkCcUpperLib",
    srcs = [
        "DummyFmwk.c",
        "DummyFmwk.h",
    ],
    tags = common.fixture_tags,
    deps = [":StaticFmwkCcLowerLib"],
)

objc_library(
    name = "StaticFmwkLowerLib",
    srcs = ["DummyFmwkDependent.m"],
    tags = common.fixture_tags,
)

cc_library(
    name = "StaticFmwkCcLowerLib",
    srcs = ["DummyFmwkDependent.c"],
    tags = common.fixture_tags,
)

swift_library(
    name = "SwiftFmwkWithGenHeader",
    srcs = ["DummyFmwk.swift"],
    generates_header = True,
    library_evolution = True,
    module_name = "SwiftFmwkWithGenHeader",
    tags = common.fixture_tags,
)

apple_universal_binary(
    name = "multi_arch_cc_binary",
    binary = "//test/starlark_tests/resources:cc_test_binary",
    minimum_os_version = common.min_os_macos.arm64_support,
    platform_type = "macos",
    tags = common.fixture_tags,
)

apple_universal_binary(
    name = "multi_arch_forced_cpus_cc_binary",
    binary = "//test/starlark_tests/resources:cc_test_binary",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = common.min_os_macos.arm64_support,
    platform_type = "macos",
    tags = common.fixture_tags,
)

# ---------------------------------------------------------------------------------------
# Targets for Apple dynamic XCFramework import tests.

apple_dynamic_xcframework_import(
    name = "ios_imported_xcframework_with_libraries",
    visibility = ["//visibility:public"],
    xcframework_imports = [":generated_static_xcframework"],
)

generate_static_xcframework(
    name = "generated_static_xcframework",
    srcs = ["@bazel_tools//tools/objc:objc_dummy.mm"],
    minimum_os_versions = {
        "ios_simulator": common.min_os_ios.baseline,
        "ios": common.min_os_ios.baseline,
    },
    platforms = {
        "ios_simulator": [
            "x86_64",
            "arm64",
        ],
        "ios": ["arm64"],
    },
)

# ---------------------------------------------------------------------------------------
# Targets for Apple static XCFramework import tests.

apple_static_xcframework_import(
    name = "ios_imported_xcframework_with_static_frameworks",
    visibility = ["//visibility:public"],
    xcframework_imports = [":generated_dynamic_xcframework"],
)

generate_dynamic_xcframework(
    name = "generated_dynamic_xcframework",
    srcs = ["@bazel_tools//tools/objc:objc_dummy.mm"],
    minimum_os_versions = {
        "ios_simulator": common.min_os_ios.baseline,
        "ios": common.min_os_ios.baseline,
    },
    platforms = {
        "ios_simulator": [
            "x86_64",
            "arm64",
        ],
        "ios": ["arm64"],
    },
)
