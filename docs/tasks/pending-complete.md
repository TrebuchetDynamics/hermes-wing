# Lista completa de pendientes

## Estado actual frente a esta fotografía histórica

El 2026-10-24, `python scripts/report_task_status.py` lee 297 registros: 295
`done`, 2 `open` y 64 cierres con exención explícita. Un cierre no acredita
implementación ni pruebas live. Las únicas tareas abiertas son Files browse y
su descarga dependiente; el trabajo pendiente de producto es mayor.

Para el estado actualizado ejecutar ese reporte de solo lectura (o `--json`);
para paquetes del clon consultar la
[ejecución vigente](../plans/2026-10-21-desktop-literal-clone.md#ejecución-vigente--2026-10-24).
Los 86 registros y checkboxes siguientes son la fotografía anterior a los cierres,
no la cola actual. Se conservan como inventario histórico de resultados no probados;
no reabren tareas ni anulan decisiones del propietario.

## Fotografía histórica conservada

Vista consolidada solicitada por el propietario. Los contratos en `tasks/items/`
siguen siendo la autoridad; esta vista no cambia estados ni crea otra cola.
Incluye los 86 registros abiertos y las brechas de implementación detectadas en
la auditoría. No son 86 funcionalidades nuevas: muchas son pruebas live.

## Orden de trabajo recomendado

- [ ] Completar admisión contractual de credenciales en UI y canal: identidad, revisión, idempotencia y consentimiento de efectos. Los permisos separados ya están entregados.
- [ ] Implementar preflight/driver Linux: LINUXQA-001-e41e98e5.
- [ ] Ejecutar regresiones compartidas y adaptador Linux: LINUXQA-001-dbb6605f.
- [ ] Calificar conexiones/custodia Linux: LINUXQA-001-8163f50f.
- [ ] Calificar Chat, sesiones, Bot Chat, colas y exportación: LINUXQA-001-c7841f6e.
- [ ] Calificar administración/ajustes/límites: LINUXQA-001-800e359b.
- [ ] Calificar accesibilidad/lifecycle/voz Linux: LINUXQA-001-cbe0b043.
- [ ] Consolidar resultados Linux: LINUXQA-001-c232368b.
- [ ] Completar Android: sesión/borrador, teclado/Back restante, muerte de proceso, TalkBack y foco.
- [ ] Calificar SSH Android real: fingerprint, autenticación, perfil/historial, pérdida y recuperación sin replay.
- [ ] Calificar Bot Chat real: lookup, creación, conflicto y adopción concurrente.
- [ ] Ejecutar workflow real integrado: generación, aprobación, Stop autoritativo, reinicio y restauración; requiere QA y admisión de llamadas.
- [ ] Calificar voz física: micrófono, permisos, TTS, interrupción, eco, reactivación y audio tardío.
- [ ] Implementar ownership/desinstalación Linux solo del cliente; calificar instalación, actualización, rollback y retención de datos/keyring en target desechable.
- [ ] Calificar Android con mismo artefacto, identidad/firma, upgrade y recuperación.
- [ ] Reconciliar documentos obsoletos de backlog, Wing Link, matriz de Bot Chat y resultados Android.

## Brechas de paridad: separar desarrollo de pruebas

- [ ] Attachment/autenticación canónica; identidad estable y recibos de envío; recuperación de resultado incierto y Stop por generación.
- [ ] Cola autoritativa y aclaraciones, solo tras trazar contratos exactos; no inventar recuperación de batches.
- [ ] OAuth remoto e importación de sesiones externas: convertir estudios terminados en slices sobre contratos verificados.
- [ ] Revisar Vault, paquetes, Screen, Radio y Pets contra Desktop oficial antes de admitir nuevas implementaciones/prioridades.
- [ ] Files: navegador/lectura y luego descarga, bloqueados por contrato de autenticación, raíz session/profile/backend y confinamiento. Sin shell/SFTP ni cambios al Agent.
- [ ] Contratos administrativos: Projects/asignación, MCP, schedules, memoria, Kanban, cuentas/revocación, lifecycle y artefactos. Cada operación ausente permanece no disponible.

Estas brechas detectadas por auditoría no tienen todas una tarea de implementación
dedicada. No declarar los estudios terminados como implementación ni inventar
aprobación, wire fields o capacidades para llenar esa carencia de trazabilidad.

## Ya entregado: no repetir

- [x] Errores de conexión tipados y owner-fenced: 4f397c46 y 8e0b86a4.
- [x] Conexión local confirmada resuelta por el propietario.
- [x] Persistencia aislada Linux de reemplazo de credenciales: dba0bd92.
- [x] Tres journeys Bot Chat en motor Android con fixtures: 47d793a1.
- [x] Cinco casos de compositor/accesibilidad Android: 980f6fc1.
- [x] Back con compositor enfocado conserva Chat/borrador, probado por ADB OS input: 6c82c059.
- [x] Cancelación TTS pendiente tras Stop/dispose, 136 pruebas deterministas: cbff9212.
- [x] Permisos separados Set/Remove/Validate y ausencia de capacidades cerrada, 98 pruebas: 3c3e4d5a. No completa admisión contractual.
- [x] Rescate de layout/perfil y archivo privado de candidatos antiguos: 06bb3033. No reimportar controladores SSH superados.

## Entrega y cierre

Por cada actividad: implementar o probar el criterio concreto, registrar plataforma,
comandos/resultados y commit en su tarea, integrar y publicar en main y retirar la
rama temporal limpia. No cerrar aceptación completa desde un subconjunto ni un
fixture. No reabrir conexión local sin nueva evidencia. No activar cron ni ejecutar
operaciones live/destructivas sin los gates de la tarea.

## Todos los registros abiertos

La aceptación se reproduce íntegra del contrato actual para no ocultar pendientes.
Las referencias a dispositivos ausentes son históricas y deben reconciliarse con
los resultados posteriores, no tratarse como impedimento permanente. Consultar
las notas del registro enlazado para sus subconjuntos completados.

### 1. VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY

- [Contrato y resultados](../../tasks/items/VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY.md): Qualify exact advertised atomic restore authority before native recovery.
- Estado: open; sección: Needs decision; goal: `DIAGNOSTICS-RECOVERY`.
- Dependencias: DOC-DIAGNOSTICS-BACKUP-CONTRACT.
- Alcance: validate an exact advertised Agent recovery operation and its profile, archive, revision, rollback and activation boundaries before implementing a Wing caller.
- Aceptación pendiente registrada:
  - authenticated secret-safe operation identity and all-resource rollback must be established; separately approved native target checks must prove recovery.

### 2. LINUXQA-001-e41e98e5

- [Contrato y resultados](../../tasks/items/LINUXQA-001-e41e98e5.md): Build safe Linux qualification entrypoint and portable preflight.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: ninguna registrada.
- Alcance: Implement only the developer-test campaign driver and portability/environment seams described by the plan. Fixed lanes, current-source snapshots, explicit compatible dependency prefix, owned output/display/state and allowlisted subprocess environment; no app feature changes. Repair hard-coded private prefix use in the three named shared runners without copying historical application code.
- Aceptación pendiente registrada:
  - Given missing or stale dependencies, wrong SDK/Node major, unsafe output roots or inherited live opt-ins, preflight and linux_feature_qualification_runner_test.py reject before any GTK/SSH/provider/installer child starts.
  - Given synthetic subprocess results, the fixed-lane driver preserves exact exits and schema-1 source/tool/case/cleanup identities; empty, interrupted or stale records cannot pass.
  - Given an explicit compatible owned prefix, reusable launchers resolve it without private absolute paths; existing self-checks and new environment-isolation tests pass without changing production or Agent source.

### 3. CONNECTION-LINK-RETIREMENT

- [Contrato y resultados](../../tasks/items/CONNECTION-LINK-RETIREMENT.md): Retire Wing Link packaging and legacy setup after Agent-only native Local flows and migration checks pass.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-LINK-REMOVAL.
- Alcance: remove lib/core/wing_link, wing_link service tree, install-wing-link.sh, delivery scripts, dependency closure, platform hosts, service/packaging hooks, release/smoke jobs and obsolete fixtures/exports. Current docs and landing visuals must contain no legacy setup offer. Historical receipts stay clearly historical. Current-user README, getting-started, PRD and docs navigation no longer promote Link installation or pairing. Android prerequisites also distinguish optional VPN connectivity from required transport security; neither VPN nor pairing is mandatory. Retain this boundary while retiring remaining consumers; historical runbooks are not replacement qualification. Preserve legacy contract/security checks until their consumers are removed.
- Aceptación pendiente registrada:
  - packaging and new phone setup include no Wing Link binary/service or pairing bootstrap; direct/native workflows pass on named Linux and Android targets. Installed paired records and personal runtimes are not erased or restarted. Previously paired installations use only retained Agent access or explicit direct reauthentication; no Link recovery/legacy compatibility mode remains. Explain unsupported former management features without a new shell bridge/backend. Audit each remaining legacy goal/task for replacement rather than marking it met because its code was removed. Reconcile agent guides only within authorized scope.

### 4. LINUXQA-001-dbb6605f

- [Contrato y resultados](../../tasks/items/LINUXQA-001-dbb6605f.md): Qualify current-source shared regressions and Linux native adapter coverage.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-e41e98e5.
- Alcance: Run the documented full Dart, analysis, deterministic browser regression and isolated native-engine adapter on one current immutable source. Reconcile the adapter inventory with current suites including Bot Chat/timestamps/paged export; retain mocked storage/input limits. Fix attributable adapter/test-harness omissions, not arbitrary production features; retain failures and exact unrun inventory.
- Aceptación pendiente registrada:
  - Given the current suite tree, the new adapter-inventory regression detects missing current Bot Chat/local-timestamp/paged-export coverage instead of trusting the old 83-import comment.
  - Given the frozen candidate and matching tool/dependency inputs, format, full analysis, full Dart suite, compiled deterministic browser suite and Linux adapter produce terminal results and exact selected-versus-recorded case IDs; failures and skips remain explicit.
  - The lane records mocked preferences/secure storage/text input separately from real plugins and does not turn browser or native-engine mocks into full Linux qualification.

### 5. FILES-TERMINAL-DOWNLOAD

- [Contrato y resultados](../../tasks/items/FILES-TERMINAL-DOWNLOAD.md): Download a selected terminal working-directory file to the Wing device with verified bytes.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: FILES-TERMINAL-BROWSE.
- Alcance: reuse browse owner/root authorization; explicit Linux Save As and Android document-save picker, bounded/cancellable transfer, sanitized filename and destination handling. No upload, edit/delete, executable preview, recursive folder download or silent overwrite.
- Aceptación pendiente registrada:
  - read back saved bytes against the selected source; cancellation/denial/disconnection/owner-switch leave no claimed successful save; progress and explicit retry; test text and binary downloads and hostile filenames; native Linux and Android save receipts, not download-start-only claims.

### 6. LINUXQA-001-8163f50f

- [Contrato y resultados](../../tasks/items/LINUXQA-001-8163f50f.md): Qualify Linux connection recovery and isolated native plugin custody.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-e41e98e5.
- Alcance: Execute the fixed connections lane using existing first-run, metadata-only Local, direct Remote, saved-host, native clipboard/picker, private D-Bus/keyring and managed SSH fixture runners. Add current production-control coverage for missing denial/cancel/owner-replacement cells using disposable synthetic fixtures. Read-only connection and deliberate native chat enablement remain distinct. Do not revive retired local installation/pairing or treat SSH preparation-only output as execution.
- Aceptación pendiente registrada:
  - The new GTK connection fixture fails if changed-origin credentials, stale picker/trust/bootstrap callbacks or automatic reconnect/mutation replay can retarget a replacement owner; missing/denied native contracts stay unavailable.
  - Existing real isolated clipboard/file/keyring/persistence and explicit --lane linux --run SSH fixture produce distinct source-bound receipts and teardown, without touching personal stores or a real SSH/Agent host.
  - The exact public-control recovery inventory accounts for each connections/plugin case and preserves native chooser/encrypted-key/real-host limitations instead of promoting mocked acquisition or historical setup receipts.

### 7. FILES-TERMINAL-BROWSE

- [Contrato y resultados](../../tasks/items/FILES-TERMINAL-BROWSE.md): Browse and read the selected Agent terminal working-directory files on Linux and Android.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: ninguna registrada.
- Alcance: [source tracing is complete](../../docs/analysis/terminal-files-feasibility.md); implement the read-only Files surface through qualified authenticated `hermes serve` routes. Qualify actual file authentication, authoritative session/profile root and server-enforced canonical containment before enabling access. List/read-text lack session parameters; local default-cwd and non-SSH execution backends need explicit qualification. Messaging-API-only connections remain unsupported. No Wing Link requirement, Agent edits, arbitrary shell, host-wide browser, file writes or prompt-based retrieval.
- Aceptación pendiente registrada:
  - folders/files and read-only bounded text previews; exact connection/profile/session root; keyboard/touch access; loading/empty/denied/unsupported/retry states; context-change stale-result rejection; traversal/symlink denial; no incidental mutation or content logs. Linux and Android device checks remain separately recorded.

### 8. LINUXQA-001-c7841f6e

- [Contrato y resultados](../../tasks/items/LINUXQA-001-c7841f6e.md): Qualify Linux Chat sessions Bot Chat queues and export controls.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-e41e98e5.
- Alcance: Use production channels against synthetic authenticated HTTP/SSE/native fixtures for the current Chat/session/workspace surface. Reuse stream/Stop/restart helpers; add bounded public GTK cases for canonical Bot Chat, API tab ownership, queue/draft races, model/session actions, local timestamps/slash, attachment ownership and paged JSON save/overwrite/cancel. Native-serve tabs/attachments, absent clarification contracts and frozen-snapshot export remain explicit unsupported boundaries.
- Aceptación pendiente registrada:
  - Given a current owner and delayed or competing operations, new native cases reject wrong Bot Chat registry/hidden/history adoption, replacement-owner queue/draft writes and stale approval/Stop/attachment completions with exact operation counts.
  - Given rendered controls, session search/fork/rename/delete/pin/pagination, supported tab/Bot Chat access, local slash/timestamps and each export format execute or expose their exact unsupported boundary; JSON replacement consent/refusal/cancel and destination bytes are checked separately from live projection.
  - Existing streaming-under-overlay and two-process recovery remain source-bound with no replay; newer-case omissions, unknown terminal outcomes or unexercised real chooser branches remain failed/not-run cells, not synthetic success.

### 9. VERIFY-SLASH-AUTHORITATIVE-TRANSPORT

- [Contrato y resultados](../../tasks/items/VERIFY-SLASH-AUTHORITATIVE-TRANSPORT.md): Qualify supported authoritative slash execution and unavailable-action recovery.
- Estado: open; sección: Needs decision; goal: `SLASH-CATALOG`.
- Dependencias: DOC-SLASH-DENIAL-EVIDENCE.
- Alcance: implement only exact advertised unmodified Agent command contracts and their coherent composer/recovery consumers; preserve direct Agent ownership and no replay.
- Aceptación pendiente registrada:
  - catalog/completion/dispatch identity and grants match the selected Agent; unavailable-action disclosure and zero specialized I/O have production-path oracles; ordinary chat fallback is explicit. Record separate native/live proof before parity.

### 10. LINUXQA-001-800e359b

- [Contrato y resultados](../../tasks/items/LINUXQA-001-800e359b.md): Qualify Linux management settings and unavailable feature boundaries.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-e41e98e5.
- Alcance: Exercise current public Profiles/Persona/Providers/Models/Tools/Schedules/Connections-health/Settings/Diagnostics over deterministic advertised, missing, denied and stale-owner contracts. Reuse Persona revision conflict. Cover every absent/partial Desktop family and route/alias by accurate negative assertions; do not add features or fabricate Agent capabilities. Use only synthetic secret values and real production channel routing where supported.
- Aceptación pendiente registrada:
  - New GTK cases detect lost revision rejection, stale-owner provider/profile mutation, incorrect secret readback or forbidden operations under missing/denied grants; ordinary save and explicit retry use exact synthetic authority.
  - All offered management, appearance/chat/voice-setting, redacted-diagnostic and inventory controls have positive/recovery checks; unsupported OAuth/Project/MCP administration/job mutation and absent destinations remain explicitly unavailable with zero unadvertised writes.
  - The 50-family and actual route/action join includes absent Memory/Kanban/artifact/preview/terminal/cloud/account/import/Starmap/guide/plugins/Radio/Vault/package/Screen/Pets surfaces without counting their negative checks as positive parity.

### 11. CONNECTION-LINK-REMOVAL

- [Contrato y resultados](../../tasks/items/CONNECTION-LINK-REMOVAL.md): Remove deprecated Wing Link product entry and catalog dependencies while preserving direct Agent ownership.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: ninguna registrada.
- Alcance: enrollment, Local platform flow, profile/catalog callers, Connections and nearest production-control tests. Retire explicit pairing/handoff payloads and routes, Local/Termux bootstrap, dormant builders/directory adapters and legacy credential/contact APIs after the active enrollment slice. Reuse current Agent APIs and Linux discovery; do not expand or replace the management service. Unsupported operations must explain unavailable Agent support, not invoke a shell.
- Aceptación pendiente registrada:
  - fresh/saved Local, SSH and Remote use zero Link requests or setup prerequisites. Profile/model choice does not fetch the Link catalog. Cancelling replacement setup and reconnect preserve exact host/profile/session and no replay. Old pairing input fails safely with direct reconnection guidance; missing Agent credentials require explicit reauthentication, not legacy Link recovery. Preserve stored Agent access and raw user records. No Link construction/process/fallback remains, even for previously paired installations. Linux offers default Hermes-home inspection and a folder chooser; Android offers guided same-phone Agent setup, with installation and auth readiness distinguished.

### 12. LINUXQA-001-cbe0b043

- [Contrato y resultados](../../tasks/items/LINUXQA-001-cbe0b043.md): Qualify Linux accessibility native lifecycle and voice failure boundaries.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-e41e98e5.
- Alcance: Reuse shell/footer/keyboard/compact-return/status/native-input fixtures and add named-control, focus/reflow/reduced-motion/contrast-regression and voice-unavailable/cancel/teardown coverage. Exercise offered native menu/clipboard/save behavior only in owned displays/state. Record framework events versus OS-injected versus physical input; inspect packaging tooling without installing/updating/removing an app. Positive real audio, screen reader, Wayland/IME and installed-artifact acceptance stay with existing live tasks.
- Aceptación pendiente registrada:
  - New native cases fail on lost focus after dismissal/owner replacement, unreachable enlarged-text controls or hidden keyboard actions; semantics/geometry evidence is classified separately from real screen-reader or physical input.
  - Voice denial/unavailability/cancel/disposal yields safe retained text/draft and zero automatic capture/re-arm/send or stale playback callbacks; no synthetic unavailable-capture assertion is counted as positive microphone/audio qualification.
  - Existing shell/persistence/footer/native-input and artifact-tooling checks record their actual window/input/storage target and cleanup, while physical/audio/packaged cells remain not-run on their existing owners.

### 13. CONNECTION-CRON-CANARY

- [Contrato y resultados](../../tasks/items/CONNECTION-CRON-CANARY.md): Qualify one reviewed implementation canary before resuming the existing 15-minute cron.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-CRON-ADMISSION.
- Alcance: preserve and finish the current Wing candidate; reconcile existing connection owners; update/read back the existing paused job prompt; qualify one manually triggered occurrence and gated schedule resumption. Use an existing eligible CONNECTION-PATHS implementation task, not duplicate product work.
- Aceptación pendiente registrada:
  - observe safe admission, relevant passing checks, independent review, a scoped implementation commit on canonical main and worker release. Existing chat work, documentation-only commits and job status `ok` do not count. Resume only after all canary evidence passes; read back enabled state and cadence and inspect the first scheduled occurrence. A hard refusal pauses and notifies.

### 14. LINUXQA-001-c232368b

- [Contrato y resultados](../../tasks/items/LINUXQA-001-c232368b.md): Join Linux feature evidence and publish an honest qualification verdict.
- Estado: open; sección: Next; goal: `PARITY`.
- Dependencias: LINUXQA-001-dbb6605f, LINUXQA-001-8163f50f, LINUXQA-001-c7841f6e, LINUXQA-001-800e359b, LINUXQA-001-cbe0b043.
- Alcance: Join all five lane results into one current-source feature/route/action ledger and existing evidence owners, with no live execution. Implement only the focused receipt/coverage checker and tests; classify every missing/unsupported/failed/live/physical/package cell. Produce a fixture verdict and separate overall Linux verdict. Link original existing live tasks without duplicating, closing, granting authority or making them prerequisites of offline reporting.
- Aceptación pendiente registrada:
  - The new checker rejects missing/duplicate/stale-source/empty/interrupted case records, boolean-as-number counts, unexplained skips and mismatched feature/route/action inventories; negative controls demonstrate each rejection.
  - All 50 matrix IDs plus current composed routes/aliases/public actions and newer Bot Chat/tab/timestamp/JSON subsets have a case-level result and source-bound evidence, with no omitted lane or skipped target hidden by a successful wrapper.
  - The final report says PARTIAL whenever required real-Agent/hardware/package cells remain unverified, maps each to its existing task, retains exact failures and does not mark PARITY met or upgrade matrix runtime classifications.

### 15. DOC-API-DEVICE-SELF-CONFORMANCE

- [Contrato y resultados](../../tasks/items/DOC-API-DEVICE-SELF-CONFORMANCE.md): Verify device-self read/revoke schema and authorization against handlers.
- Estado: open; sección: Needs decision; goal: `API-CONFORMANCE`.
- Dependencias: DOC-API-CONFORMANCE.
- Alcance: one management-route family, existing tooling, in-process disposable recorder fixtures and documentation corrections. Exclude live listeners, personal credentials, peer administration, API redesign and new dependencies.
- Aceptación pendiente registrada:
  - execute schema-to-handler checks for self-read/revoke, exact grants, pending/revoked authority and method/protocol errors. Reject an isolated incorrect schema copy; keep generated credentials and fixture bodies out of receipts. Record exact commands, source hashes and limits. Other families, full OpenAPI standards validation, TLS and live transport remain unverified.

### 16. DOC-API-PROTOCOL-ERROR-EVIDENCE

- [Contrato y resultados](../../tasks/items/DOC-API-PROTOCOL-ERROR-EVIDENCE.md): Map profile-list protocol error precedence.
- Estado: open; sección: Needs decision; goal: `API-CONFORMANCE`.
- Dependencias: DOC-API-DEVICE-SELF-CONFORMANCE.
- Alcance: read-only source, nearest tests and sanitized receipt inspection for this outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
- Aceptación pendiente registrada:
  - Compare code-first schema and existing dispatch tests for omitted, supported and unsupported generations with method/auth errors. Record conformance proof or the exact unexecuted check; no sockets.

### 17. CONNECTION-CRON-ADMISSION-LIVE

- [Contrato y resultados](../../tasks/items/CONNECTION-CRON-ADMISSION-LIVE.md): Live checks for CONNECTION-CRON-ADMISSION.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-CRON-ADMISSION.
- Alcance: Run the live checks the offline work for CONNECTION-CRON-ADMISSION left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - The separate hermes-toolset admission contract/repair and independent review must establish full-lifecycle fencing, overlap rejection, stale/crashed-owner recovery, and failure cleanup. - Exercise installed native admission, verify checked local commit and worker release, then perform the separately gated one-occurrence cron canary. Keep the job paused until these proofs exist.

### 18. CONNECTION-SAVED-WORKFLOWS-LIVE

- [Contrato y resultados](../../tasks/items/CONNECTION-SAVED-WORKFLOWS-LIVE.md): Live checks for CONNECTION-SAVED-WORKFLOWS.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-SAVED-WORKFLOWS.
- Alcance: Run the live checks the offline work for CONNECTION-SAVED-WORKFLOWS left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Requalify the final candidate through named native Linux and Android application journeys; this run exercised Linux-hosted Flutter widgets and compiled Chromium only. - Approved isolated live Hermes Agent authentication and actual Chat/provider readiness remain unexercised; deterministic discovery/history and injected denial are not live authentication or inference. - OS-native secure storage, directory/document chooser, restart persistence, physical input and screen-reader behavior require matching platform evidence; earlier native receipts retain their own frozen-source scope. - Actual manual Termux installation/start and on-phone background survival remain separately qualified, not proved by the Android-targeted setup widget fixture.

### 19. DOC-M2-INODE-POLICY-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M2-INODE-POLICY-EVIDENCE-LIVE.md): Live checks for DOC-M2-INODE-POLICY-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `M2`.
- Dependencias: DOC-M2-INODE-POLICY-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-M2-INODE-POLICY-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No kernel/mount control execution or Android/device qualification was performed; these remain separate M2 admission prerequisites, and M2 remains unverified.

### 20. PARITY-LIVE-WORKFLOW-LIVE

- [Contrato y resultados](../../tasks/items/PARITY-LIVE-WORKFLOW-LIVE.md): Live checks for PARITY-LIVE-WORKFLOW.
- Estado: open; sección: Needs decision; goal: `M1`.
- Dependencias: PARITY-LIVE-WORKFLOW.
- Alcance: Run the live checks the offline work for PARITY-LIVE-WORKFLOW left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Supported authoritative Agent-side physical provider-call admission covering retries, continuations, and auxiliary work. - Separately authorized disposable QA authentication, exact operation grants, and target prerequisites. - Production two-process native GTK journey with actual output, correlated approval, authoritative Stop, close/relaunch restoration, deliberate resumed send, and canonical Agent readback.

### 21. WING-TASK-408-LIVE

- [Contrato y resultados](../../tasks/items/WING-TASK-408-LIVE.md): Live checks for WING-TASK-408.
- Estado: open; sección: Needs decision; goal: `PARITY-COMPOSITION`.
- Dependencias: WING-TASK-408.
- Alcance: Run the live checks the offline work for WING-TASK-408 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Android remains unqualified. - Compact saved-host Settings entry is not independently exercised in the native HTTP/SSE matrix; its attempted test extension hit unrelated shell-control availability before reaching the new entry. - No live Agent/provider, physical keyboard, or physical-device qualification was performed.

### 22. VERIFY-DESKTOP-NATIVE-DELIVERY

- [Contrato y resultados](../../tasks/items/VERIFY-DESKTOP-NATIVE-DELIVERY.md): Qualify named-target Linux install, update, client-only removal and retained-state recovery.
- Estado: open; sección: Needs decision; goal: `DESKTOP-DELIVERY`.
- Dependencias: DOC-DESKTOP-UNINSTALL-EVIDENCE.
- Alcance: separately approved disposable Linux target and synthetic state only; qualify complete bundle/launcher ownership, activation/rollback, client-only removal, retained endpoint identity and actual keyring reinstall readability. Preserve Agent services, credentials, raw legacy records and unrelated files. No live operation now.
- Aceptación pendiente registrada:
  - named-target source/artifact-bound receipts prove each operation and failure/recovery outcome; missing client-only producer, signing or access remain explicit gaps. Offline source and mocked storage checks cannot close this task.

### 23. VERIFY-PERSONA-LIVE-COMPATIBILITY

- [Contrato y resultados](../../tasks/items/VERIFY-PERSONA-LIVE-COMPATIBILITY.md): Qualify Persona revision-aware saves and conflict recovery against an authorized deployed Agent.
- Estado: open; sección: Needs decision; goal: `PERSONA`.
- Dependencias: VERIFY-PERSONA-NATIVE-CONFLICT.
- Alcance: production standalone Persona and Profiles modal on a named disposable QA profile, through exact advertised Agent SOUL read/write operations and supported private authentication. No personal profile/credential discovery, provider inference, Agent edits, compatibility adapter or new draft mechanism.
- Aceptación pendiente registrada:
  - verify the deployed operation/path/grants and profile context; deliberate ordinary save persists exact text; a real concurrent revision change rejects the stale save, loads authoritative newer text and permits only a deliberate retry at the new revision. Prove exact owner and write counts with sanitized server readback; native fixtures alone do not qualify this task. Android, physical IME and screen-reader coverage remain separately unqualified.

### 24. VERIFY-M4-LIVE-INVENTORY

- [Contrato y resultados](../../tasks/items/VERIFY-M4-LIVE-INVENTORY.md): Qualify scheduled-job inventory on an authenticated native Agent target.
- Estado: open; sección: Needs decision; goal: `M4`.
- Dependencias: DOC-M4-SCHEDULE-INVENTORY-EVIDENCE.
- Alcance: installed Linux Wing against an existing approved isolated authenticated, unmodified Agent target. No Agent changes, service changes, inference or mutations.
- Aceptación pendiente registrada:
  - verify exact advertised jobs/grants/profile contract, real denial, pending A-to-B read isolation and explicit B recovery with owner-scoped request receipts and zero mutations; keyboard recovery remains operable. If the contract is absent, verify unavailable/no dispatch and retain successful inventory unqualified.

### 25. VERIFY-SHELL-NATIVE-INPUT

- [Contrato y resultados](../../tasks/items/VERIFY-SHELL-NATIVE-INPUT.md): Qualify sidebar persistence and adaptive return through physical OS controls.
- Estado: open; sección: Needs decision; goal: `SHELL-PERSISTENCE`.
- Dependencias: DOC-SHELL-COMPACT-RETURN-EVIDENCE.
- Alcance: use an explicitly approved disposable native target and its public keyboard/window controls; preserve personal storage and all Agent identities.
- Aceptación pendiente registrada:
  - collapse with OS keyboard input, resize wide-to-compact-to-wide, retain production draft and collapsed intent without incidental Agent calls, then relaunch and verify persisted sidebar intent. Record exact source, target, commands, counts and outcomes; do not substitute framework key/resize seams.

### 26. M2-DEVICE-QUALIFICATION

- [Contrato y resultados](../../tasks/items/M2-DEVICE-QUALIFICATION.md): Owner: run the named-device Android death-to-completion qualification (physical device); agents prepare nothing further until then.
- Estado: open; sección: Needs decision; goal: `M2`.
- Dependencias: owner-provided device and the existing admission prerequisites.
- Alcance: only the admitted isolated device scenario and sanitized receipt; exclude personal credentials, unadmitted QA runtime and synthetic qualification claims.
- Aceptación pendiente registrada:
  - named-device receipt proves completion while absent, exact restoration and authoritative no-replay counts. A device alone does not supply missing admission.

### 27. VERIFY-M6-ANDROID-INTEGRATED

- [Contrato y resultados](../../tasks/items/VERIFY-M6-ANDROID-INTEGRATED.md): Qualify same-artifact Android workflow, upgrade and recovery on an admitted target.
- Estado: open; sección: Needs decision; goal: `M6`.
- Dependencias: DOC-M6-INTEGRATED-RECEIPT-GAP.
- Alcance: separately admitted candidate and disposable named Android target; bind installed artifact/package/process identity to applicable M1–M5 outcomes, then a distinct verified predecessor and approved upgrade/failure/recovery sequence. Preserve paired/personal apps, credentials and Agent state. No release, deployment, upstream edits, invented contracts or unapproved inference is authorized here.
- Aceptación pendiente registrada:
  - exact source/tag/certificate/artifact and installed-byte readback; named target/OS/ABI/package/process generations; applicable workflow receipts and exact-owner canonical restoration with zero replay. Upgrade and recovery must retain expected state, restore trusted bytes/health and verify canonical owner. Unsupported operations remain explicit gaps; fixtures never qualify M6.

### 28. M1-MOBILE-AWAY-STATUS-LIVE

- [Contrato y resultados](../../tasks/items/M1-MOBILE-AWAY-STATUS-LIVE.md): Live checks for M1-MOBILE-AWAY-STATUS.
- Estado: open; sección: Needs decision; goal: `M1`.
- Dependencias: M1-MOBILE-AWAY-STATUS.
- Alcance: Run the live checks the offline work for M1-MOBILE-AWAY-STATUS left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Android acceptance remains NOT_CHECKED. Reestablish authenticated access to the selected isolated Waydroid QA target; verify Android release/API/ABI and existing QA APK/source/entrypoint digest, installed package equality and storage separation without replacing the paired app. - Run this task's full compact/enlarged-text Android away/return matrix: deterministic running-to-completed and running-to-failed while backgrounded, exact host/profile/session/run and canonical history, disconnect unknown then deliberate Retry, current exact approval grants and rejected late old-owner results. Record per-phase send/create/approval/Stop attempt counts; unobserved counts are not zero. Repair only reproduced Wing defects with focused regressions. Existing broad feature/YAML entries do not alone qualify this matrix.

### 29. LANDING-PRODUCT-PROOF-LIVE

- [Contrato y resultados](../../tasks/items/LANDING-PRODUCT-PROOF-LIVE.md): Live checks for LANDING-PRODUCT-PROOF.
- Estado: open; sección: Needs decision; goal: `LANDING-ONBOARDING`.
- Dependencias: LANDING-PRODUCT-PROOF.
- Alcance: Run the live checks the offline work for LANDING-PRODUCT-PROOF left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Named-platform/native and physical-device connection, full-app SSH login, real secure storage, live authenticated first reply/provider inference and combined approval/Stop/reconnect workflows remain separate qualification tasks. Browser fixtures/builds do not establish them. - Manual screen-reader qualification remains unperformed, including current selectable approval-detail semantics; speech/microphone, notifications and detached-run/background recovery are not qualified by this work. - Exact GitHub rendering/sanitization, real social-platform card cropping/cache behavior, public artifact freshness and consented human first-reply/onboarding review require their respective authorized environments. Local metadata and Markdown approximations are not those results. Broader landing/share parent acceptance must not be closed from this local docs/proof commit alone.

### 30. PARITY-MAESTRO-ANDROID-DEVICE-LIVE

- [Contrato y resultados](../../tasks/items/PARITY-MAESTRO-ANDROID-DEVICE-LIVE.md): Live checks for PARITY-MAESTRO-ANDROID-DEVICE.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: PARITY-MAESTRO-ANDROID-DEVICE.
- Alcance: Run the live checks the offline work for PARITY-MAESTRO-ANDROID-DEVICE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Normal authenticated ADB reachability for the selected Waydroid target; privileged diagnostics/repair, if required, need separate authority. No substitute phone required. - Review disposable target and installed .qa package; capture exact source/build/APK/flow fingerprints; actual Maestro launches and individual device exits. - Prove 3 sends, 2 decisions, 1 Stop, unchanged recovery counters and sess_1 retention; qualify earlier-history tail separately. - Prove late attachment rejection across sess_1/sess_2 and usable next pick. - Exact-artifact Android fresh welcome, keyboard Back/cancel, sanitized denial, explicit retry and saved-owner relaunch. - Other mapped Android journeys, without substituting unavailable-state checks for positive gaps. - Separate physical-device M2, TalkBack, native picker/IME, live Agent/provider and authoritative run qualification.

### 31. BACKEND-SSH-CONNECT-LIVE

- [Contrato y resultados](../../tasks/items/BACKEND-SSH-CONNECT-LIVE.md): Live checks for BACKEND-SSH-CONNECT.
- Estado: open; sección: Needs decision; goal: `REMOTE-BACKENDS`.
- Dependencias: BACKEND-SSH-CONNECT.
- Alcance: Run the live checks the offline work for BACKEND-SSH-CONNECT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No Android device/emulator was attached (adb devices -l was empty). Run the existing isolated Android SSH fixture journey and separate authorized controlled already-configured SSH/Agent target proof through the production form: host trust, authentication, explicit serve selection, profile/history loading, deliberate usable chat and transport-loss/no-replay behavior. SSH login or deterministic tests alone cannot qualify this outcome. - Preserve Linux full-app acceptance with a named controlled-target receipt. This run exercised Linux-hosted deterministic tests and SSH trust/authentication/cancellation, not successful native full-app forwarding. The existing key journey covers advertised API reads, not the added serve chat selection; native picker/keystore qualification remains with BACKEND-SSH-KEY-NATIVE. - Retain the task's required native/security review and qualification dependency. Independent offline code review does not close it. Review docs/quality/android-ssh-serve-offline.md for unsupported behavior: per-attempt host trust only, no durable SSH target/profile/session mapping or cold SSH relaunch; unsupported targets retain external-tunnel access.

### 32. DOC-BACKEND-DISCONNECT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-BACKEND-DISCONNECT-CONTRACT-LIVE.md): Live checks for DOC-BACKEND-DISCONNECT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `REMOTE-BACKENDS`.
- Dependencias: DOC-BACKEND-DISCONNECT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-BACKEND-DISCONNECT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Run the named Android SSH fixture interruption -> explicit Retry journey in integration_test/managed_ssh_key_native_test.dart on an approved disposable Android app/device with its owned ADB-reverse mapping; verify replaced forwarding port, exact host/profile/session and zero mutations. Prepared but not executed here. - On an approved Android live-Agent target, exercise Wi-Fi/tunnel interruption and explicit Retry with uncertain work; verify authoritative readback and zero implicit Send/approval/Stop/service restart. No live Agent or physical Android target was exercised. - Physical platform secure-storage durability and native document acquisition remain unqualified; fixture substitutions are not keystore/SAF evidence. Android away/process-death proof remains with its existing separate task.

### 33. PARITY-OFFICIAL-MATRIX-LIVE

- [Contrato y resultados](../../tasks/items/PARITY-OFFICIAL-MATRIX-LIVE.md): Live checks for PARITY-OFFICIAL-MATRIX.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: PARITY-OFFICIAL-MATRIX.
- Alcance: Run the live checks the offline work for PARITY-OFFICIAL-MATRIX left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 34. CONNECTION-OWNER-RECONNECT-LIVE

- [Contrato y resultados](../../tasks/items/CONNECTION-OWNER-RECONNECT-LIVE.md): Live checks for CONNECTION-OWNER-RECONNECT.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-OWNER-RECONNECT.
- Alcance: Run the live checks the offline work for CONNECTION-OWNER-RECONNECT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Native desktop/Android exact-owner reconnect with platform secure storage and an authenticated unmodified Hermes Agent requires separate qualification. - Live Agent/provider continuation and recovery require separate runtime evidence; the opt-in live browser case was not enabled.

### 35. M1-NOTIFICATION-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/M1-NOTIFICATION-CONTRACT-LIVE.md): Live checks for M1-NOTIFICATION-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M1`.
- Dependencias: M1-NOTIFICATION-CONTRACT.
- Alcance: Run the live checks the offline work for M1-NOTIFICATION-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Existing M1-MOBILE-AWAY-STATUS Android matrix remains NOT_CHECKED; this documentation assessment does not qualify reliable Android away/return status. - After separately scoped local-alert implementation, qualify permission denial/revocation, generic locked-screen payloads, exact-owner taps, focus transitions and deduplication on named native artifacts/targets. No application platform was exercised in this assessment. - Suspended/terminated Android/iOS and browser push remain unavailable pending an authoritative notification enrollment/routing/rotation/revocation/redemption contract, separate architecture/privacy/provider or relay consent decisions, and real platform delivery evidence. No provider or relay was selected or activated.

### 36. VERIFY-LIVE-WORKFLOW-RECOVERY-LIVE

- [Contrato y resultados](../../tasks/items/VERIFY-LIVE-WORKFLOW-RECOVERY-LIVE.md): Live checks for VERIFY-LIVE-WORKFLOW-RECOVERY.
- Estado: open; sección: Needs decision; goal: `M1`.
- Dependencias: VERIFY-LIVE-WORKFLOW-RECOVERY.
- Alcance: Run the live checks the offline work for VERIFY-LIVE-WORKFLOW-RECOVERY left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 37. CONNECTION-SETUP-AUTH-MATRIX-LIVE

- [Contrato y resultados](../../tasks/items/CONNECTION-SETUP-AUTH-MATRIX-LIVE.md): Live checks for CONNECTION-SETUP-AUTH-MATRIX.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: CONNECTION-SETUP-AUTH-MATRIX.
- Alcance: Run the live checks the offline work for CONNECTION-SETUP-AUTH-MATRIX left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Parent CONNECTION-SETUP-AUTH-MATRIX remains incomplete. Linux Local existing/preparation-needed requires an approved disposable unmodified Agent, private QA authentication, named isolated chooser/keychain target and qualified provider-call budget for an independently observed owned first reply; actual chooser/window sizing/keychain behavior remains NOT_CHECKED. - Android execution/manual Termux preparation and saved-owner recovery require an approved disposable device/package and Termux target, private QA authentication and qualified provider-call budget. Actual installation, physical keystore and assistive-technology output remain NOT_CHECKED; reuse the delivered Android fixture/runner rather than reimplementing it. - Native Remote/saved-connection authentication and fresh-process storage restoration require an approved HTTPS Agent, privately supplied disposable token, named platform/storage backend and isolated saved state. No live credentials or approved target were supplied; OAuth remains unsupported/unqualified, not simulated success. - Hosted-browser stranger-first-success is a separate topology requiring a compatible approved HTTPS Agent, trusted certificate, exact hosted Wing CORS origin, private QA authentication and a qualified provider-call budget. Record explicit capability discovery, separate persistence/connect/generation outcomes and one independently observed owned reply. No public binding, wildcard CORS, trust bypass or personal credential discovery is authorized. - Full live two-host profile/session collision qualification requires two approved authenticated disposable Agents, intentionally colliding profile/session IDs, isolated saved state and bounded delayed responses. Public selection/cancellation/retry must preserve origin-bound credentials and exact owner/history with zero management attempts or stale-owner mutations. Existing native/browser fixture receipts are reused only within their original scope.

### 38. DOC-M3-CONTRACT-CHECKPOINT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-CONTRACT-CHECKPOINT-LIVE.md): Live checks for DOC-M3-CONTRACT-CHECKPOINT.
- Estado: open; sección: Needs decision; goal: `M3`.
- Dependencias: DOC-M3-CONTRACT-CHECKPOINT.
- Alcance: Run the live checks the offline work for DOC-M3-CONTRACT-CHECKPOINT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Approved-device direct enrollment, native authentication, physical secure-input/storage and target-specific accessibility qualification remain unexecuted; no platform was exercised by this documentation task. - Combined isolated enrollment -> new-profile -> explicit Chat and failed-setup rollback require a suitable exact unmodified Agent contract before live execution. The inspected API server does not advertise Wing profile creation/grants, and dashboard/RPC best-effort create is not a transactional substitute. M3 remains unqualified; next separate source-evidence slice is DOC-M3-ROLLBACK-EVIDENCE.

### 39. DOC-M3-PROJECT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-PROJECT-CONTRACT-LIVE.md): Live checks for DOC-M3-PROJECT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M3-PROJECT`.
- Dependencias: DOC-M3-PROJECT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M3-PROJECT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Future Project creation qualification requires an approved disposable target and a suitable unmodified Agent contract; no native, browser, Android/device or live service was exercised. This documentation task does not qualify creation, assignment or Project-scoped Chat; M3-PROJECT remains unmet.

### 40. DOC-M3-PROVIDER-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-PROVIDER-CONTRACT-LIVE.md): Live checks for DOC-M3-PROVIDER-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M3-PROVIDER`.
- Dependencias: DOC-M3-PROVIDER-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M3-PROVIDER-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No live support is qualified. Future isolated Linux UI/provider validation, deployed capability advertisement, secret transport/storage, concurrent-writer/replay and activation checks require an eligible unmodified Agent contract plus separately scoped target/authority/effects consent; current inspected contracts do not establish the ADR guarantees. - Android/device and native UI qualification remain NOT_CHECKED; source and fixture test inspection does not qualify those platforms.

### 41. DOC-ARTIFACT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-ARTIFACT-CONTRACT-LIVE.md): Live checks for DOC-ARTIFACT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `ARTIFACTS`.
- Dependencias: DOC-ARTIFACT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-ARTIFACT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No application/platform or live Agent artifact retrieval/preview/save was exercised. Any future implementation needs separate named-platform/live authentication, hostile-content and persistence qualification; the artifact operation remains unavailable in Wing.

### 42. DOC-M4-MCP-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-MCP-CONTRACT-LIVE.md): Live checks for DOC-M4-MCP-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-MCP`.
- Dependencias: DOC-M4-MCP-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-MCP-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Native/live authenticated enable/disable and exact authoritative readback remain unqualified. A separately authorized isolated target can exercise them only after an unmodified Agent exposes the required exact operation, profile/platform identity, grants, concurrency and persistence/activation/retry guarantees; this documentation slice adds no write support.

### 43. DOC-M4-SCHEDULE-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-SCHEDULE-CONTRACT-LIVE.md): Live checks for DOC-M4-SCHEDULE-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-SCHEDULES`.
- Dependencias: DOC-M4-SCHEDULE-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-SCHEDULE-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No browser, native UI, device, live authentication, actual schedule pause/resume, execution or delivery qualification was performed. Any later operation journey requires a separately authorized disposable target exposing a suitable unmodified authoritative contract, with exact authority and consent gates. Current contract gaps do not block this evidence-only task.

### 44. DOC-M5-ANDROID-FIXTURE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M5-ANDROID-FIXTURE-LIVE.md): Live checks for DOC-M5-ANDROID-FIXTURE.
- Estado: open; sección: Needs decision; goal: `M5`.
- Dependencias: DOC-M5-ANDROID-FIXTURE.
- Alcance: Run the live checks the offline work for DOC-M5-ANDROID-FIXTURE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Original acceptance is not complete. Obtain a named owned disposable Android target, exclusive build/device access and the matching isolated com.trebuchetdynamics.hermes.wing.qa artifact before executing exactly these two Maestro flows. This offline worker performed no build, install, device operation or live service access. - Capture actual Android text and Markdown clipboard readback receipts and setup return-to-hub/zero-overflow receipts. Syntax and Linux-hosted widget tests do not establish those exits on Android.

### 45. DOC-M4-CONTRACT-CHECKPOINT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-CONTRACT-CHECKPOINT-LIVE.md): Live checks for DOC-M4-CONTRACT-CHECKPOINT.
- Estado: open; sección: Needs decision; goal: `M4-DISCOVER`.
- Dependencias: DOC-M4-CONTRACT-CHECKPOINT.
- Alcance: Run the live checks the offline work for DOC-M4-CONTRACT-CHECKPOINT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 46. DOC-M4-KANBAN-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-KANBAN-CONTRACT-LIVE.md): Live checks for DOC-M4-KANBAN-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-KANBAN`.
- Dependencias: DOC-M4-KANBAN-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-KANBAN-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platform was exercised. Authenticated bounded board reads/denials, exact board/Project ownership and accessible target-native inspection require a separately admitted disposable target after an eligible unmodified authoritative contract exists; no credentials or operations activated here.

### 47. DOC-M4-MEMORY-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-MEMORY-CONTRACT-LIVE.md): Live checks for DOC-M4-MEMORY-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-MEMORY`.
- Dependencias: DOC-M4-MEMORY-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-MEMORY-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platform was exercised. Authenticated bounded memory reads/denials, profile isolation/recreation, owner-change recovery and accessible target-native inspection require a suitable unmodified authoritative operation and a separately admitted disposable target; not authorized or qualified by this source-only task.

### 48. DOC-M4-PLATFORM-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-PLATFORM-CONTRACT-LIVE.md): Live checks for DOC-M4-PLATFORM-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-PLATFORMS`.
- Dependencias: DOC-M4-PLATFORM-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-PLATFORM-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 49. DOC-ACCOUNT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-ACCOUNT-CONTRACT-LIVE.md): Live checks for DOC-ACCOUNT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `ACCOUNT`.
- Dependencias: DOC-ACCOUNT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-ACCOUNT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Before future OAuth exposure, separately qualify an unmodified Agent's exact advertised operations/grants and private browser handoff on an isolated authorized target; Wing acquisition and account navigation remain unavailable. - Actual provider approval/expiry/refresh/revocation, cross-process commit/cancellation, native secure storage and platform end-to-end behavior were not exercised. No Flutter or upstream tests were run for this documentation-only task. DOC-ACCOUNT-REVOCATION-EVIDENCE retains the separate lifecycle evidence work.

### 50. DOC-NATIVE-DESIGN-REVIEW-LIVE

- [Contrato y resultados](../../tasks/items/DOC-NATIVE-DESIGN-REVIEW-LIVE.md): Live checks for DOC-NATIVE-DESIGN-REVIEW.
- Estado: open; sección: Needs decision; goal: `NATIVE-INTEGRATION`.
- Dependencias: DOC-NATIVE-DESIGN-REVIEW.
- Alcance: Run the live checks the offline work for DOC-NATIVE-DESIGN-REVIEW left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 51. DOC-VOICE-QUALIFICATION-LIVE

- [Contrato y resultados](../../tasks/items/DOC-VOICE-QUALIFICATION-LIVE.md): Live checks for DOC-VOICE-QUALIFICATION.
- Estado: open; sección: Needs decision; goal: `VOICE`.
- Dependencias: DOC-VOICE-QUALIFICATION.
- Alcance: Run the live checks the offline work for DOC-VOICE-QUALIFICATION left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Obtain separately approved physical Android target and capture consent, including OS recognizer processing and any permission denial/revoke testing; name actual device, recognizer package/version, effective locale and built-in microphone route. No device was selected or operated. - After isolated QA authentication, provider budget and exact installed-artifact identification are available, execute actual capture -> reviewed draft -> explicit Send plus cancel, permission/no-speech failure, explicit recovery and diagnostic privacy observations. No audio, recognized words or observation receipt was collected; all physical outcomes remain NOT_CHECKED. - Output cancellation/TTS, provider reply, hands-free/re-arm, broader ownership scenarios, wired/Bluetooth routes and acoustic behavior require separately approved named-target execution. This input-only preparation cannot satisfy the existing sanitized physical-voice recorder's broader gates or close VOICE acceptance.

### 52. LANDING-PAGES-QUALITY-LIVE

- [Contrato y resultados](../../tasks/items/LANDING-PAGES-QUALITY-LIVE.md): Live checks for LANDING-PAGES-QUALITY.
- Estado: open; sección: Needs decision; goal: `LANDING-ONBOARDING`.
- Dependencias: LANDING-PAGES-QUALITY.
- Alcance: Run the live checks the offline work for LANDING-PAGES-QUALITY left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Authorized CI execution with its pinned Flutter 3.44.6 and any Pages publication/public CDN freshness readback were not performed. Coordinator integration and publication remain separate from this local commit. - Actual browser-chrome zoom, screen readers, physical devices and real-device/field performance remain unqualified; automated text scaling/effective-viewport reflow and focused semantic/contrast guards are not full accessibility certification. - Authenticated first reply and combined real-Agent/provider workflows remain with existing CONNECTION-SETUP-AUTH-MATRIX and PARITY-LIVE-WORKFLOW owners; this task creates no duplicate live QA requirement.

### 53. BACKEND-SSH-KEY-NATIVE-LIVE

- [Contrato y resultados](../../tasks/items/BACKEND-SSH-KEY-NATIVE-LIVE.md): Live checks for BACKEND-SSH-KEY-NATIVE.
- Estado: open; sección: Needs decision; goal: `REMOTE-BACKENDS`.
- Dependencias: BACKEND-SSH-KEY-NATIVE.
- Alcance: Run the live checks the offline work for BACKEND-SSH-KEY-NATIVE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Full-app qualification remains open. Provide the approved host, independently reviewed fingerprint, permitted SSH authentication and separate Agent credential through an approved secret channel; none was supplied with this invocation. Do not infer authorization for provider spending or personal-runtime changes.

### 54. DOC-M3-ROLLBACK-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-ROLLBACK-EVIDENCE-LIVE.md): Live checks for DOC-M3-ROLLBACK-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `M3`.
- Dependencias: DOC-M3-ROLLBACK-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-M3-ROLLBACK-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Current new-profile whole-setup rollback and unchanged existing-profile identity remain UNVERIFIED. A separately authorized isolated failure/readback qualification requires a suitable exact unmodified Agent create/identity/outcome contract first; this documentation task authorizes no new attempt. - Native/device secure-storage and target-specific onboarding behavior remain separately unqualified; no platform was exercised by this task.

### 55. DOC-M3-PROJECT-ASSIGNMENT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-PROJECT-ASSIGNMENT-CONTRACT-LIVE.md): Live checks for DOC-M3-PROJECT-ASSIGNMENT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M3-PROJECT`.
- Dependencias: DOC-M3-PROJECT-ASSIGNMENT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M3-PROJECT-ASSIGNMENT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No browser, native desktop, Android/physical device, production or live Agent exercised. Future assignment/Project-aware Chat runtime qualification requires a separately approved disposable target and a suitable unmodified authoritative contract. Current source gaps do not authorize activation; M3-PROJECT remains unmet.

### 56. DOC-M3-PROVIDER-REMOVAL-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M3-PROVIDER-REMOVAL-CONTRACT-LIVE.md): Live checks for DOC-M3-PROVIDER-REMOVAL-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M3-PROVIDER`.
- Dependencias: DOC-M3-PROVIDER-REMOVAL-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M3-PROVIDER-REMOVAL-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 57. DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE-LIVE.md): Live checks for DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `ARTIFACTS`.
- Dependencias: DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Future retrieved-text implementation requires an eligible unmodified Agent contract, then separately authorized named-platform/live authentication, hostile-content/network isolation, denial/cancellation/owner-loss and persistence qualification. No application/browser/native/device or live Agent artifact retrieval, preview or save was exercised; ARTIFACTS remains open and artifact operations remain unavailable in Wing.

### 58. DOC-M4-MCP-CONFIG-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-MCP-CONFIG-CONTRACT-LIVE.md): Live checks for DOC-M4-MCP-CONFIG-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-MCP`.
- Dependencias: DOC-M4-MCP-CONFIG-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-MCP-CONFIG-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No application, browser, native desktop, physical Android/device, live authentication, provider or Agent operation was exercised. After a suitable unmodified Agent advertises a bounded sanitized exact-authorized MCP config read, separately admit a disposable native/live read-refresh and auth-denial/profile-isolation-recreation journey. This source-only task authorizes no installation, config write, probe, OAuth or arbitrary command execution.

### 59. DOC-M4-SCHEDULE-DELIVERY-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-SCHEDULE-DELIVERY-CONTRACT-LIVE.md): Live checks for DOC-M4-SCHEDULE-DELIVERY-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-SCHEDULES`.
- Dependencias: DOC-M4-SCHEDULE-DELIVERY-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-SCHEDULE-DELIVERY-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No browser/native/device UI, live authentication, job execution or delivery was exercised. Any future existing-job delivery edit requires a separately authorized disposable target exposing a suitable unmodified advertised operation, exact grants, identity/revision checks and safe reconciliation; credential provisioning for another target requires its own write-only contract. These absent guarantees do not block this read-only evidence task.

### 60. DOC-M5-LARGE-TEXT-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M5-LARGE-TEXT-EVIDENCE-LIVE.md): Live checks for DOC-M5-LARGE-TEXT-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `M5`.
- Dependencias: DOC-M5-LARGE-TEXT-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-M5-LARGE-TEXT-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Named owned Android target and matching isolated QA artifact are still needed for actual clipboard readback, Android system 200% text, keyboard/CJK IME and TalkBack focus/actions; no device, browser or native runtime journey ran in this source-inspection task. - Android save/share remains unsupported by the current native saver gate; injected supported-saving fixtures do not qualify it. Existing fixture share-sheet acceptance reconciliation remains unchanged.

### 61. DOC-M4-DISCOVERY-SELECTION-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-DISCOVERY-SELECTION-CONTRACT-LIVE.md): Live checks for DOC-M4-DISCOVERY-SELECTION-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-DISCOVER`.
- Dependencias: DOC-M4-DISCOVERY-SELECTION-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-DISCOVERY-SELECTION-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platform/native/browser/live journey exercised. Only after an eligible authoritative install contract exists and a separately authorized isolated target is available: authenticated install/denial, exact-profile authoritative readback, failure/uncertainty/no-replay and named-platform accessible selection/consent/recovery journeys. This receipt authorizes no installation.

### 62. DOC-M4-HOST-LIFECYCLE-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-HOST-LIFECYCLE-EVIDENCE-LIVE.md): Live checks for DOC-M4-HOST-LIFECYCLE-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `M4-PLATFORMS`.
- Dependencias: DOC-M4-HOST-LIFECYCLE-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-M4-HOST-LIFECYCLE-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Named Linux/Android direct Agent setup and migration acceptance remains with CONNECTION-LINK-RETIREMENT; no native app, physical device, installed service, live Agent or messaging account was exercised here. - Any future Agent-owned lifecycle qualification requires an eligible exact unmodified Agent contract and separately admitted disposable target, including authorization/resource/approval binding, stale/replay denial and artifact/process-correlated activation versus restored-health outcomes. Historical missing Link approval and recovered-service receipts are evidence gaps, not requests or permission to revive Link.

### 63. DOC-M4-KANBAN-PAGINATION-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-KANBAN-PAGINATION-EVIDENCE-LIVE.md): Live checks for DOC-M4-KANBAN-PAGINATION-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `M4-KANBAN`.
- Dependencias: DOC-M4-KANBAN-PAGINATION-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-M4-KANBAN-PAGINATION-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 64. DOC-M4-MEMORY-CAPACITY-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-M4-MEMORY-CAPACITY-CONTRACT-LIVE.md): Live checks for DOC-M4-MEMORY-CAPACITY-CONTRACT.
- Estado: open; sección: Needs decision; goal: `M4-MEMORY`.
- Dependencias: DOC-M4-MEMORY-CAPACITY-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-M4-MEMORY-CAPACITY-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platform exercised. Only after separate admission and a suitable unmodified exact advertised bounded status/capacity contract: qualify authenticated reads/denials, profile A-to-B-to-A/recreation, owner-change recovery, declared effects and accessible target-native inspection using disposable state. No Agent/provider operation was invoked here.

### 65. SECURITY-RETAINED-RELEASE-AUDIT-LIVE

- [Contrato y resultados](../../tasks/items/SECURITY-RETAINED-RELEASE-AUDIT-LIVE.md): Live checks for SECURITY-RETAINED-RELEASE-AUDIT.
- Estado: open; sección: Needs decision; goal: `SECURITY`.
- Dependencias: SECURITY-RETAINED-RELEASE-AUDIT.
- Alcance: Run the live checks the offline work for SECURITY-RETAINED-RELEASE-AUDIT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Native/device and live Agent/provider qualification were not exercised; evidence is Linux-hosted Node audit/guard only. - Named-target release signing, installation, activation, rollback and distribution remain separate qualification; no release workflow or publication was executed.

### 66. DOC-ACCOUNT-REVOCATION-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-ACCOUNT-REVOCATION-EVIDENCE-LIVE.md): Live checks for DOC-ACCOUNT-REVOCATION-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `ACCOUNT`.
- Dependencias: DOC-ACCOUNT-REVOCATION-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-ACCOUNT-REVOCATION-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Separately authorized isolated-provider qualification of actual access-token expiry, rejected refresh and provider-side invalidation scope/acknowledgement; none executed here. - Separately authorized logout followed by authoritative root/pool/CLI resolution checks, in-flight login/refresh and cross-process races, and other-profile/device effects; source findings do not establish post-logout closure. - Current deployed Agent exact lifecycle capabilities/grants and named-platform secure-storage/end-to-end behavior remain unverified; no Wing account lifecycle operation is admitted by this study.

### 67. DOC-NATIVE-FAILURE-BOUNDARY-LIVE

- [Contrato y resultados](../../tasks/items/DOC-NATIVE-FAILURE-BOUNDARY-LIVE.md): Live checks for DOC-NATIVE-FAILURE-BOUNDARY.
- Estado: open; sección: Needs decision; goal: `NATIVE-INTEGRATION`.
- Dependencias: DOC-NATIVE-FAILURE-BOUNDARY.
- Alcance: Run the live checks the offline work for DOC-NATIVE-FAILURE-BOUNDARY left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platform was exercised at runtime. Separately scoped isolated Linux native evidence must check actual chooser cancellation/exit/modality, delayed or failed metadata IO responsiveness and outstanding-work behavior across mode changes, disposal and re-entry. Existing provider-overridden/completer tests and historical GTK receipts do not establish these guarantees. - Other named-platform behavior and any future privileged operation require their own reviewed contracts and runtime receipts. Preparation grants no native activation rights; this review does not qualify OS rollback, keyring/authentication, process cleanup or NATIVE-INTEGRATION.

### 68. DOC-VOICE-OUTPUT-CANCEL-EVIDENCE-LIVE

- [Contrato y resultados](../../tasks/items/DOC-VOICE-OUTPUT-CANCEL-EVIDENCE-LIVE.md): Live checks for DOC-VOICE-OUTPUT-CANCEL-EVIDENCE.
- Estado: open; sección: Needs decision; goal: `VOICE`.
- Dependencias: DOC-VOICE-OUTPUT-CANCEL-EVIDENCE.
- Alcance: Run the live checks the offline work for DOC-VOICE-OUTPUT-CANCEL-EVIDENCE left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Separately authorize and identify a physical Android QA target, exact installed APK/source/build, built-in speaker route, effective system TTS package/version and voice/locale, including playback/bystander/content and network-processing consent. No target or actual engine was selected here. - On that approved artifact, establish the pending-configuration ordering and actual settlement for stop/disposal, then observe no late audio, replay or stale callback; verify retained text/draft, zero automatic capture/re-arm/sends and bounded diagnostic privacy. If ordering cannot be established on the unchanged artifact, leave that branch NOT_CHECKED. No physical or acoustic acceptance is claimed.

### 69. DEV-001-c7-LIVE

- [Contrato y resultados](../../tasks/items/DEV-001-c7-LIVE.md): Live checks for DEV-001-c7.
- Estado: open; sección: Needs decision; goal: `INTEGRATION`.
- Dependencias: DEV-001-c7.
- Alcance: Run the live checks the offline work for DEV-001-c7 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No platforms were exercised beyond Linux-hosted SDK static tooling. Native SSH/device/secure-storage/live Agent reachability and actual IME/screen-reader behavior remain unqualified here and retain existing live qualification tasks; this review grants no live access.

### 70. PARITYUPDATE-001-aa-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-001-aa-LIVE.md): Live checks for PARITYUPDATE-001-aa.
- Estado: open; sección: Needs decision; goal: `CONNECTION-PATHS`.
- Dependencias: PARITYUPDATE-001-aa.
- Alcance: Run the live checks the offline work for PARITYUPDATE-001-aa left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - No product platform was exercised. Named-target canonical attachment/reconnect/disconnect qualification remains separate from this source-only task; retain existing Linux/Android/SSH/remote qualification owners and require a separately admitted implementation before positive canonical-native acceptance.

### 71. PARITYUPDATE-002-5c-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-002-5c-LIVE.md): Live checks for PARITYUPDATE-002-5c.
- Estado: open; sección: Needs decision; goal: `CHAT-FIDELITY`.
- Dependencias: PARITYUPDATE-002-5c.
- Alcance: Run the live checks the offline work for PARITYUPDATE-002-5c left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Future separately authorized Linux/Android qualification of canonical authentication, exact advertised operation/grants, admission/queue races, Stop settlement and clarification recovery remains unrun. This source-only task exercised no application platform, live Agent, device, inference, submission, queue mutation or answer; no runtime cell advances. Canonical send-time user-row receipts and authoritative batch/partial-lock reconnect projection remain absent at the inspected pin and cannot be established by live testing alone.

### 72. PARITYUPDATE-003-b1-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-003-b1-LIVE.md): Live checks for PARITYUPDATE-003-b1.
- Estado: open; sección: Needs decision; goal: `ACCOUNT`.
- Dependencias: PARITYUPDATE-003-b1.
- Alcance: Run the live checks the offline work for PARITYUPDATE-003-b1 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Only Linux-host source/document validation was exercised. No browser authorization, login, credential/cookie acquisition, ticket mint, refresh, logout, revocation, Agent runtime or platform test was performed. - A separately bounded future OAuth design and authorized isolated live qualification must establish deployed advertisement, secure-storage-only custody, exact-connection browser return/background behavior, cancellation and logout outcomes on each named platform. Source resolution does not qualify native revocation, Cloud discovery/cascade or provider-account OAuth.

### 73. PARITYUPDATE-004-48-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-004-48-LIVE.md): Live checks for PARITYUPDATE-004-48.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: PARITYUPDATE-004-48.
- Alcance: Run the live checks the offline work for PARITYUPDATE-004-48 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Only Linux-host source/document validation was exercised. No Agent protocol/runtime tests, application/browser/device runs, network playback, export/import, secret acquisition, package execution, computer control or image generation was performed; no Linux/Android runtime cell advanced. - Future separately bounded consumers need exact connected-Agent admission and named-platform qualification. Preserve export snapshot/completeness limits, foreign preview-content/privacy limits, Vault secret/concurrency boundaries, Agent/Desktop package authority split, Screen secret-safe ticket delivery/non-canvas/reconnect gaps, and Pets profile/run/spend/cancellation gaps. Optional Radio is client-local, not blocked on an Agent API, but media/privacy/lifecycle qualification remains separate. - Coordinator review and integration remain separate from this local worker commit. The document specifies only a conditional read-only foreign list/preview successor with explicit transport/admission dependency; no new task was scheduled or active owner expanded.

### 74. README-001-62-LIVE

- [Contrato y resultados](../../tasks/items/README-001-62-LIVE.md): Live checks for README-001-62.
- Estado: open; sección: Needs decision; goal: `LANDING-ONBOARDING`.
- Dependencias: README-001-62.
- Alcance: Run the live checks the offline work for README-001-62 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Hosted GitHub rendering/sanitizer was not exercised; only source-bound local GitHub-like previews were inspected. - Existing native-device, authenticated Agent/provider, SSH, voice, notifications and recovery qualification remain with their existing live owners; this documentation change claims none of them.

### 75. MT-VERIFY-BROWSER-GATES-LIVE

- [Contrato y resultados](../../tasks/items/MT-VERIFY-BROWSER-GATES-LIVE.md): Live checks for MT-VERIFY-BROWSER-GATES.
- Estado: open; sección: Needs decision; goal: `INTEGRATION`.
- Dependencias: MT-VERIFY-BROWSER-GATES.
- Alcance: Run the live checks the offline work for MT-VERIFY-BROWSER-GATES left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Canonical live-Agent say-hi opt-in was explicitly skipped; no live Agent/provider authentication or inference qualified. - Physical Android, native desktop UI, microphone/acoustics, installation/signing/update and human platform acceptance remain separate platform/live work; only Linux-host headless Chromium/offline tooling exercised.

### 76. PARITYUPDATE-005-11-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-005-11-LIVE.md): Live checks for PARITYUPDATE-005-11.
- Estado: open; sección: Needs decision; goal: `INTEGRATION`.
- Dependencias: PARITYUPDATE-005-11.
- Alcance: Run the live checks the offline work for PARITYUPDATE-005-11 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Only Linux-hosted deterministic Flutter widget tests were exercised. Native desktop, physical Android, live Agent/provider and screen-reader qualification remain unverified; no live support is inferred.

### 77. VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART-LIVE

- [Contrato y resultados](../../tasks/items/VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART-LIVE.md): Live checks for VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART.
- Estado: open; sección: Needs decision; goal: `CHAT-FIDELITY`.
- Dependencias: VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART.
- Alcance: Run the live checks the offline work for VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Live unmodified Hermes Agent authentication, provider/tool execution and real approvals/Stop remain unqualified; no credentials, inference, upstream edits or live operations were used. - Physical mobile/Android, physical keyboard and screen-reader qualification remain separate. Native coverage here is Linux x86_64 GTK/Xvfb with injected key events and programmatic viewport preparation, not an entirely keyboard-only scrolling journey. - Full application saved-endpoint startup and OS secure-storage recovery are not qualified by this isolated Chat target; Linux selection preferences are real, while the run-lease store and HTTP/SSE transports are synthetic test seams.

### 78. PARITY-NATIVE-LINUX-LIVE

- [Contrato y resultados](../../tasks/items/PARITY-NATIVE-LINUX-LIVE.md): Live checks for PARITY-NATIVE-LINUX.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: PARITY-NATIVE-LINUX.
- Alcance: Run the live checks the offline work for PARITY-NATIVE-LINUX left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Real Agent/provider/SSH/OAuth operation/grant authority, inference and authoritative approval/terminal cancellation remain separately unqualified. - Android/device and Wayland/other-IME/screen-reader qualification were not exercised; native X11 fixture results are not substitutes. - Physical microphone/acoustic routing, actual speech and audio hardware remain unqualified; unavailable capture assertions do not qualify positive voice support. - OS keyring, saved-credential upgrade/readback and signed installer/service/update/rollback acceptance need separately authorized platform checks.

### 79. PARITYUPDATE-006-f4-LIVE

- [Contrato y resultados](../../tasks/items/PARITYUPDATE-006-f4-LIVE.md): Live checks for PARITYUPDATE-006-f4.
- Estado: open; sección: Needs decision; goal: `INTEGRATION`.
- Dependencias: PARITYUPDATE-006-f4.
- Alcance: Run the live checks the offline work for PARITYUPDATE-006-f4 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Physical keyboard/OS-window resize and screen-reader qualification remain unverified; retained Linux GTK/Xvfb native evidence uses WidgetTester input and framework viewport resizing. - Android/other platforms, live Agent/provider transport, OS keyring, install/update/signing and release qualification remain unchanged and unverified by this deterministic fixture.

### 80. DOC-PARITY-TAB-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-PARITY-TAB-CONTRACT-LIVE.md): Live checks for DOC-PARITY-TAB-CONTRACT.
- Estado: open; sección: Needs decision; goal: `PARITY-TABS`.
- Dependencias: DOC-PARITY-TAB-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-PARITY-TAB-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Isolated Android public-control multi-conversation journeys remain required on an allocated emulator/device. Native-serve tabs including Android SSH serve remain unavailable pending authoritative lifecycle reconciliation; exclusion is not Android tab acceptance. - Physical/native accessibility, screen readers, platform IME, microphone/speaker/echo/Bluetooth and acoustic speech behavior, live unmodified Agent/authentication/provider/SSH qualification remain separate and unexecuted by this worker. No live provider spending, production operation, deployment or upstream modification.

### 81. ANDROID-CHAT-TOUCH-POLISH-LIVE

- [Contrato y resultados](../../tasks/items/ANDROID-CHAT-TOUCH-POLISH-LIVE.md): Live checks for ANDROID-CHAT-TOUCH-POLISH.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: ANDROID-CHAT-TOUCH-POLISH.
- Alcance: Run the live checks the offline work for ANDROID-CHAT-TOUCH-POLISH left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Isolated Waydroid Android public-control, real software-keyboard/Back/cancel, text-scaling and owner-switch journeys: Waydroid reports RUNNING but IP UNKNOWN, ADB lists no target, and the bounded shell probe requires root/operator access. No container restart, escalation or installation attempted. Status/probe log: $TMPDIR/waydroid-access.log. These are pending qualification, not offline blockers. - TalkBack remains UNVERIFIED. Physical Android device/native accessibility, live SSH/Agent/provider, secure-storage and acoustic outcomes were not exercised. Widget insets/platform Back and Chromium widths do not qualify Android input. - Human final visual/mockup acceptance and complete Android multi-session parity remain unqualified. Native-serve tabs (including Android SSH serve) and cross-profile background streaming retain the predecessor's explicit unsupported boundaries.

### 82. WING-001-b3-LIVE

- [Contrato y resultados](../../tasks/items/WING-001-b3-LIVE.md): Live checks for WING-001-b3.
- Estado: open; sección: Needs decision; goal: `REMOTE-BACKENDS`.
- Dependencias: WING-001-b3.
- Alcance: Run the live checks the offline work for WING-001-b3 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 83. PARITYGAP-002-76-LIVE

- [Contrato y resultados](../../tasks/items/PARITYGAP-002-76-LIVE.md): Live checks for PARITYGAP-002-76.
- Estado: open; sección: Needs decision; goal: `PARITY`.
- Dependencias: PARITYGAP-002-76.
- Alcance: Run the live checks the offline work for PARITYGAP-002-76 left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Named isolated Linux GTK paged-JSON preparation/save/replacement-consent/refusal/cancel/owner-switch and destination-byte readback. Retained loaded-export native test was updated but not run on GTK here. - Actual unmodified Agent projection, including compacted and ancestor records, remains live qualification. Other platforms and HD-EXPORT runtime cells remain open; no frozen snapshot, backup/import, canonical export or private ticket support is claimed.

### 84. PARITYGAP-001-3f-LIVE

- [Contrato y resultados](../../tasks/items/PARITYGAP-001-3f-LIVE.md): Live checks for PARITYGAP-001-3f.
- Estado: open; sección: Needs decision; goal: `SLASH-CATALOG`.
- Dependencias: PARITYGAP-001-3f.
- Alcance: Run the live checks the offline work for PARITYGAP-001-3f left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Physical Android IME, TalkBack, touch/keyboard and installed-device qualification remain separate; only Linux-hosted widgets and deterministic Linux Chromium were exercised. - No live Agent/provider or other native platform qualification was performed. Agent-config defaults remain explicitly unsynced; authoritative slash catalog/dispatch is unchanged and unavailable through this local control.

### 85. DOC-PARITY-TAB-RECONNECT-CONTRACT-LIVE

- [Contrato y resultados](../../tasks/items/DOC-PARITY-TAB-RECONNECT-CONTRACT-LIVE.md): Live checks for DOC-PARITY-TAB-RECONNECT-CONTRACT.
- Estado: open; sección: Needs decision; goal: `PARITY-TABS`.
- Dependencias: DOC-PARITY-TAB-RECONNECT-CONTRACT.
- Alcance: Run the live checks the offline work for DOC-PARITY-TAB-RECONNECT-CONTRACT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target:

### 86. ANDROID-CANONICAL-BOT-CHAT-LIVE

- [Contrato y resultados](../../tasks/items/ANDROID-CANONICAL-BOT-CHAT-LIVE.md): Live checks for ANDROID-CANONICAL-BOT-CHAT.
- Estado: open; sección: Needs decision; goal: `PARITY-TABS`.
- Dependencias: ANDROID-CANONICAL-BOT-CHAT.
- Alcance: Run the live checks the offline work for ANDROID-CANONICAL-BOT-CHAT left pending.
- Aceptación pendiente registrada:
  - Each check passes on the real target: - Isolated Android .qa device/emulator journeys; adb devices -l returned no attached targets. Android-target widget fixtures are not device execution. - Live unmodified Agent authentication, canonical lookup/create/title-conflict/concurrent-client adoption and actual managed SSH. No live inference used or authorized by this task. - Native accessibility/screen reader, IME and process-death qualification; long forever-chat/frame-bound qualification remains pending.

