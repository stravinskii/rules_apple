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

"""Implementation of tvOS rules."""

load(
    "@build_bazel_rules_apple//apple/internal/utils:clang_rt_dylibs.bzl",
    "clang_rt_dylibs",
)
load(
    "@build_bazel_rules_apple//apple/internal:apple_product_type.bzl",
    "apple_product_type",
)
load(
    "@build_bazel_rules_apple//apple/internal:apple_toolchains.bzl",
    "AppleMacToolsToolchainInfo",
    "AppleXPlatToolsToolchainInfo",
)
load(
    "@build_bazel_rules_apple//apple/internal:bundling_support.bzl",
    "bundling_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:cc_info_support.bzl",
    "cc_info_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:entitlements_support.bzl",
    "entitlements_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:features_support.bzl",
    "features_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:linking_support.bzl",
    "linking_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:outputs.bzl",
    "outputs",
)
load(
    "@build_bazel_rules_apple//apple/internal:partials.bzl",
    "partials",
)
load(
    "@build_bazel_rules_apple//apple/internal:platform_support.bzl",
    "platform_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:processor.bzl",
    "processor",
)
load(
    "@build_bazel_rules_apple//apple/internal:resources.bzl",
    "resources",
)
load(
    "@build_bazel_rules_apple//apple/internal:rule_attrs.bzl",
    "rule_attrs",
)
load(
    "@build_bazel_rules_apple//apple/internal:rule_factory.bzl",
    "rule_factory",
)
load(
    "@build_bazel_rules_apple//apple/internal:rule_support.bzl",
    "rule_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:run_support.bzl",
    "run_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:swift_support.bzl",
    "swift_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:transition_support.bzl",
    "transition_support",
)
load(
    "@build_bazel_rules_apple//apple/internal/aspects:framework_provider_aspect.bzl",
    "framework_provider_aspect",
)
load(
    "@build_bazel_rules_apple//apple/internal/aspects:resource_aspect.bzl",
    "apple_resource_aspect",
)
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBundleInfo",
    "ApplePlatformInfo",
    "TvosApplicationBundleInfo",
    "TvosExtensionBundleInfo",
    "TvosFrameworkBundleInfo",
    "TvosStaticFrameworkBundleInfo",
)
load(
    "@build_bazel_rules_swift//swift:providers.bzl",
    "SwiftInfo",
)
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _tvos_application_impl(ctx):
    """Experimental implementation of tvos_application."""
    rule_descriptor = rule_support.rule_descriptor(
        platform_type = ctx.attr.platform_type,
        product_type = apple_product_type.application,
    )

    actions = ctx.actions
    apple_mac_toolchain_info = ctx.attr._mac_toolchain[AppleMacToolsToolchainInfo]
    apple_xplat_toolchain_info = ctx.attr._xplat_toolchain[AppleXPlatToolsToolchainInfo]
    bundle_id = ctx.attr.bundle_id
    bundle_name, bundle_extension = bundling_support.bundle_full_name(
        custom_bundle_name = ctx.attr.bundle_name,
        label_name = ctx.label.name,
        rule_descriptor = rule_descriptor,
    )
    bundle_verification_targets = [struct(target = ext) for ext in ctx.attr.extensions]
    embeddable_targets = ctx.attr.extensions + ctx.attr.frameworks + ctx.attr.deps
    features = features_support.compute_enabled_features(
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    label = ctx.label
    platform_prerequisites = platform_support.platform_prerequisites(
        apple_fragment = ctx.fragments.apple,
        build_settings = apple_xplat_toolchain_info.build_settings,
        config_vars = ctx.var,
        cpp_fragment = ctx.fragments.cpp,
        device_families = rule_descriptor.allowed_device_families,
        explicit_minimum_os = ctx.attr.minimum_os_version,
        objc_fragment = ctx.fragments.objc,
        platform_type_string = ctx.attr.platform_type,
        signing_certificate_name = apple_xplat_toolchain_info.build_settings.signing_certificate_name,
        uses_swift = swift_support.uses_swift(ctx.attr.deps),
        xcode_version_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )
    predeclared_outputs = ctx.outputs
    provisioning_profile = ctx.file.provisioning_profile
    resource_deps = ctx.attr.deps + ctx.attr.resources
    swift_dylib_dependencies = ctx.attr.extensions + ctx.attr.frameworks
    top_level_infoplists = resources.collect(
        attr = ctx.attr,
        res_attrs = ["infoplists"],
    )
    top_level_resources = resources.collect(
        attr = ctx.attr,
        res_attrs = [
            "app_icons",
            "launch_images",
            "launch_storyboard",
            "resources",
            "strings",
        ],
    )

    entitlements = entitlements_support.process_entitlements(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        bundle_id = bundle_id,
        entitlements_file = ctx.file.entitlements,
        platform_prerequisites = platform_prerequisites,
        product_type = rule_descriptor.product_type,
        provisioning_profile = provisioning_profile,
        rule_label = label,
        validation_mode = ctx.attr.entitlements_validation,
    )

    link_result = linking_support.register_binary_linking_action(
        ctx,
        avoid_deps = ctx.attr.frameworks,
        entitlements = entitlements,
        exported_symbols_lists = ctx.files.exported_symbols_lists,
        platform_prerequisites = platform_prerequisites,
        rule_descriptor = rule_descriptor,
        stamp = ctx.attr.stamp,
    )
    binary_artifact = link_result.binary
    debug_outputs = linking_support.debug_outputs_by_architecture(link_result.outputs)

    processor_partials = [
        partials.app_assets_validation_partial(
            app_icons = ctx.files.app_icons,
            launch_images = ctx.files.launch_images,
            platform_prerequisites = platform_prerequisites,
            product_type = rule_descriptor.product_type,
        ),
        partials.apple_bundle_info_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_id = bundle_id,
            bundle_name = bundle_name,
            entitlements = entitlements,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            product_type = rule_descriptor.product_type,
        ),
        partials.binary_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bundle_name = bundle_name,
            label_name = label.name,
        ),
        partials.bitcode_symbols_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bitcode_symbol_maps = debug_outputs.bitcode_symbol_maps,
            dependency_targets = embeddable_targets,
            label_name = label.name,
            package_bitcode = True,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.clang_rt_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            features = features,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            dylibs = clang_rt_dylibs.get_from_toolchain(ctx),
        ),
        partials.codesigning_dossier_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            apple_xplat_toolchain_info = apple_xplat_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            embedded_targets = embeddable_targets,
            entitlements = entitlements,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            provisioning_profile = provisioning_profile,
            rule_descriptor = rule_descriptor,
        ),
        partials.debug_symbols_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            debug_dependencies = embeddable_targets,
            dsym_binaries = debug_outputs.dsym_binaries,
            dsym_info_plist_template = apple_mac_toolchain_info.dsym_info_plist_template,
            linkmaps = debug_outputs.linkmaps,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.embedded_bundles_partial(
            bundle_embedded_bundles = True,
            embeddable_targets = embeddable_targets,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.framework_import_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            features = features,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            provisioning_profile = provisioning_profile,
            rule_descriptor = rule_descriptor,
            targets = ctx.attr.deps + embeddable_targets,
        ),
        partials.resources_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_id = bundle_id,
            bundle_name = bundle_name,
            bundle_verification_targets = bundle_verification_targets,
            environment_plist = ctx.file._environment_plist,
            launch_storyboard = ctx.file.launch_storyboard,
            platform_prerequisites = platform_prerequisites,
            resource_deps = resource_deps,
            rule_descriptor = rule_descriptor,
            rule_label = label,
            targets_to_avoid = ctx.attr.frameworks,
            top_level_infoplists = top_level_infoplists,
            top_level_resources = top_level_resources,
            version = ctx.attr.version,
        ),
        partials.settings_bundle_partial(
            actions = actions,
            platform_prerequisites = platform_prerequisites,
            rule_label = label,
            settings_bundle = ctx.attr.settings_bundle,
        ),
        partials.swift_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            bundle_dylibs = True,
            dependency_targets = swift_dylib_dependencies,
            label_name = label.name,
            package_swift_support_if_needed = True,
            platform_prerequisites = platform_prerequisites,
        ),
    ]

    if platform_prerequisites.platform.is_device:
        processor_partials.append(
            partials.provisioning_profile_partial(
                actions = actions,
                profile_artifact = provisioning_profile,
                rule_label = label,
            ),
        )

    processor_result = processor.process(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        apple_xplat_toolchain_info = apple_xplat_toolchain_info,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        entitlements = entitlements,
        features = features,
        ipa_post_processor = ctx.executable.ipa_post_processor,
        partials = processor_partials,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
        process_and_sign_template = apple_mac_toolchain_info.process_and_sign_template,
        provisioning_profile = provisioning_profile,
        rule_descriptor = rule_descriptor,
        rule_label = label,
    )

    executable = outputs.executable(
        actions = actions,
        label_name = label.name,
    )

    # TODO(b/254511920): Consider creating a custom build config for tvOS simulator device/version.
    run_support.register_simulator_executable(
        actions = actions,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        output = executable,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
        runner_template = ctx.file._runner_template,
    )

    archive = outputs.archive(
        actions = actions,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
    )

    return [
        DefaultInfo(
            executable = executable,
            files = processor_result.output_files,
            runfiles = ctx.runfiles(
                files = [archive],
            ),
        ),
        OutputGroupInfo(
            **outputs.merge_output_groups(
                link_result.output_groups,
                processor_result.output_groups,
            )
        ),
        TvosApplicationBundleInfo(),
        apple_common.new_executable_binary_provider(
            binary = binary_artifact,
            cc_info = link_result.cc_info,
            objc = link_result.objc,
        ),
        # TODO(b/228856372): Remove when downstream users are migrated off this provider.
        link_result.debug_outputs_provider,
    ] + processor_result.providers

def _tvos_framework_impl(ctx):
    """Experimental implementation of tvos_framework."""
    rule_descriptor = rule_support.rule_descriptor(
        platform_type = ctx.attr.platform_type,
        product_type = apple_product_type.framework,
    )

    actions = ctx.actions
    apple_mac_toolchain_info = ctx.attr._mac_toolchain[AppleMacToolsToolchainInfo]
    apple_xplat_toolchain_info = ctx.attr._xplat_toolchain[AppleXPlatToolsToolchainInfo]
    bin_root_path = ctx.bin_dir.path
    bundle_id = ctx.attr.bundle_id
    bundle_name, bundle_extension = bundling_support.bundle_full_name(
        custom_bundle_name = ctx.attr.bundle_name,
        label_name = ctx.label.name,
        rule_descriptor = rule_descriptor,
    )
    cc_toolchain = find_cpp_toolchain(ctx)
    cc_features = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        language = "objc",
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    features = features_support.compute_enabled_features(
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    label = ctx.label
    platform_prerequisites = platform_support.platform_prerequisites(
        apple_fragment = ctx.fragments.apple,
        build_settings = apple_xplat_toolchain_info.build_settings,
        config_vars = ctx.var,
        cpp_fragment = ctx.fragments.cpp,
        device_families = rule_descriptor.allowed_device_families,
        explicit_minimum_os = ctx.attr.minimum_os_version,
        objc_fragment = ctx.fragments.objc,
        platform_type_string = ctx.attr.platform_type,
        signing_certificate_name = apple_xplat_toolchain_info.build_settings.signing_certificate_name,
        uses_swift = swift_support.uses_swift(ctx.attr.deps),
        xcode_version_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )
    predeclared_outputs = ctx.outputs
    provisioning_profile = ctx.file.provisioning_profile
    resource_deps = ctx.attr.deps + ctx.attr.resources
    signed_frameworks = []
    if provisioning_profile:
        signed_frameworks = [
            bundle_name + rule_descriptor.bundle_extension,
        ]
    top_level_infoplists = resources.collect(
        attr = ctx.attr,
        res_attrs = ["infoplists"],
    )
    top_level_resources = resources.collect(
        attr = ctx.attr,
        res_attrs = ["resources"],
    )

    link_result = linking_support.register_binary_linking_action(
        ctx,
        avoid_deps = ctx.attr.frameworks,
        # Frameworks do not have entitlements.
        entitlements = None,
        exported_symbols_lists = ctx.files.exported_symbols_lists,
        extra_linkopts = [
            "-dynamiclib",
            "-install_name",
            "@rpath/{name}{extension}/{name}".format(
                extension = bundle_extension,
                name = bundle_name,
            ),
        ],
        platform_prerequisites = platform_prerequisites,
        rule_descriptor = rule_descriptor,
        stamp = ctx.attr.stamp,
    )
    binary_artifact = link_result.binary
    debug_outputs = linking_support.debug_outputs_by_architecture(link_result.outputs)

    archive = outputs.archive(
        actions = actions,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
    )

    processor_partials = [
        partials.apple_bundle_info_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_id = bundle_id,
            bundle_name = bundle_name,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            product_type = rule_descriptor.product_type,
        ),
        partials.binary_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bundle_name = bundle_name,
            label_name = label.name,
        ),
        partials.bitcode_symbols_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bitcode_symbol_maps = debug_outputs.bitcode_symbol_maps,
            dependency_targets = ctx.attr.frameworks,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
        ),
        # TODO(kaipi): Check if clang_rt dylibs are needed in Frameworks, or if
        # the can be skipped.
        partials.clang_rt_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            features = features,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            dylibs = clang_rt_dylibs.get_from_toolchain(ctx),
        ),
        partials.codesigning_dossier_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            apple_xplat_toolchain_info = apple_xplat_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_location = processor.location.framework,
            bundle_name = bundle_name,
            embed_target_dossiers = False,
            embedded_targets = ctx.attr.frameworks,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            provisioning_profile = provisioning_profile,
            rule_descriptor = rule_descriptor,
        ),
        partials.debug_symbols_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            debug_dependencies = ctx.attr.frameworks,
            dsym_binaries = debug_outputs.dsym_binaries,
            dsym_info_plist_template = apple_mac_toolchain_info.dsym_info_plist_template,
            linkmaps = debug_outputs.linkmaps,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.embedded_bundles_partial(
            frameworks = [archive],
            embeddable_targets = ctx.attr.frameworks,
            platform_prerequisites = platform_prerequisites,
            signed_frameworks = depset(signed_frameworks),
        ),
        partials.extension_safe_validation_partial(
            is_extension_safe = ctx.attr.extension_safe,
            rule_label = label,
            targets_to_validate = ctx.attr.frameworks,
        ),
        partials.framework_headers_partial(hdrs = ctx.files.hdrs),
        partials.framework_provider_partial(
            actions = actions,
            bin_root_path = bin_root_path,
            binary_artifact = binary_artifact,
            bundle_name = bundle_name,
            cc_features = cc_features,
            cc_info = link_result.cc_info,
            cc_toolchain = cc_toolchain,
            objc_provider = link_result.objc,
            rule_label = label,
        ),
        partials.resources_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_id = bundle_id,
            bundle_name = bundle_name,
            environment_plist = ctx.file._environment_plist,
            launch_storyboard = None,
            platform_prerequisites = platform_prerequisites,
            resource_deps = resource_deps,
            rule_descriptor = rule_descriptor,
            rule_label = label,
            targets_to_avoid = ctx.attr.frameworks,
            top_level_infoplists = top_level_infoplists,
            top_level_resources = top_level_resources,
            version = ctx.attr.version,
            version_keys_required = False,
        ),
        partials.swift_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            dependency_targets = ctx.attr.frameworks,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
        ),
    ]

    processor_result = processor.process(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        apple_xplat_toolchain_info = apple_xplat_toolchain_info,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        features = features,
        ipa_post_processor = ctx.executable.ipa_post_processor,
        partials = processor_partials,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
        process_and_sign_template = apple_mac_toolchain_info.process_and_sign_template,
        provisioning_profile = provisioning_profile,
        rule_descriptor = rule_descriptor,
        rule_label = label,
    )

    return [
        DefaultInfo(files = processor_result.output_files),
        OutputGroupInfo(
            **outputs.merge_output_groups(
                link_result.output_groups,
                processor_result.output_groups,
            )
        ),
        TvosFrameworkBundleInfo(),
        # TODO(b/228856372): Remove when downstream users are migrated off this provider.
        link_result.debug_outputs_provider,
    ] + processor_result.providers

def _tvos_extension_impl(ctx):
    """Experimental implementation of tvos_extension."""
    rule_descriptor = rule_support.rule_descriptor(
        platform_type = ctx.attr.platform_type,
        product_type = apple_product_type.app_extension,
    )

    actions = ctx.actions
    apple_mac_toolchain_info = ctx.attr._mac_toolchain[AppleMacToolsToolchainInfo]
    apple_xplat_toolchain_info = ctx.attr._xplat_toolchain[AppleXPlatToolsToolchainInfo]
    bundle_id = ctx.attr.bundle_id
    bundle_name, bundle_extension = bundling_support.bundle_full_name(
        custom_bundle_name = ctx.attr.bundle_name,
        label_name = ctx.label.name,
        rule_descriptor = rule_descriptor,
    )
    features = features_support.compute_enabled_features(
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    label = ctx.label
    platform_prerequisites = platform_support.platform_prerequisites(
        apple_fragment = ctx.fragments.apple,
        build_settings = apple_xplat_toolchain_info.build_settings,
        config_vars = ctx.var,
        cpp_fragment = ctx.fragments.cpp,
        device_families = rule_descriptor.allowed_device_families,
        explicit_minimum_os = ctx.attr.minimum_os_version,
        objc_fragment = ctx.fragments.objc,
        platform_type_string = ctx.attr.platform_type,
        signing_certificate_name = apple_xplat_toolchain_info.build_settings.signing_certificate_name,
        uses_swift = swift_support.uses_swift(ctx.attr.deps),
        xcode_version_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )
    predeclared_outputs = ctx.outputs
    provisioning_profile = ctx.file.provisioning_profile
    resource_deps = ctx.attr.deps + ctx.attr.resources
    top_level_infoplists = resources.collect(
        attr = ctx.attr,
        res_attrs = ["infoplists"],
    )
    top_level_resources = resources.collect(
        attr = ctx.attr,
        res_attrs = [
            "app_icons",
            "strings",
            "resources",
        ],
    )

    entitlements = entitlements_support.process_entitlements(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        bundle_id = bundle_id,
        entitlements_file = ctx.file.entitlements,
        platform_prerequisites = platform_prerequisites,
        product_type = rule_descriptor.product_type,
        provisioning_profile = provisioning_profile,
        rule_label = label,
        validation_mode = ctx.attr.entitlements_validation,
    )

    extra_linkopts = [
        "-e",
        "_TVExtensionMain",
        "-fapplication-extension",
        "-framework",
        "TVServices",
    ]

    link_result = linking_support.register_binary_linking_action(
        ctx,
        avoid_deps = ctx.attr.frameworks,
        entitlements = entitlements,
        exported_symbols_lists = ctx.files.exported_symbols_lists,
        extra_linkopts = extra_linkopts,
        platform_prerequisites = platform_prerequisites,
        rule_descriptor = rule_descriptor,
        stamp = ctx.attr.stamp,
    )
    binary_artifact = link_result.binary
    debug_outputs = linking_support.debug_outputs_by_architecture(link_result.outputs)

    archive = outputs.archive(
        actions = actions,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
    )

    processor_partials = [
        partials.apple_bundle_info_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            bundle_id = bundle_id,
            entitlements = entitlements,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            product_type = rule_descriptor.product_type,
        ),
        partials.binary_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bundle_name = bundle_name,
            label_name = label.name,
        ),
        partials.bitcode_symbols_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bitcode_symbol_maps = debug_outputs.bitcode_symbol_maps,
            dependency_targets = ctx.attr.frameworks,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.clang_rt_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            features = features,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            dylibs = clang_rt_dylibs.get_from_toolchain(ctx),
        ),
        partials.codesigning_dossier_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            apple_xplat_toolchain_info = apple_xplat_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_location = processor.location.plugin,
            bundle_name = bundle_name,
            embed_target_dossiers = False,
            embedded_targets = ctx.attr.frameworks,
            entitlements = entitlements,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            provisioning_profile = provisioning_profile,
            rule_descriptor = rule_descriptor,
        ),
        partials.debug_symbols_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            debug_dependencies = ctx.attr.frameworks,
            dsym_binaries = debug_outputs.dsym_binaries,
            dsym_info_plist_template = apple_mac_toolchain_info.dsym_info_plist_template,
            linkmaps = debug_outputs.linkmaps,
            platform_prerequisites = platform_prerequisites,
        ),
        partials.embedded_bundles_partial(
            embeddable_targets = ctx.attr.frameworks,
            platform_prerequisites = platform_prerequisites,
            plugins = [archive],
        ),
        partials.extension_safe_validation_partial(
            is_extension_safe = True,
            rule_label = label,
            targets_to_validate = ctx.attr.frameworks,
        ),
        partials.resources_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_id = bundle_id,
            bundle_name = bundle_name,
            environment_plist = ctx.file._environment_plist,
            launch_storyboard = None,
            platform_prerequisites = platform_prerequisites,
            resource_deps = resource_deps,
            rule_descriptor = rule_descriptor,
            rule_label = label,
            targets_to_avoid = ctx.attr.frameworks,
            top_level_infoplists = top_level_infoplists,
            top_level_resources = top_level_resources,
            version = ctx.attr.version,
        ),
        partials.swift_dylibs_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            binary_artifact = binary_artifact,
            dependency_targets = ctx.attr.frameworks,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
        ),
    ]

    if platform_prerequisites.platform.is_device:
        processor_partials.append(
            partials.provisioning_profile_partial(
                actions = actions,
                profile_artifact = provisioning_profile,
                rule_label = label,
            ),
        )

    processor_result = processor.process(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        apple_xplat_toolchain_info = apple_xplat_toolchain_info,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        entitlements = entitlements,
        features = features,
        ipa_post_processor = ctx.executable.ipa_post_processor,
        partials = processor_partials,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
        process_and_sign_template = apple_mac_toolchain_info.process_and_sign_template,
        provisioning_profile = provisioning_profile,
        rule_descriptor = rule_descriptor,
        rule_label = label,
    )

    return [
        DefaultInfo(
            files = processor_result.output_files,
        ),
        OutputGroupInfo(
            **outputs.merge_output_groups(
                link_result.output_groups,
                processor_result.output_groups,
            )
        ),
        TvosExtensionBundleInfo(),
        # TODO(b/228856372): Remove when downstream users are migrated off this provider.
        link_result.debug_outputs_provider,
    ] + processor_result.providers

def _tvos_static_framework_impl(ctx):
    """Implementation of tvos_static_framework."""
    rule_descriptor = rule_support.rule_descriptor(
        platform_type = ctx.attr.platform_type,
        product_type = apple_product_type.static_framework,
    )

    actions = ctx.actions
    apple_mac_toolchain_info = ctx.attr._mac_toolchain[AppleMacToolsToolchainInfo]
    apple_xplat_toolchain_info = ctx.attr._xplat_toolchain[AppleXPlatToolsToolchainInfo]
    avoid_deps = ctx.attr.avoid_deps
    cc_toolchain_forwarder = ctx.split_attr._cc_toolchain_forwarder
    deps = ctx.attr.deps
    label = ctx.label
    predeclared_outputs = ctx.outputs
    split_deps = ctx.split_attr.deps
    bundle_name, bundle_extension = bundling_support.bundle_full_name(
        custom_bundle_name = ctx.attr.bundle_name,
        label_name = ctx.label.name,
        rule_descriptor = rule_descriptor,
    )
    features = features_support.compute_enabled_features(
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    platform_prerequisites = platform_support.platform_prerequisites(
        apple_fragment = ctx.fragments.apple,
        build_settings = apple_xplat_toolchain_info.build_settings,
        config_vars = ctx.var,
        cpp_fragment = ctx.fragments.cpp,
        device_families = rule_descriptor.allowed_device_families,
        explicit_minimum_os = ctx.attr.minimum_os_version,
        objc_fragment = ctx.fragments.objc,
        platform_type_string = ctx.attr.platform_type,
        uses_swift = swift_support.uses_swift(ctx.attr.deps),
        xcode_version_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )
    resource_deps = ctx.attr.deps + ctx.attr.resources

    link_result = linking_support.register_static_library_linking_action(ctx = ctx)
    binary_artifact = link_result.library

    processor_partials = [
        partials.apple_bundle_info_partial(
            actions = actions,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            label_name = label.name,
            platform_prerequisites = platform_prerequisites,
            predeclared_outputs = predeclared_outputs,
            product_type = rule_descriptor.product_type,
        ),
        partials.binary_partial(
            actions = actions,
            binary_artifact = binary_artifact,
            bundle_name = bundle_name,
            label_name = label.name,
        ),
    ]

    swift_infos = {}
    if swift_support.uses_swift(deps):
        for split_attr_key, cc_toolchain in cc_toolchain_forwarder.items():
            apple_platform_info = cc_toolchain[ApplePlatformInfo]
            for dep in split_deps[split_attr_key]:
                if SwiftInfo in dep:
                    swift_infos[apple_platform_info.target_arch] = dep[SwiftInfo]

    # If there's any Swift dependencies on the static framework rule, treat it as a Swift static
    # framework.
    if swift_infos:
        processor_partials.append(
            partials.swift_framework_partial(
                actions = actions,
                avoid_deps = avoid_deps,
                bundle_name = bundle_name,
                label_name = label.name,
                swift_infos = swift_infos,
            ),
        )
    else:
        processor_partials.append(
            partials.framework_header_modulemap_partial(
                actions = actions,
                bundle_name = bundle_name,
                hdrs = ctx.files.hdrs,
                label_name = label.name,
                sdk_dylibs = cc_info_support.get_sdk_dylibs(deps = deps),
                sdk_frameworks = cc_info_support.get_sdk_frameworks(deps = deps),
                umbrella_header = ctx.file.umbrella_header,
            ),
        )

    if not ctx.attr.exclude_resources:
        processor_partials.append(partials.resources_partial(
            actions = actions,
            apple_mac_toolchain_info = apple_mac_toolchain_info,
            bundle_extension = bundle_extension,
            bundle_name = bundle_name,
            environment_plist = ctx.file._environment_plist,
            launch_storyboard = None,
            platform_prerequisites = platform_prerequisites,
            resource_deps = resource_deps,
            rule_descriptor = rule_descriptor,
            rule_label = label,
            version = ctx.attr.version,
        ))

    processor_result = processor.process(
        actions = actions,
        apple_mac_toolchain_info = apple_mac_toolchain_info,
        apple_xplat_toolchain_info = apple_xplat_toolchain_info,
        bundle_extension = bundle_extension,
        bundle_name = bundle_name,
        features = features,
        ipa_post_processor = ctx.executable.ipa_post_processor,
        partials = processor_partials,
        platform_prerequisites = platform_prerequisites,
        predeclared_outputs = predeclared_outputs,
        process_and_sign_template = apple_mac_toolchain_info.process_and_sign_template,
        rule_descriptor = rule_descriptor,
        rule_label = label,
    )

    return [
        DefaultInfo(files = processor_result.output_files),
        OutputGroupInfo(**processor_result.output_groups),
        TvosStaticFrameworkBundleInfo(),
    ] + processor_result.providers

tvos_application = rule_factory.create_apple_rule(
    doc = "Builds and bundles a tvOS Application.",
    implementation = _tvos_application_impl,
    is_executable = True,
    predeclared_outputs = {"archive": "%{name}.ipa"},
    attrs = [
        rule_attrs.app_icon_attrs(),
        rule_attrs.binary_linking_attrs(
            deps_cfg = apple_common.multi_arch_split,
            extra_deps_aspects = [
                apple_resource_aspect,
                framework_provider_aspect,
            ],
            is_test_supporting_rule = False,
            requires_legacy_cc_toolchain = True,
        ),
        rule_attrs.bundle_id_attrs(is_mandatory = True),
        rule_attrs.common_bundle_attrs,
        rule_attrs.common_tool_attrs,
        rule_attrs.device_family_attrs(
            allowed_families = rule_attrs.defaults.allowed_families.tvos,
        ),
        rule_attrs.entitlements_attrs,
        rule_attrs.infoplist_attrs(),
        rule_attrs.launch_images_attrs,
        rule_attrs.platform_attrs(
            add_environment_plist = True,
            platform_type = "tvos",
        ),
        rule_attrs.provisioning_profile_attrs(),
        rule_attrs.settings_bundle_attrs,
        rule_attrs.simulator_runner_template_attr,
        {
            "frameworks": attr.label_list(
                aspects = [framework_provider_aspect],
                providers = [[AppleBundleInfo, TvosFrameworkBundleInfo]],
                doc = """
A list of framework targets (see
[`tvos_framework`](https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-tvos.md#tvos_framework))
that this target depends on.
""",
            ),
            "extensions": attr.label_list(
                providers = [[AppleBundleInfo, TvosExtensionBundleInfo]],
                doc = "A list of tvOS extensions to include in the final application bundle.",
            ),
            "launch_storyboard": attr.label(
                allow_single_file = [".storyboard"],
                doc = """
The `.storyboard` file that should be used as the launch screen for the application. The provided
file will be compiled into the appropriate format (`.storyboardc`) and placed in the root of the
final bundle. The generated file will also be registered in the bundle's Info.plist under the key
`UILaunchStoryboardName`.
""",
            ),
        },
    ],
)

tvos_extension = rule_factory.create_apple_rule(
    doc = "Builds and bundles a tvOS Extension.",
    implementation = _tvos_extension_impl,
    predeclared_outputs = {"archive": "%{name}.zip"},
    attrs = [
        rule_attrs.binary_linking_attrs(
            deps_cfg = apple_common.multi_arch_split,
            extra_deps_aspects = [
                apple_resource_aspect,
                framework_provider_aspect,
            ],
            is_test_supporting_rule = False,
            requires_legacy_cc_toolchain = True,
        ),
        rule_attrs.bundle_id_attrs(is_mandatory = True),
        rule_attrs.common_bundle_attrs,
        rule_attrs.common_tool_attrs,
        rule_attrs.device_family_attrs(
            allowed_families = rule_attrs.defaults.allowed_families.tvos,
        ),
        rule_attrs.entitlements_attrs,
        rule_attrs.infoplist_attrs(),
        rule_attrs.platform_attrs(
            add_environment_plist = True,
            platform_type = "tvos",
        ),
        rule_attrs.provisioning_profile_attrs(),
        {
            "frameworks": attr.label_list(
                providers = [[AppleBundleInfo, TvosFrameworkBundleInfo]],
                doc = """
A list of framework targets (see
[`tvos_framework`](https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-tvos.md#tvos_framework))
that this target depends on.
""",
            ),
        },
    ],
)

tvos_framework = rule_factory.create_apple_rule(
    doc = "Builds and bundles a tvOS Dynamic Framework.",
    implementation = _tvos_framework_impl,
    predeclared_outputs = {"archive": "%{name}.zip"},
    attrs = [
        rule_attrs.binary_linking_attrs(
            deps_cfg = apple_common.multi_arch_split,
            extra_deps_aspects = [
                apple_resource_aspect,
                framework_provider_aspect,
            ],
            is_test_supporting_rule = False,
            requires_legacy_cc_toolchain = True,
        ),
        rule_attrs.bundle_id_attrs(is_mandatory = True),
        rule_attrs.common_bundle_attrs,
        rule_attrs.common_tool_attrs,
        rule_attrs.device_family_attrs(
            allowed_families = rule_attrs.defaults.allowed_families.tvos,
        ),
        rule_attrs.infoplist_attrs(),
        rule_attrs.platform_attrs(
            add_environment_plist = True,
            platform_type = "tvos",
        ),
        rule_attrs.provisioning_profile_attrs(),
        {
            "extension_safe": attr.bool(
                default = False,
                doc = """
If true, compiles and links this framework with `-application-extension`, restricting the binary to
use only extension-safe APIs.
""",
            ),
            "frameworks": attr.label_list(
                providers = [[AppleBundleInfo, TvosFrameworkBundleInfo]],
                doc = """
A list of framework targets (see
[`tvos_framework`](https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-tvos.md#tvos_framework))
that this target depends on.
""",
            ),
            # TODO(b/250090851): Document this attribute and its limitations.
            "hdrs": attr.label_list(
                allow_files = [".h"],
            ),
        },
    ],
)

_STATIC_FRAMEWORK_DEPS_CFG = transition_support.apple_platform_split_transition

tvos_static_framework = rule_factory.create_apple_rule(
    cfg = transition_support.apple_platforms_rule_base_transition,
    doc = "Builds and bundles a tvOS Static Framework.",
    implementation = _tvos_static_framework_impl,
    predeclared_outputs = {"archive": "%{name}.zip"},
    attrs = [
        rule_attrs.binary_linking_attrs(
            deps_cfg = _STATIC_FRAMEWORK_DEPS_CFG,
            extra_deps_aspects = [
                apple_resource_aspect,
                framework_provider_aspect,
            ],
            is_test_supporting_rule = False,
            requires_legacy_cc_toolchain = True,
        ),
        rule_attrs.cc_toolchain_forwarder_attrs(
            deps_cfg = _STATIC_FRAMEWORK_DEPS_CFG,
        ),
        rule_attrs.common_bundle_attrs,
        rule_attrs.common_tool_attrs,
        rule_attrs.device_family_attrs(
            allowed_families = rule_attrs.defaults.allowed_families.tvos,
        ),
        rule_attrs.platform_attrs(
            add_environment_plist = True,
            platform_type = "tvos",
        ),
        {
            "_emitswiftinterface": attr.bool(
                default = True,
                doc = "Private attribute to generate Swift interfaces for static frameworks.",
            ),
            "avoid_deps": attr.label_list(
                cfg = _STATIC_FRAMEWORK_DEPS_CFG,
                doc = """
A list of library targets on which this framework depends in order to compile, but the transitive
closure of which will not be linked into the framework's binary.
""",
            ),
            "exclude_resources": attr.bool(
                default = False,
                doc = """
Indicates whether resources should be excluded from the bundle. This can be used to avoid
unnecessarily bundling resources if the static framework is being distributed in a different
fashion, such as a Cocoapod.
""",
            ),
            "hdrs": attr.label_list(
                allow_files = [".h"],
                doc = """
A list of `.h` files that will be publicly exposed by this framework. These headers should have
framework-relative imports, and if non-empty, an umbrella header named `%{bundle_name}.h` will also
be generated that imports all of the headers listed here.
""",
            ),
            "umbrella_header": attr.label(
                allow_single_file = [".h"],
                doc = """
An optional single .h file to use as the umbrella header for this framework. Usually, this header
will have the same name as this target, so that clients can load the header using the #import
<MyFramework/MyFramework.h> format. If this attribute is not specified (the common use case), an
umbrella header will be generated under the same name as this target.
""",
            ),
        },
    ],
)
