# OmniRoute installer review — 2026-09-05

The optional local Wing Link installer pins OmniRoute 3.8.50 and its npm
dependency closure. It does not expose a remote install operation, start a
server, provision a provider credential, or change Hermes profiles.

## Dependency correction

The initial lock failed `npm audit --omit=dev` with eight findings (six high,
one moderate, one low), including inherited findings in parent packages. The
review added exact root overrides for:

- `adm-zip` 0.6.0: [archive memory-allocation advisory](https://github.com/advisories/GHSA-xcpc-8h2w-3j85).
- `sharp` 0.35.3: [libvips advisories](https://github.com/advisories/GHSA-f88m-g3jw-g9cj).
- DOMPurify 3.4.13: [sanitization advisory](https://github.com/advisories/GHSA-55q2-fjhq-7xh7).

The regenerated lock reports zero known vulnerabilities. npm lifecycle scripts
remain disabled. The normal Go test checks the locked versions and integrity
fields; future dependency changes must repeat the audit.

Dependency review rejects the lowercase `apache-2.0` metadata published by
`@pierre/diffs` 1.2.12 and `@pierre/theming` 0.0.2. Both package manifests declare
that license; the diffs tarball includes the Apache 2.0 text, and the
[upstream monorepo license](https://github.com/pierrecomputer/pierre/blob/4f60f29f3b9caf95945ea505bd0cc8b97acb8850/LICENSE.md)
also supplies Apache 2.0. CI allows only these exact package/version license
metadata exceptions. Vulnerability checks and the denied-license list remain
enforced.

## Compatibility and qualification

A fresh locked installation was tested on Linux with Node 24.19.0. OmniRoute's
version/help probes passed. A synthetic ZIP creation/read round trip passed,
and Hugging Face Transformers decoded and resized a synthetic PNG through the
patched sharp dependency. DOMPurify sanitized event-handler and script input in
Chromium. The archive and transformer checks are also included in the opt-in
real-install Go test:

```bash
cd wing_link
WING_TEST_OMNIROUTE_INSTALL=1 go test ./internal/app -run '^TestOmniRouteRealInstall$' -count=1
```

These checks cover the exercised APIs across the two 0.x minor upgrades. They
do not qualify all OmniRoute integrations, model inference, provider sign-in,
Android installation, or background service operation. No model was downloaded,
no provider request was sent, and no OmniRoute server was started for this review.
