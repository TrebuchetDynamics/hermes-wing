# Android Durable Keystore Smoke

Validate durable reconnect key storage on Android before release. This runbook
separates keypair readiness from full Gormes durable reconnect so the two are not
confused.

## Automated key readiness

Run on a connected Android device/emulator:

```bash
npm run android:durable-key-smoke
```

or target a specific device:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> npm run android:durable-key-smoke
```

The smoke runs `integration_test/durable_key_store_android_smoke_test.dart` and
verifies:

- the native durable key MethodChannel is available;
- an ES256/P-256 keypair can be created under a `navivox_durable_*` alias;
- only public JWK fields are exported (`kty`, `crv`, `alg`, `x`, `y`), never
  private `d` material;
- payload signing returns a 64-byte ES256 signature;
- deleting the alias is safe and repeatable;
- unsafe non-durable aliases are rejected;
- the Dart `MethodChannelDurableCredentialKeyStore` adapter exercises the same
  create/sign/delete path.

This is key storage readiness only. It does **not** prove durable credential
issuance, authentication, or silent reconnect.

## Full durable reconnect closeout still required

Use a trusted Android device and a Gormes gateway that advertises durable
reconnect.

1. Install Navivox on the Android device.
2. Pair with the Gormes gateway.
3. Confirm the gateway advertises durable reconnect as available.
4. Confirm Navivox issues/registers a non-secret public key and no pairing token is stored; only durable reconnect credential/metadata may persist.
5. Stop/restart the Gormes gateway or otherwise invalidate the original pairing
   token while keeping the durable device credential valid.
6. Kill/restart Navivox.
7. Verify Navivox silently reconnects with the saved device credential, without a
   QR scan or pairing token.
8. Verify reconnect readiness remains available and shows saved/available after reconnect.
9. Verify no pairing token, device secret, private key material, or bearer token
   appears in UI, logs, routes, screenshots, diagnostics, or shared prefs.
10. Run strict readiness audit after recording the reconnect receipt:

    ```bash
    NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
    ```

    If unrelated blockers remain, the expected result is exit 3 with
    `Completion verdict: NOT COMPLETE`; do not promote this reconnect receipt,
    key smoke, passing tests, APK hashes, configured Hermes home, workflow YAML,
    or dispatch-only output to whole-goal completion.

Until steps 1-10 are recorded on Android against real Gormes, the legacy durable
reconnect blocker remains open even if `npm run android:durable-key-smoke`
passes.
