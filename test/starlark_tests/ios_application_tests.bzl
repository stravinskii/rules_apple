# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""ios_application Starlark tests."""

load(
    ":common.bzl",
    "common",
)
load(
    "//apple/build_settings:build_settings.bzl",
    "build_settings_labels",
)
load(
    "//test/starlark_tests/rules:apple_verification_test.bzl",
    "apple_verification_test",
)
load(
    "//test/starlark_tests/rules:analysis_target_actions_test.bzl",
    "analysis_target_actions_tree_artifacts_outputs_test",
)
load(
    "//test/starlark_tests/rules:analysis_target_outputs_test.bzl",
    "analysis_target_outputs_test",
    "analysis_target_tree_artifacts_outputs_test",
)
load(
    "//test/starlark_tests/rules:common_verification_tests.bzl",
    "apple_symbols_file_test",
    "archive_contents_test",
)
load(
    "//test/starlark_tests/rules:dsyms_test.bzl",
    "dsyms_test",
)
load(
    "//test/starlark_tests/rules:infoplist_contents_test.bzl",
    "infoplist_contents_test",
)
load(
    "//test/starlark_tests/rules:output_group_zip_contents_test.bzl",
    "output_group_zip_contents_test",
)
load(
    "//test/starlark_tests/rules:linkmap_test.bzl",
    "linkmap_test",
)
load(
    "//test/starlark_tests/rules:analysis_failure_message_test.bzl",
    "analysis_failure_message_test",
)

def ios_application_test_suite(name):
    """Test suite for ios_application.

    Args:
      name: the base name to be used in things created by this macro
    """
    analysis_target_outputs_test(
        name = "{}_ipa_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        expected_outputs = ["app.ipa"],
        tags = [name],
    )
    analysis_target_tree_artifacts_outputs_test(
        name = "{}_tree_artifact_outputs_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        expected_outputs = ["app_minimal.app"],
        tags = [name],
    )

    archive_contents_test(
        name = "{}_tree_artifact_contents_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        build_settings = {
            build_settings_labels.use_tree_artifacts_outputs: "True",
        },
        contains = [
            "$BUNDLE_ROOT/Info.plist",
            "$BUNDLE_ROOT/PkgInfo",
            "$BUNDLE_ROOT/app_minimal",
        ],
        tags = [name],
    )

    analysis_target_actions_tree_artifacts_outputs_test(
        name = "{}_registers_action_for_tree_artifact_bundling_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        target_mnemonic = "BundleTreeApp",
        not_expected_mnemonic = ["BundleApp"],
        tags = [name],
    )

    apple_verification_test(
        name = "{}_ext_and_fmwk_provisioned_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_ext_and_fmwk_provisioned",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_ext_and_fmwk_provisioned_codesign_asan_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_ext_and_fmwk_provisioned",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        sanitizer = "asan",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_fmwk",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_imported_fmwk_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_imported_fmwk",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    # Verify ios_application with imported dynamic framework bundles files for Objective-C/Swift
    archive_contents_test(
        name = "{}_with_imported_dynamic_fmwk_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_imported_fmwk",
        contains = [
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Info.plist",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/iOSDynamicFramework",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Resources/iOSDynamicFramework.bundle/Info.plist",
        ],
        not_contains = [
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Headers/SharedClass.h",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Headers/iOSDynamicFramework.h",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Modules/module.modulemap",
        ],
        tags = [name],
    )
    archive_contents_test(
        name = "{}_swift_with_imported_dynamic_fmwk_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:swift_app_with_imported_dynamic_fmwk",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libswiftCore.dylib",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Info.plist",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/iOSDynamicFramework",
        ],
        not_contains = [
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Headers/SharedClass.h",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Headers/iOSDynamicFramework.h",
            "$BUNDLE_ROOT/Frameworks/iOSDynamicFramework.framework/Modules/module.modulemap",
        ],
        tags = [name],
    )

    # Verify ios_application with imported static framework contains symbols for Objective-C/Swift,
    # and resource bundles; but does not bundle the static library.
    archive_contents_test(
        name = "{}_with_imported_static_fmwk_contains_symbols_and_bundles_resources".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_imported_static_fmwk",
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        binary_contains_symbols = [
            "-[SharedClass doSomethingShared]",
            "_OBJC_CLASS_$_SharedClass",
        ],
        is_not_binary_plist = ["$BUNDLE_ROOT/iOSStaticFramework.bundle/Info.plist"],
        contains = ["$BUNDLE_ROOT/iOSStaticFramework.bundle/Info.plist"],
        not_contains = ["$BUNDLE_ROOT/Frameworks/iOSStaticFramework.framework"],
        tags = [name],
    )
    archive_contents_test(
        name = "{}_with_imported_swift_static_fmwk_contains_symbols_and_not_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_imported_swift_static_fmwk",
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        binary_contains_symbols = [
            "_OBJC_CLASS_$__TtC23iOSSwiftStaticFramework11SharedClass",
        ],
        not_contains = ["$BUNDLE_ROOT/Frameworks/iOSSwiftStaticFramework.framework"],
        tags = [name],
    )
    archive_contents_test(
        name = "{}_with_imported_swift_static_fmwk_and_no_swift_module_interface_file_contains_symbols_and_not_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_imported_swift_static_fmwk_without_module_interface_files",
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        binary_contains_symbols = [
            "_OBJC_CLASS_$__TtC23iOSSwiftStaticFramework11SharedClass",
        ],
        contains = ["$BUNDLE_ROOT/Frameworks/libswiftCore.dylib"],
        not_contains = ["$BUNDLE_ROOT/Frameworks/iOSSwiftStaticFramework.framework"],
        tags = [name],
    )
    archive_contents_test(
        name = "{}_swift_with_imported_static_fmwk_contains_symbols_and_not_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:swift_app_with_imported_static_fmwk",
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        binary_contains_symbols = [
            "-[SharedClass doSomethingShared]",
            "_OBJC_CLASS_$_SharedClass",
        ],
        contains = ["$BUNDLE_ROOT/Frameworks/libswiftCore.dylib"],
        not_contains = ["$BUNDLE_ROOT/Frameworks/iOSStaticFramework.framework"],
        tags = [name],
    )
    archive_contents_test(
        name = "{}_swift_with_imported_swift_static_fmwk_contains_symbols_and_not_bundles_files".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:swift_app_with_imported_swift_static_fmwk",
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        binary_contains_symbols = ["_OBJC_CLASS_$__TtC23iOSSwiftStaticFramework11SharedClass"],
        contains = ["$BUNDLE_ROOT/Frameworks/libswiftCore.dylib"],
        not_contains = ["$BUNDLE_ROOT/Frameworks/iOSSwiftStaticFramework.framework"],
        tags = [name],
    )

    apple_verification_test(
        name = "{}_fmwk_with_imported_fmwk_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_fmwk_importing_fmwk",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_fmwk_in_fmwk_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_fmwk_with_fmwk",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_fmwk_in_fmwk_provisioned_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_fmwk_with_fmwk_provisioned",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_two_fmwk_provisioned_codesign_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_two_fmwk_provisioned",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_entitlements_simulator_test".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        verifier_script = "verifier_scripts/entitlements_verifier.sh",
        tags = [name],
    )

    apple_verification_test(
        name = "{}_entitlements_device_test".format(name),
        build_type = "device",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        verifier_script = "verifier_scripts/entitlements_verifier.sh",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_dbg_resources_simulator_test".format(name),
        build_type = "simulator",
        compilation_mode = "dbg",
        is_binary_plist = ["$BUNDLE_ROOT/resource_bundle.bundle/Info.plist"],
        is_not_binary_plist = ["$BUNDLE_ROOT/Another.plist"],
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_opt_resources_simulator_test".format(name),
        build_type = "simulator",
        compilation_mode = "opt",
        is_binary_plist = [
            "$BUNDLE_ROOT/resource_bundle.bundle/Info.plist",
            "$BUNDLE_ROOT/Another.plist",
        ],
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_dbg_resources_device_test".format(name),
        build_type = "device",
        compilation_mode = "dbg",
        is_binary_plist = ["$BUNDLE_ROOT/resource_bundle.bundle/Info.plist"],
        is_not_binary_plist = ["$BUNDLE_ROOT/Another.plist"],
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_opt_resources_device_test".format(name),
        build_type = "device",
        compilation_mode = "opt",
        is_binary_plist = [
            "$BUNDLE_ROOT/resource_bundle.bundle/Info.plist",
            "$BUNDLE_ROOT/Another.plist",
        ],
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_opt_strings_simulator_test".format(name),
        build_type = "simulator",
        compilation_mode = "opt",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        contains = [
            "$RESOURCE_ROOT/localization.bundle/en.lproj/files.stringsdict",
            "$RESOURCE_ROOT/localization.bundle/en.lproj/greetings.strings",
        ],
        tags = [name],
    )

    dsyms_test(
        name = "{}_dsyms_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        expected_direct_dsyms = ["app.app"],
        expected_transitive_dsyms = ["app.app"],
        tags = [name],
    )

    dsyms_test(
        name = "{}_transitive_dsyms_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_ext_and_fmwk_provisioned",
        expected_direct_dsyms = ["app_with_ext_and_fmwk_provisioned.app"],
        expected_transitive_dsyms = ["app_with_ext_and_fmwk_provisioned.app", "ext_with_fmwk_provisioned.appex", "fmwk_with_provisioning.framework"],
        tags = [name],
    )

    infoplist_contents_test(
        name = "{}_plist_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        expected_values = {
            "BuildMachineOSBuild": "*",
            "CFBundleExecutable": "app",
            "CFBundleIdentifier": "com.google.example",
            "CFBundleName": "app",
            "CFBundlePackageType": "APPL",
            "CFBundleSupportedPlatforms:0": "iPhone*",
            "DTCompiler": "com.apple.compilers.llvm.clang.1_0",
            "DTPlatformBuild": "*",
            "DTPlatformName": "iphone*",
            "DTPlatformVersion": "*",
            "DTSDKBuild": "*",
            "DTSDKName": "iphone*",
            "DTXcode": "*",
            "DTXcodeBuild": "*",
            "MinimumOSVersion": common.min_os_ios.baseline,
            "UIDeviceFamily:0": "1",
        },
        tags = [name],
    )

    infoplist_contents_test(
        name = "{}_multiple_plist_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_multiple_infoplists",
        expected_values = {
            "AnotherKey": "AnotherValue",
            "CFBundleExecutable": "app_multiple_infoplists",
        },
        tags = [name],
    )

    # Tests that the archive contains .symbols package files when `include_symbols_in_bundle`
    # is enabled.
    apple_symbols_file_test(
        name = "{}_archive_contains_apple_symbols_files_test".format(name),
        binary_paths = [
            "Payload/app_with_ext_and_fmwk_and_symbols_in_bundle.app/app_with_ext_and_fmwk_and_symbols_in_bundle",
            "Payload/app_with_ext_and_fmwk_and_symbols_in_bundle.app/PlugIns/ext_with_fmwk_provisioned.appex/ext_with_fmwk_provisioned",
            "Payload/app_with_ext_and_fmwk_and_symbols_in_bundle.app/Frameworks/fmwk_with_provisioning.framework/fmwk_with_provisioning",
        ],
        build_type = "simulator",
        tags = [name],
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_ext_and_fmwk_and_symbols_in_bundle",
    )

    # Tests that the linkmap outputs are produced when `--objc_generate_linkmap`
    # is present.
    linkmap_test(
        name = "{}_linkmap_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        tags = [name],
    )

    # Tests that the provisioning profile is present when built for device.
    archive_contents_test(
        name = "{}_contains_provisioning_profile_test".format(name),
        build_type = "device",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        contains = [
            "$BUNDLE_ROOT/embedded.mobileprovision",
        ],
        tags = [name],
    )

    archive_contents_test(
        name = "{}_contains_asan_dylib_simulator_test".format(name),
        build_type = "simulator",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libclang_rt.asan_iossim_dynamic.dylib",
        ],
        sanitizer = "asan",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_contains_asan_dylib_device_test".format(name),
        build_type = "device",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libclang_rt.asan_ios_dynamic.dylib",
        ],
        sanitizer = "asan",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_contains_tsan_dylib_device_test".format(name),
        build_type = "simulator",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libclang_rt.tsan_iossim_dynamic.dylib",
        ],
        sanitizer = "tsan",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_contains_ubsan_dylib_simulator_test".format(name),
        build_type = "simulator",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libclang_rt.ubsan_iossim_dynamic.dylib",
        ],
        sanitizer = "ubsan",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_contains_ubsan_dylib_device_test".format(name),
        build_type = "device",
        contains = [
            "$BUNDLE_ROOT/Frameworks/libclang_rt.ubsan_ios_dynamic.dylib",
        ],
        sanitizer = "ubsan",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_minimal",
        tags = [name],
    )

    # Tests analysis phase failure when an extension depends on a framework which
    # is not marked extension_safe.
    analysis_failure_message_test(
        name = "{}_fails_with_extension_depending_on_not_extension_safe_framework".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app_with_ext_with_fmwk_not_extension_safe",
        expected_error = (
            "The target {package}:ext_with_fmwk_not_extension_safe is for an extension but its " +
            "framework dependency {package}:fmwk_not_extension_safe is not marked extension-safe." +
            " Specify 'extension_safe = 1' on the framework target."
        ).format(
            package = "//test/starlark_tests/targets_under_test/ios",
        ),
        tags = [name],
    )

    output_group_zip_contents_test(
        name = "{}_has_combined_zip_output_group".format(name),
        build_type = "device",
        target_under_test = "//test/starlark_tests/targets_under_test/ios:app",
        output_group_name = "combined_dossier_zip",
        output_group_file_shortpath = "third_party/bazel_rules/rules_apple/test/starlark_tests/targets_under_test/ios/app_dossier_with_bundle.zip",
        contains = [
            "bundle/Payload/app.app/Info.plist",
            "bundle/Payload/app.app/app",
            "dossier/manifest.json",
        ],
        tags = [name],
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
