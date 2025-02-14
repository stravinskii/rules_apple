# Copyright 2017 The Bazel Authors. All rights reserved.
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

"""Support functions for working with Apple platforms and device families."""

# Maps the strings passed in to the "families" attribute to the numerical
# representation in the UIDeviceFamily plist entry.
# @unsorted-dict-items
_DEVICE_FAMILY_VALUES = {
    "iphone": 1,
    "ipad": 2,
    "tv": 3,
    "watch": 4,
    # We want _ui_device_family_plist_value to find None for the valid "mac"
    # family since macOS doesn't use the UIDeviceFamily Info.plist key, but we
    # still want to catch invalid families with a KeyError.
    "mac": None,
}

def _ui_device_family_plist_value(*, platform_prerequisites):
    """Returns the value to use for `UIDeviceFamily` in an info.plist.

    This function returns the array of value to use or None if there should be
    no plist entry (currently, only macOS doesn't use UIDeviceFamily).

    Args:
      platform_prerequisites: The platform prerequisites.

    Returns:
      A list of integers to use for the `UIDeviceFamily` in an Info.plist
      or None if the key should not be added to the Info.plist.
    """
    family_ids = []
    families = platform_prerequisites.device_families

    for f in families:
        number = _DEVICE_FAMILY_VALUES[f]
        if number:
            family_ids.append(number)
    if family_ids:
        return family_ids
    return None

def _platform_prerequisites(
        *,
        apple_fragment,
        build_settings,
        config_vars,
        cpp_fragment = None,
        device_families,
        explicit_minimum_os = None,
        objc_fragment = None,
        platform_type_string,
        signing_certificate_name = None,
        uses_swift,
        xcode_version_config):
    """Returns a struct containing information on the platform being targeted.

    Args:
      apple_fragment: An Apple fragment (ctx.fragments.apple).
      build_settings: A struct with build settings info from AppleXplatToolsToolchainInfo.
      config_vars: A reference to configuration variables, typically from `ctx.var`.
      cpp_fragment: An cpp fragment (ctx.fragments.cpp), if it is present. Optional.
      device_families: The list of device families that apply to the target being built.
      explicit_minimum_os: A dotted version string indicating minimum OS desired. Optional.
      objc_fragment: An Objective-C fragment (ctx.fragments.objc), if it is present. Optional.
      platform_type_string: The platform type for the current target as a string.
      signing_certificate_name: The name of the code signing identity to use for signing. If this
        is expected to be inferred from an assigned provisioning profile or if code signing does not
        apply to this part of the rule logic, set this to None. Optional.
      uses_swift: Boolean value to indicate if this target uses Swift.
      xcode_version_config: The `apple_common.XcodeVersionConfig` provider from the current context.

    Returns:
      A struct representing the collected platform information.
    """
    platform_type_attr = getattr(apple_common.platform_type, platform_type_string)
    platform = apple_fragment.multi_arch_platform(platform_type_attr)

    if explicit_minimum_os:
        minimum_os = explicit_minimum_os
    else:
        # TODO(b/38006810): Use the SDK version instead of the flag value as a soft default.
        minimum_os = str(xcode_version_config.minimum_os_for_platform_type(platform_type_attr))

    if objc_fragment:
        # TODO(b/252873771): Remove this fallback when the native Bazel flag ios_signing_cert_name
        # is removed.
        preferred_signing_cert_name = (signing_certificate_name or
                                       objc_fragment.signing_certificate_name)
    else:
        preferred_signing_cert_name = signing_certificate_name

    sdk_version = xcode_version_config.sdk_version_for_platform(platform)

    return struct(
        apple_fragment = apple_fragment,
        build_settings = build_settings,
        config_vars = config_vars,
        cpp_fragment = cpp_fragment,
        device_families = device_families,
        minimum_os = minimum_os,
        platform = platform,
        platform_type = platform_type_attr,
        objc_fragment = objc_fragment,
        sdk_version = sdk_version,
        signing_certificate_name = preferred_signing_cert_name,
        uses_swift = uses_swift,
        xcode_version_config = xcode_version_config,
    )

# Define the loadable module that lists the exported symbols in this file.
platform_support = struct(
    platform_prerequisites = _platform_prerequisites,
    ui_device_family_plist_value = _ui_device_family_plist_value,
)
