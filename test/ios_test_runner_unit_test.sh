#!/bin/bash

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

# Integration tests for iOS test runner.

function set_up() {
  mkdir -p ios
}

function tear_down() {
  rm -rf ios
}

function create_sim_runners() {
  cat > ios/BUILD <<EOF
load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_application",
    "ios_unit_test"
)
load("@build_bazel_rules_swift//swift:swift_library.bzl",
     "swift_library"
)
load(
    "@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl",
    "ios_test_runner"
)

ios_test_runner(
    name = "ios_x86_64_sim_runner",
    device_type = "iPhone 8",
)

EOF
}

function create_test_host_app() {
  if [[ ! -f ios/BUILD ]]; then
    fail "create_sim_runners must be called first."
  fi

  cat > ios/main.m <<EOF
#import <UIKit/UIKit.h>

int main(int argc, char * argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, nil);
  }
}
EOF

  cat > ios/Info.plist <<EOF
{
  CFBundleIdentifier = "\${PRODUCT_BUNDLE_IDENTIFIER}";
  CFBundleName = "\${PRODUCT_NAME}";
  CFBundlePackageType = "APPL";
  CFBundleShortVersionString = "1.0";
  CFBundleVersion = "1.0";
}
EOF

  cat >> ios/BUILD <<EOF
objc_library(
    name = "app_lib",
    srcs = [
        "main.m"
    ],
)

ios_application(
    name = "app",
    bundle_id = "my.bundle.id",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "${MIN_OS_IOS}",
    provisioning_profile = "@build_bazel_rules_apple//test/testdata/provisioning:integration_testing_ios.mobileprovision",
    deps = [":app_lib"],
)
EOF
}

function create_ios_unit_tests() {
  if [[ ! -f ios/BUILD ]]; then
    fail "create_sim_runners must be called first."
  fi

  cat > ios/pass_unit_test.m <<EOF
#import <XCTest/XCTest.h>

@interface PassingUnitTest : XCTestCase

@end

@implementation PassingUnitTest

- (void)testPass {
  XCTAssertEqual(1, 1, @"should pass");
}

- (void)testPass2 {
  XCTAssertEqual(1, 1, @"should pass");
}

@end
EOF

  cat > ios/pass_unit_test.swift <<EOF
import XCTest

class PassingUnitTest : XCTestCase {

  func testPass() throws {
    let result = 1 + 1;
    XCTAssertEqual(result, 2, "should pass");
  }
}
EOF

  cat > ios/fail_unit_test.m <<EOF
#import <XCTest/XCTest.h>

@interface FailingUnitTest : XCTestCase

@end

@implementation FailingUnitTest

- (void)testFail {
  XCTAssertEqual(0, 1, @"should fail");
}

@end
EOF

  cat > ios/PassUnitTest-Info.plist <<EOF
<plist version="1.0">
<dict>
        <key>CFBundleExecutable</key>
        <string>PassingUnitTest</string>
</dict>
</plist>
EOF

  cat > ios/PassUnitSwiftTest-Info.plist <<EOF
<plist version="1.0">
<dict>
        <key>CFBundleExecutable</key>
        <string>PassUnitSwiftTest</string>
</dict>
</plist>
EOF

  cat > ios/FailUnitTest-Info.plist <<EOF
<plist version="1.0">
<dict>
        <key>CFBundleExecutable</key>
        <string>FailingUnitTest</string>
</dict>
</plist>
EOF

  cat >> ios/BUILD <<EOF
objc_library(
    name = "pass_unit_test_lib",
    srcs = ["pass_unit_test.m"],
)

ios_unit_test(
    name = "PassingUnitTest",
    infoplists = ["PassUnitTest-Info.plist"],
    deps = [":pass_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    runner = ":ios_x86_64_sim_runner",
)

ios_unit_test(
    name = "PassingWithHost",
    infoplists = ["PassUnitTest-Info.plist"],
    deps = [":pass_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    test_host = ":app",
    runner = ":ios_x86_64_sim_runner",
)

swift_library(
    name = "pass_unit_swift_test_lib",
    srcs = ["pass_unit_test.swift"],
)

ios_unit_test(
    name = "PassingUnitSwiftTest",
    infoplists = ["PassUnitSwiftTest-Info.plist"],
    deps = [":pass_unit_swift_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    test_host = ":app",
    runner = ":ios_x86_64_sim_runner",
)

objc_library(
    name = "fail_unit_test_lib",
    srcs = ["fail_unit_test.m"],
)

ios_unit_test(
    name = 'FailingUnitTest',
    infoplists = ["FailUnitTest-Info.plist"],
    deps = [":fail_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    runner = ":ios_x86_64_sim_runner",
)

ios_unit_test(
    name = 'FailingWithHost',
    infoplists = ["FailUnitTest-Info.plist"],
    deps = [":fail_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    test_host = ":app",
    runner = ":ios_x86_64_sim_runner",
)
EOF
}

function create_ios_unit_envtest() {
  if [[ ! -f ios/BUILD ]]; then
    fail "create_sim_runners must be called first."
  fi

  cat > ios/env_unit_test.m <<EOF
#import <XCTest/XCTest.h>
#include <assert.h>
#include <stdlib.h>

@interface EnvUnitTest : XCTestCase

@end

@implementation EnvUnitTest

- (void)testEnv {
  NSString *var_value = [[[NSProcessInfo processInfo] environment] objectForKey:@"$1"];
  XCTAssertEqualObjects(var_value, @"$2", @"env $1 should be %@, instead is %@", @"$2", var_value);
}

@end
EOF

  cat >ios/EnvUnitTest-Info.plist <<EOF
<plist version="1.0">
<dict>
        <key>CFBundleExecutable</key>
        <string>EnvUnitTest</string>
</dict>
</plist>
EOF

  cat >> ios/BUILD <<EOF
objc_library(
    name = "env_unit_test_lib",
    srcs = ["env_unit_test.m"],
)

ios_unit_test(
    name = 'EnvUnitTest',
    infoplists = ["EnvUnitTest-Info.plist"],
    deps = [":env_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    runner = ":ios_x86_64_sim_runner",
)

ios_unit_test(
    name = 'EnvWithHost',
    infoplists = ["EnvUnitTest-Info.plist"],
    deps = [":env_unit_test_lib"],
    minimum_os_version = "${MIN_OS_IOS}",
    test_host = ":app",
    runner = ":ios_x86_64_sim_runner",
)
EOF
}

function do_ios_test() {
  do_test ios "--test_output=all" "--spawn_strategy=local" "$@"
}

function test_ios_unit_test_pass() {
  create_sim_runners
  create_ios_unit_tests
  do_ios_test //ios:PassingUnitTest || fail "should pass"

  expect_log "Test Suite 'PassingUnitTest' passed"
  expect_log "Test Suite 'PassingUnitTest.xctest' passed"
  expect_log "Executed 2 tests, with 0 failures"
}

function test_ios_unit_test_with_host_pass() {
  create_sim_runners
  create_test_host_app
  create_ios_unit_tests
  do_ios_test //ios:PassingWithHost || fail "should pass"

  expect_log "Test Suite 'PassingUnitTest' passed"
  expect_log "Test Suite 'PassingWithHost.xctest' passed"
  expect_log "Executed 2 tests, with 0 failures"
}

function test_ios_unit_swift_test_pass() {
  create_sim_runners
  create_test_host_app
  create_ios_unit_tests
  do_ios_test //ios:PassingUnitSwiftTest || fail "should pass"

  expect_log "Test Suite 'PassingUnitTest' passed"
  expect_log "Test Suite 'PassingUnitSwiftTest.xctest' passed"
  expect_log "Executed 1 test, with 0 failures"
}

function test_ios_unit_test_fail() {
  create_sim_runners
  create_ios_unit_tests
  ! do_ios_test //ios:FailingUnitTest || fail "should fail"

  expect_log "Test Suite 'FailingUnitTest' failed"
  expect_log "Test Suite 'FailingUnitTest.xctest' failed"
  expect_log "Executed 1 test, with 1 failure"
}

function test_ios_unit_test_with_host_fail() {
  create_sim_runners
  create_test_host_app
  create_ios_unit_tests
  ! do_ios_test //ios:FailingWithHost || fail "should fail"

  expect_log "Test Suite 'FailingUnitTest' failed"
  expect_log "Test Suite 'FailingWithHost.xctest' failed"
  expect_log "Executed 1 test, with 1 failure"
}

function test_ios_unit_test_with_filter() {
  create_sim_runners
  create_ios_unit_tests
  do_ios_test --test_filter=PassingUnitTest/testPass2 //ios:PassingUnitTest || fail "should pass"

  expect_log "Test Case '-\[PassingUnitTest testPass2\]' passed"
  expect_log "Test Suite 'PassingUnitTest' passed"
  expect_log "Test Suite 'PassingUnitTest.xctest' passed"
  expect_log "Executed 1 test, with 0 failures"
}

function test_ios_unit_test_with_host_with_filter() {
  create_sim_runners
  create_test_host_app
  create_ios_unit_tests
  do_ios_test --test_filter=PassingUnitTest/testPass2 //ios:PassingWithHost || fail "should pass"

  expect_log "Test Case '-\[PassingUnitTest testPass2\]' passed"
  expect_log "Test Suite 'PassingUnitTest' passed"
  expect_log "Test Suite 'PassingWithHost.xctest' passed"
  expect_log "Executed 1 test, with 0 failures"
}

function test_ios_unit_test_with_env() {
  create_sim_runners
  create_ios_unit_envtest ENV_KEY1 ENV_VALUE2
  do_ios_test --test_env=ENV_KEY1=ENV_VALUE2 //ios:EnvUnitTest || fail "should pass"

  expect_log "Test Suite 'EnvUnitTest' passed"
}

function test_ios_unit_test_with_host_with_env() {
  create_sim_runners
  create_test_host_app
  create_ios_unit_envtest ENV_KEY1 ENV_VALUE2
  do_ios_test --test_env=ENV_KEY1=ENV_VALUE2 //ios:EnvWithHost || fail "should pass"

  expect_log "Test Suite 'EnvUnitTest' passed"
}

run_suite "ios_unit_test with iOS test runner bundling tests"
