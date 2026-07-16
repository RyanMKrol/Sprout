#!/usr/bin/env bash
#
# loop_sim.sh — ensure this project's DEDICATED iOS simulator exists and print its UDID.
#
# Why a dedicated device: build_run.sh, the harness LOCAL_DOD, and the test run all
# target a simulator by name. When two harness loops for different projects run on the
# same Mac at once, resolving by a shared generic name like "iPhone 17 Pro" (and
# preferring an already-booted match) makes both loops converge on the SAME simulator —
# each then installs and re-launches ITS OWN app onto it, so the running app visibly
# flip-flops and `xcodebuild test` intermittently fails to launch. Pinning Sprout to a
# uniquely-named device no other project targets removes the clash. (Adopted from the
# sibling Basket project's tools/loop_sim.sh.)
#
# Idempotent + self-healing: reuses the device if it already exists, otherwise creates
# an iPhone 17 Pro on the newest available iOS runtime. Prints ONLY the UDID on stdout;
# all diagnostics go to stderr, so callers can `SIM=$(tools/loop_sim.sh)`.
#
# Override the device name with SPROUT_SIM_NAME if you want a different dedicated device.

set -euo pipefail

SIM_NAME="${SPROUT_SIM_NAME:-Sprout-Claude}"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"

# Reuse an existing available device with this exact name, if any.
udid="$(xcrun simctl list devices --json \
  | jq -r --arg n "$SIM_NAME" '
      .devices | to_entries[] | .value[]
      | select(.name == $n and (.isAvailable != false)) | .udid' \
  | head -1)"

if [ -z "${udid:-}" ]; then
  # Newest available iOS runtime (e.g. com.apple.CoreSimulator.SimRuntime.iOS-26-5).
  runtime="$(xcrun simctl list runtimes available \
    | grep -Eo 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' \
    | sort -V | tail -1)"
  if [ -z "${runtime:-}" ]; then
    echo "loop_sim: no available iOS simulator runtime found — run 'xcodebuild -downloadPlatform iOS'." >&2
    exit 1
  fi
  echo "loop_sim: creating dedicated simulator '$SIM_NAME' ($runtime)…" >&2
  udid="$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$runtime")"
fi

echo "$udid"
