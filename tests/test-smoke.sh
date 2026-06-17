#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source tests/test-helpers.sh
assert_eq "1" "1" "框架基本断言"
assert_eq "$(jq -n '1+1')" "2" "jq 可用"
summary
