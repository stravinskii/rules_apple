# Copyright 2020 The Bazel Authors. All rights reserved.
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

"""macos_extension Starlark tests."""

load(
    "//test/starlark_tests/rules:common_verification_tests.bzl",
    "entry_point_test",
)

def macos_extension_test_suite(name):
    """Test suite for macos_extension.

    Args:
      name: the base name to be used in things created by this macro
    """
    entry_point_test(
        name = "{}_entry_point_nsextensionmain_test".format(name),
        build_type = "simulator",
        entry_point = "_NSExtensionMain",
        target_under_test = "//test/starlark_tests/targets_under_test/macos:ext",
        tags = [name],
    )

    native.test_suite(
        name = name,
        tags = [name],
    )
