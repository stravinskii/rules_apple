# Copyright 2022 The Bazel Authors. All rights reserved.
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
"""Tests for xcframework_processor_tool."""

import unittest
from unittest import mock

from build_bazel_rules_apple.tools.imported_dynamic_framework_processor import imported_dynamic_framework_processor
from build_bazel_rules_apple.tools.wrapper_common import lipo


class ImportedDynamicFrameworkProcessorTest(unittest.TestCase):

  @mock.patch.object(lipo, "find_archs_for_binaries")
  def test_strip_or_copy_binary_fails_with_no_binary_archs(
      self, mock_lipo):
    with self.assertRaisesRegex(
        ValueError,
        "Could not find binary architectures for binaries using lipo.*"):
      mock_lipo.return_value = (None, None)
      imported_dynamic_framework_processor._strip_or_copy_binary(
          framework_binary="/tmp/path/to/fake/binary",
          output_path="/tmp/path/to/outputs",
          requested_archs=["x86_64"])

  @mock.patch.object(lipo, "find_archs_for_binaries")
  def test_strip_or_copy_binary_fails_with_no_matching_archs(
      self, mock_lipo):
    with self.assertRaisesRegex(
        ValueError,
        ".*Precompiled framework does not share any binary architecture.*"):
      mock_lipo.return_value = (set(["x86_64"]), None)
      imported_dynamic_framework_processor._strip_or_copy_binary(
          framework_binary="/tmp/path/to/fake/binary",
          output_path="/tmp/path/to/outputs",
          requested_archs=["arm64"])

  @mock.patch.object(lipo, "find_archs_for_binaries")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_copy_framework_file")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_strip_framework_binary")
  def test_strip_or_copy_binary_thins_framework_binary(
      self, mock_strip_framework_binary, mock_copy_framework_file, mock_lipo):
    mock_lipo.return_value = (set(["x86_64", "arm64"]), None)
    imported_dynamic_framework_processor._strip_or_copy_binary(
        framework_binary="/tmp/path/to/fake/binary",
        output_path="/tmp/path/to/outputs",
        requested_archs=["arm64"])

    mock_copy_framework_file.assert_not_called()
    mock_strip_framework_binary.assert_called_with(
        "/tmp/path/to/fake/binary",
        "/tmp/path/to/outputs",
        set(["arm64"]))

  @mock.patch.object(lipo, "find_archs_for_binaries")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_copy_framework_file")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_strip_framework_binary")
  def test_strip_or_copy_binary_skips_lipo_with_single_arch_binary(
      self, mock_strip_framework_binary, mock_copy_framework_file, mock_lipo):
    mock_lipo.return_value = (set(["arm64"]), None)
    imported_dynamic_framework_processor._strip_or_copy_binary(
        framework_binary="/tmp/path/to/fake/binary",
        output_path="/tmp/path/to/outputs",
        requested_archs=["arm64"])

    mock_strip_framework_binary.assert_not_called()
    mock_copy_framework_file.assert_called_with(
        "/tmp/path/to/fake/binary",
        executable=True,
        output_path="/tmp/path/to/outputs")

  @mock.patch.object(lipo, "find_archs_for_binaries")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_copy_framework_file")
  @mock.patch.object(
      imported_dynamic_framework_processor, "_strip_framework_binary")
  def test_strip_or_copy_binary_skips_lipo_with_matching_archs_bin(
      self, mock_strip_framework_binary, mock_copy_framework_file, mock_lipo):
    mock_lipo.return_value = (set(["x86_64", "arm64"]), None)
    imported_dynamic_framework_processor._strip_or_copy_binary(
        framework_binary="/tmp/path/to/fake/binary",
        output_path="/tmp/path/to/outputs",
        requested_archs=["x86_64", "arm64"])

    mock_strip_framework_binary.assert_not_called()
    mock_copy_framework_file.assert_called_with(
        "/tmp/path/to/fake/binary",
        executable=True,
        output_path="/tmp/path/to/outputs")

if __name__ == "__main__":
  unittest.main()
