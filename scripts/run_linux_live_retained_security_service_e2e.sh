#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../wing_link"
# Offline service fixtures only; no installed runtime, manifests or product UI.
export GOPROXY=off GOTOOLCHAIN=local
exec go test -count=1 -timeout=60s ./internal/app ./internal/state -run 'Test(DeviceCanInspectAndRevokeOnlyItself|DeviceCredentialCanBeRevokedIndividually|DeviceScopesAreEnforcedPerRoute|DecodeJSONRejectsBodyBeyondLimit|PairOpen|PairingAdvertiseHostUsesLoopbackForExplicitLocalMode|PairingBrokerInspectsAndExchangesOnce|PairingBrokerRejectsWrongOriginAndCode|SameDeviceOutputContainsOnlyOpenURL)'
