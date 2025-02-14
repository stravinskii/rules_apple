# Copyright 2018 The Bazel Authors. All rights reserved.
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

"""Implementation of framework import rules."""

load(
    "@bazel_skylib//lib:collections.bzl",
    "collections",
)
load(
    "@bazel_skylib//lib:dicts.bzl",
    "dicts",
)
load(
    "@bazel_skylib//lib:partial.bzl",
    "partial",
)
load(
    "@bazel_skylib//lib:paths.bzl",
    "paths",
)
load(
    "@bazel_skylib//lib:sets.bzl",
    "sets",
)
load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleFrameworkImportInfo",
)
load(
    "@build_bazel_rules_apple//apple/internal:cc_toolchain_info_support.bzl",
    "cc_toolchain_info_support",
)
load(
    "@build_bazel_rules_apple//apple/internal:resources.bzl",
    "resources",
)
load(
    "@build_bazel_rules_apple//apple/internal/aspects:swift_usage_aspect.bzl",
    "SwiftUsageInfo",
)
load(
    "@build_bazel_rules_apple//apple/internal:rule_attrs.bzl",
    "rule_attrs",
)
load(
    "@build_bazel_rules_apple//apple:utils.bzl",
    "group_files_by_directory",
)
load(
    "@build_bazel_rules_swift//swift:swift_clang_module_aspect.bzl",
    "swift_clang_module_aspect",
)
load(
    "@build_bazel_rules_swift//swift:swift_common.bzl",
    "swift_common",
)
load(
    "@build_bazel_rules_apple//apple/internal:framework_import_support.bzl",
    "framework_import_support",
)
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain", "use_cpp_toolchain")

def _grouped_framework_files(framework_imports):
    """Returns a dictionary of each framework's imports, grouped by path to the .framework root."""
    framework_groups = group_files_by_directory(
        framework_imports,
        ["framework"],
        attr = "framework_imports",
    )

    # Only check for unique basenames of these keys, since it's possible to
    # have targets that glob files from different locations but with the same
    # `.framework` name, causing them to be merged into the same framework
    # during bundling.
    unique_frameworks = collections.uniq(
        [paths.basename(path) for path in framework_groups.keys()],
    )
    if len(unique_frameworks) > 1:
        fail("A framework import target may only include files for a " +
             "single '.framework' bundle.", attr = "framework_imports")

    return framework_groups

def _framework_search_paths(header_imports):
    """Return the list framework search paths for the headers_imports."""
    if header_imports:
        header_groups = _grouped_framework_files(header_imports)

        search_paths = sets.make()
        for path in header_groups.keys():
            sets.insert(search_paths, paths.dirname(path))
        return sets.to_list(search_paths)
    else:
        return []

def _apple_dynamic_framework_import_impl(ctx):
    """Implementation for the apple_dynamic_framework_import rule."""
    actions = ctx.actions
    cc_toolchain = find_cpp_toolchain(ctx)
    deps = ctx.attr.deps
    disabled_features = ctx.disabled_features
    features = ctx.features
    framework_imports = ctx.files.framework_imports
    label = ctx.label

    # TODO(b/207475773): Remove grep-includes once it's no longer required for cc_common APIs.
    grep_includes = ctx.file._grep_includes

    target_triplet = cc_toolchain_info_support.get_apple_clang_triplet(cc_toolchain)
    has_versioned_framework_files = framework_import_support.has_versioned_framework_files(
        framework_imports,
    )
    if target_triplet.os == "macos" and has_versioned_framework_files:
        # TODO(b/158696451): Add support to import macOS versioned frameworks.
        fail("apple_dynamic_framework_import rule does not yet support macOS versioned frameworks.")

    providers = []
    framework = framework_import_support.classify_framework_imports(framework_imports)

    # Create AppleFrameworkImportInfo provider.
    providers.append(framework_import_support.framework_import_info_with_dependencies(
        build_archs = [target_triplet.architecture],
        deps = deps,
        framework_imports = (
            framework.binary_imports +
            framework.bundling_imports
        ),
    ))

    # Create apple_common.Objc provider.
    transitive_objc_providers = [
        dep[apple_common.Objc]
        for dep in deps
        if apple_common.Objc in dep
    ]
    objc_provider = framework_import_support.objc_provider_with_dependencies(
        additional_objc_providers = transitive_objc_providers,
        dynamic_framework_file = framework.binary_imports,
    )
    providers.append(objc_provider)

    # Create CcInfo provider.
    cc_info = framework_import_support.cc_info_with_dependencies(
        actions = actions,
        cc_toolchain = cc_toolchain,
        ctx = ctx,
        deps = deps,
        disabled_features = disabled_features,
        features = features,
        framework_includes = _framework_search_paths(framework.header_imports),
        grep_includes = grep_includes,
        header_imports = framework.header_imports,
        kind = "dynamic",
        label = label,
        libraries = framework.binary_imports,
    )
    providers.append(cc_info)

    # Create AppleDynamicFramework provider.
    framework_groups = _grouped_framework_files(framework_imports)
    framework_dirs_set = depset(framework_groups.keys())
    providers.append(apple_common.new_dynamic_framework_provider(
        objc = objc_provider,
        cc_info = cc_info,
        framework_dirs = framework_dirs_set,
        framework_files = depset(framework_imports),
    ))

    if framework.swift_interface_imports:
        # Create SwiftInfo provider
        swift_toolchain = swift_common.get_toolchain(ctx, attr = "_swift_toolchain")
        swiftinterface_files = framework_import_support.get_swift_module_files_with_target_triplet(
            swift_module_files = framework.swift_interface_imports,
            target_triplet = target_triplet,
        )
        providers.append(
            framework_import_support.swift_info_from_module_interface(
                actions = actions,
                ctx = ctx,
                deps = deps,
                disabled_features = disabled_features,
                features = features,
                module_name = framework.bundle_name,
                swift_toolchain = swift_toolchain,
                swiftinterface_file = swiftinterface_files[0],
            ),
        )
    else:
        # Create _SwiftInteropInfo provider.
        swift_interop_info = framework_import_support.swift_interop_info_with_dependencies(
            deps = deps,
            module_name = framework.bundle_name,
            module_map_imports = framework.module_map_imports,
        )
        if swift_interop_info:
            providers.append(swift_interop_info)

    return providers

def _apple_static_framework_import_impl(ctx):
    """Implementation for the apple_static_framework_import rule."""
    actions = ctx.actions
    alwayslink = ctx.attr.alwayslink
    cc_toolchain = find_cpp_toolchain(ctx)
    deps = ctx.attr.deps
    disabled_features = ctx.disabled_features
    features = ctx.features
    framework_imports = ctx.files.framework_imports
    has_swift = ctx.attr.has_swift
    label = ctx.label
    sdk_dylibs = ctx.attr.sdk_dylibs
    sdk_frameworks = ctx.attr.sdk_frameworks
    weak_sdk_frameworks = ctx.attr.weak_sdk_frameworks

    # TODO(b/207475773): Remove grep-includes once it's no longer required for cc_common APIs.
    grep_includes = ctx.file._grep_includes

    providers = []
    framework = framework_import_support.classify_framework_imports(framework_imports)

    # Create AppleFrameworkImportInfo provider
    target_triplet = cc_toolchain_info_support.get_apple_clang_triplet(cc_toolchain)
    providers.append(framework_import_support.framework_import_info_with_dependencies(
        build_archs = [target_triplet.architecture],
        deps = deps,
    ))

    # Collect transitive Objc/CcInfo providers from Swift toolchain
    additional_cc_infos = []
    additional_objc_providers = []
    additional_objc_provider_fields = {}
    if framework.swift_interface_imports or has_swift:
        toolchain = swift_common.get_toolchain(ctx, attr = "_swift_toolchain")
        providers.append(SwiftUsageInfo())

        # The Swift toolchain propagates Swift-specific linker flags (e.g.,
        # library/framework search paths) as an implicit dependency. In the
        # rare case that a binary has a Swift framework import dependency but
        # no other Swift dependencies, make sure we pick those up so that it
        # links to the standard libraries correctly.
        additional_objc_providers.extend(toolchain.implicit_deps_providers.objc_infos)
        additional_cc_infos.extend(toolchain.implicit_deps_providers.cc_infos)

    # Create apple_common.Objc provider
    additional_objc_providers.extend([
        dep[apple_common.Objc]
        for dep in deps
        if apple_common.Objc in dep
    ])
    providers.append(
        framework_import_support.objc_provider_with_dependencies(
            additional_objc_provider_fields = additional_objc_provider_fields,
            additional_objc_providers = additional_objc_providers,
            alwayslink = alwayslink,
            sdk_dylib = sdk_dylibs,
            sdk_framework = sdk_frameworks,
            static_framework_file = framework.binary_imports,
            weak_sdk_framework = weak_sdk_frameworks,
        ),
    )

    # Create CcInfo provider
    linkopts = []
    if sdk_dylibs:
        for dylib in ctx.attr.sdk_dylibs:
            if dylib.startswith("lib"):
                dylib = dylib[3:]
            linkopts.append("-l%s" % dylib)
    if sdk_frameworks:
        for sdk_framework in ctx.attr.sdk_frameworks:
            linkopts.append("-framework")
            linkopts.append(sdk_framework)
    if weak_sdk_frameworks:
        for sdk_framework in ctx.attr.weak_sdk_frameworks:
            linkopts.append("-weak_framework")
            linkopts.append(sdk_framework)

    providers.append(
        framework_import_support.cc_info_with_dependencies(
            actions = actions,
            additional_cc_infos = additional_cc_infos,
            alwayslink = alwayslink,
            cc_toolchain = cc_toolchain,
            ctx = ctx,
            deps = deps,
            disabled_features = disabled_features,
            features = features,
            framework_includes = _framework_search_paths(
                framework.header_imports,
            ),
            grep_includes = grep_includes,
            header_imports = framework.header_imports,
            kind = "static",
            label = label,
            libraries = framework.binary_imports,
            linkopts = linkopts,
        ),
    )

    if framework.swift_interface_imports:
        # Create SwiftInfo provider
        swift_toolchain = swift_common.get_toolchain(ctx, attr = "_swift_toolchain")
        swiftinterface_files = framework_import_support.get_swift_module_files_with_target_triplet(
            swift_module_files = framework.swift_interface_imports,
            target_triplet = target_triplet,
        )
        providers.append(
            framework_import_support.swift_info_from_module_interface(
                actions = actions,
                ctx = ctx,
                deps = deps,
                disabled_features = disabled_features,
                features = features,
                module_name = framework.bundle_name,
                swift_toolchain = swift_toolchain,
                swiftinterface_file = swiftinterface_files[0],
            ),
        )
    else:
        # Create SwiftInteropInfo provider for swift_clang_module_aspect
        swift_interop_info = framework_import_support.swift_interop_info_with_dependencies(
            deps = deps,
            module_name = framework.bundle_name,
            module_map_imports = framework.module_map_imports,
        )
        if swift_interop_info:
            providers.append(swift_interop_info)

    # Create AppleResourceInfo provider
    bundle_files = [x for x in framework_imports if ".bundle/" in x.short_path]
    if bundle_files:
        parent_dir_param = partial.make(
            resources.bundle_relative_parent_dir,
            extension = "bundle",
        )
        resource_provider = resources.bucketize_typed(
            bundle_files,
            owner = str(label),
            bucket_type = "unprocessed",
            parent_dir_param = parent_dir_param,
        )
        providers.append(resource_provider)

    return providers

apple_dynamic_framework_import = rule(
    implementation = _apple_dynamic_framework_import_impl,
    fragments = ["cpp"],
    attrs = dicts.add(
        rule_attrs.common_tool_attrs,
        swift_common.toolchain_attrs(toolchain_attr_name = "_swift_toolchain"),
        {
            "framework_imports": attr.label_list(
                allow_empty = False,
                allow_files = True,
                mandatory = True,
                doc = """
The list of files under a .framework directory which are provided to Apple based targets that depend
on this target.
""",
            ),
            "deps": attr.label_list(
                aspects = [swift_clang_module_aspect],
                doc = """
A list of targets that are dependencies of the target being built, which will be linked into that
target.
""",
                providers = [
                    [apple_common.Objc, CcInfo],
                    [apple_common.Objc, CcInfo, AppleFrameworkImportInfo],
                ],
            ),
            "_cc_toolchain": attr.label(
                default = "@bazel_tools//tools/cpp:current_cc_toolchain",
                doc = "The C++ toolchain to use.",
            ),
        },
    ),
    doc = """
This rule encapsulates an already-built dynamic framework. It is defined by a list of files in
exactly one .framework directory. apple_dynamic_framework_import targets need to be added to library
targets through the `deps` attribute.
""",
    toolchains = use_cpp_toolchain(),
)

apple_static_framework_import = rule(
    implementation = _apple_static_framework_import_impl,
    fragments = ["cpp"],
    attrs = dicts.add(
        rule_attrs.common_tool_attrs,
        swift_common.toolchain_attrs(toolchain_attr_name = "_swift_toolchain"),
        {
            "framework_imports": attr.label_list(
                allow_empty = False,
                allow_files = True,
                mandatory = True,
                doc = """
The list of files under a .framework directory which are provided to Apple based targets that depend
on this target.
""",
            ),
            "sdk_dylibs": attr.string_list(
                doc = """
Names of SDK .dylib libraries to link with. For instance, `libz` or `libarchive`. `libc++` is
included automatically if the binary has any C++ or Objective-C++ sources in its dependency tree.
When linking a binary, all libraries named in that binary's transitive dependency graph are used.
""",
            ),
            "sdk_frameworks": attr.string_list(
                doc = """
Names of SDK frameworks to link with (e.g. `AddressBook`, `QuartzCore`). `UIKit` and `Foundation`
are always included when building for the iOS, tvOS and watchOS platforms. For macOS, only
`Foundation` is always included. When linking a top level binary, all SDK frameworks listed in that
binary's transitive dependency graph are linked.
""",
            ),
            "weak_sdk_frameworks": attr.string_list(
                doc = """
Names of SDK frameworks to weakly link with. For instance, `MediaAccessibility`. In difference to
regularly linked SDK frameworks, symbols from weakly linked frameworks do not cause an error if they
are not present at runtime.
""",
            ),
            "deps": attr.label_list(
                aspects = [swift_clang_module_aspect],
                doc = """
A list of targets that are dependencies of the target being built, which will provide headers and be
linked into that target.
""",
                providers = [
                    [apple_common.Objc, CcInfo],
                    [apple_common.Objc, CcInfo, AppleFrameworkImportInfo],
                ],
            ),
            "alwayslink": attr.bool(
                default = False,
                doc = """
If true, any binary that depends (directly or indirectly) on this framework will link in all the
object files for the framework file, even if some contain no symbols referenced by the binary. This
is useful if your code isn't explicitly called by code in the binary; for example, if you rely on
runtime checks for protocol conformances added in extensions in the library but do not directly
reference any other symbols in the object file that adds that conformance.
""",
            ),
            "has_swift": attr.bool(
                doc = """
A boolean indicating if the target has Swift source code. This helps flag Apple frameworks that do
not include Swift interface files.
""",
                default = False,
            ),
            "_cc_toolchain": attr.label(
                default = "@bazel_tools//tools/cpp:current_cc_toolchain",
                doc = "The C++ toolchain to use.",
            ),
        },
    ),
    doc = """
This rule encapsulates an already-built static framework. It is defined by a list of files in a
.framework directory. apple_static_framework_import targets need to be added to library targets
through the `deps` attribute.
""",
    toolchains = use_cpp_toolchain(),
)
