# Plan maestro: clon 1:1 de Hermes Desktop en Flutter

## Ejecución vigente — 2026-10-24

El propietario confirmó implementar todo el plan contra Desktop actual, apariencia
literal incluida, en Linux, Android, web, macOS y Windows. La excepción Muse/Duet y
criaturas locales queda sustituida; sus preferencias guardadas se conservan inertes.
Una función sin contrato o evidencia queda pendiente: no se acepta como paridad.

Referencia de esta ejecución: `14e1e43a23761b369641208e204365cd6cb9399d`
de NousResearch/hermes-agent, HEAD/main consultado el 2026-10-24. Checkout separado
solo para lectura. Frente al pin anterior `47b23fa048`, Desktop/shared tienen 316
archivos cambiados (16,622 inserciones y 3,032 eliminaciones); las 50 familias son
inventario inicial, no cobertura validada del nuevo pin. No se repinan pruebas antiguas.

Disponibilidad confirmada por el propietario: usar los targets presentes; no hay
Agent desechable de QA preparado. Esta sesión valida Linux/Chromium donde las
herramientas lo permiten. Android/macOS/Windows, inferencia real, voz física y
ciclo de distribución permanecen pendientes, sin sustituirlos por fixtures.

### Estado de los paquetes

| Paquete | Estado actual de ejecución |
| --- | --- |
| F0 | Flutter 3.44.2 y Node 22 preparados; dependencias bloqueadas resueltas. Admisión de credenciales legacy corregida; 675 pruebas focalizadas y análisis aprobados. Suites completas interrumpidas por reinicio del entorno; pendientes. CLI `autowork` no instalada: registro de tareas pendiente, sin transiciones inventadas. |
| CLONE-01 | Tokens existentes; geometría de mensajes/compositor adaptada al pin actual. Baseline visual emparejado pendiente. |
| CLONE-02 | Shell final, destinos y overlays oficiales pendientes; conservar rutas existentes durante migración. |
| CLONE-03 | Búsqueda de categorías y controles locales; Appearance separa Theme/Typography con navegación y enlaces `page`/`setting`; selector compacto único, breadcrumb navegable y selección de hoja actual. Árbol completo y demás campos pendientes. Galería de criaturas Wing retirada sin borrar preferencias. |
| CLONE-04 | Onboarding completo y guía pendientes; preservar conexión directa ya implementada. |
| CLONE-05 | Remote/SSH y gateway sign-in existentes; attachment canónico, Cloud y cobertura completa OAuth pendientes. |
| CLONE-06 | Rutas legacy de credenciales rechazadas antes de red y formularios sin entrada de secretos; contrato positivo sigue pendiente. Modelos mantienen gates independientes. |
| CLONE-07 | Projects/multifolder/worktrees pendientes de contratos exactos y caller. |
| CLONE-08 | Transcript existente y geometría actualizada; completar controles/adjuntos/ramificación según contratos. |
| CLONE-09 | Recibos durables, resultado incierto, FIFO y aclaraciones completas pendientes. |
| CLONE-10 | Bot Chat existente preservado; fallback visual estático oficial añadido. Roster completo, multipane, ventanas y lifecycle pendientes. |
| CLONE-11 | Files continúa CONTRACT-UNREADY; PTY/review pendientes, sin shell/SFTP sustituto. |
| CLONE-12 | Artifacts y preview aislado pendientes; export de transcript no los satisface. |
| CLONE-13 | Completar Skills/MCP/memoria/cron/Messaging/Webhooks/Kanban tras contratos por operación. |
| CLONE-14 | Vault/paquetes/Screen/Pets pendientes; no cargar JS Electron ni llamar proveedores sin admisión. |
| CLONE-15 | Radio/Starmap/importación pendientes. |
| CLONE-16 | Campaña Linux/Android existente; calificación actual de cinco plataformas, voz física y distribución pendientes. |

Recibo del primer lote y límites: [validación 2026-10-24](../quality/2026-10-24-desktop-parity-first-batch.md).
Build web y Linux debug aprobados; Chromium tiene 12 casos de superficies y 2 de
búsqueda aprobados. No son paridad visual emparejada ni aceptación native/live.

Cada paquete conserva los contratos y dependencias detallados abajo; este estado
no crea otra cola ni convierte cierres por exención en aceptación. La comparación
actual de implementación con todo el nuevo upstream aún no está terminada.

Seguimiento local: el contador de tareas separa exenciones, aplazamientos, retiros,
sustituciones, recibos y cierres históricos; no presenta `done` como porcentaje de
paridad. Appearance incorpora los hijos Theme/Typography y los targets oficiales
`theme`/`chat-text-scale`, conservando claves y valores. Una búsqueda abierta no
sobrescribe una navegación posterior. El recibo del primer lote conserva sus
resultados originales y añade el seguimiento de estas comprobaciones.

### Admisión contractual de credenciales

Fuente actual: `hermes_cli/web_routers/ops.py` expone pool add con unsuppression y
remove por índice con cleanup de la fuente; `config_env.py` expone validación por
clave/valor con efectos de red. Estos contratos no equivalen a reemplazo/remoción
por ID y revisión con idempotencia durable y consentimiento de efectos del ADR.
Las rutas legacy Wing `/api/providers/{slug}/credential` no se admiten por tener
scope `providers:write`. Canal y UI rechazan Set/Remove/Validate; inventario y
operaciones de modelos retienen sus gates independientes. El cliente HTTP de bajo
nivel permanece para pruebas de protocolo, sin caller de credenciales de producto.
No hay soporte positivo de credenciales ni resultado live declarado.

### Apariencia entregada en este lote

Fuentes del pin: `thread/user-message.tsx` usa fila completa y `rounded-xl`;
`thread/assistant-message.tsx` usa prosa sin burbuja; compositor usa `rounded-2xl`.
Con `styles.css --radius-scalar: 0.2`, los radios son 3.2 y 4.8 px. Se mantienen
identidades, selección, acciones, controles táctiles accesibles y borradores.
Avatares de contactos usan las formas fallback y colores de `hermes-bots/avatar.tsx`
y `lib/profile-color.ts`; no implementan imágenes/meta Agent, blobatar ni animación.
La búsqueda Settings solo indexa categorías/temas ya implementados: no ofrece
controles ficticios, lecturas Agent ni mutaciones al buscar/cancelar.

Los apartados siguientes conservan el plan y recibos históricos; sus pins,
excepciones visuales y declaraciones de plataforma no prevalecen sobre esta sección.

## Mandato y estado

Requisito del propietario: «literal un clon de Hermes Desktop», no una aplicación
inspirada en sus colores. Conservar estructura, navegación, texto, interacciones,
estados, atajos y recuperación. Android debe adaptar la presentación al teléfono
sin eliminar resultados funcionales. Este es un proyecto completo, no un ajuste UI.

Estado: plan contrastado con fuente oficial; pendiente de admisión de tareas nuevas. No declara implementación,
paridad ni aceptación runtime. Referencia inspeccionada de solo lectura:
`47b23fa048536c413a53ae5ad391f9a911f5d4e5`, `apps/desktop/` en NousResearch/hermes-agent.
No se afirma que sea el último upstream remoto. La matriz anterior está fijada a
otro commit; se conserva como evidencia histórica, no se repinea para fingir pruebas.

## Decisiones del planificador

1. Portar flujos verticales, no pantallas vacías ni Electron internals. Flutter,
   Riverpod y Go Router existentes; Hermes Agent conserva toda autoridad de dominio.
2. Chat es home. Separar destinos duraderos, overlays cortos y panes persistentes
   como lo define Desktop DESIGN.md. Evitar mantener la navegación propia actual
   como si fuera paridad oficial. La migración debe preservar URLs/identidades/drafts.
3. El baseline visual es Desktop/Linux; Android tiene touch/IME/Back/hojas adaptativos.
   Web no hereda privilegios nativos. macOS/Windows quedan con calificación separada.
4. Comparar escenas idénticas con datos sintéticos: luz/oscuro, vacío/loading/error,
   desconexión, permisos, texto 100/200%, motion reducido y transcript largo.
5. No sustituir contratos ausentes por shell, archivos Agent, Wing Link o inventarios
   paralelos. El clon literal completo está condicionado a contratos autorizados:
   una apariencia idéntica no inventa soporte. Registrar cada divergencia bloqueada.
6. Mantener todos los logros ya entregados: Bot Chat, Back, TTS cancelado y fences.
   No reemplazar código moderno por ramas antiguas para acercar una captura.
7. Entregar un resultado usable por commit, integrar/publicar main bajo autoridad
   vigente y retirar ramas temporales limpias. Planear no ejecuta estas entregas.

Alternativas rechazadas: copiar colores solamente (no cumple), portar Electron
línea por línea (rompe arquitectura/plataformas), rediseñar Wing libremente (no
cumple fidelidad), habilitar operaciones por endpoints parecidos (no es autoridad).

## Fases y dependencias

### F0 — Base verificable y contratos

- Congelar el pin oficial y catalogar rutas, overlays, panes, contribuciones y
  controles. Reusar las 50 familias HD existentes sin alterar sus recibos históricos.
- Crear escenas comparables y una tabla control→acción→estado→autoridad→test.
- Corregir admisión contractual de proveedores en canal y UI; no basta permisos.
- Implementar LINUXQA-001-e41e98e5 y sus pruebas, luego adaptador/driver/checker
  de la campaña existente. No gastar la fase en nuevas auditorías repetidas.
- Salida: próximo slice sin decisiones de producto pendientes, contratos exactos
  identificados, gates offline ejecutables y divergencias externas acotadas.

### F1 — Identidad visual y shell literal

- Tokens/typography/iconografía/densidad/espaciado/elevación desde primitives y
  styles oficiales; preservar objetivos táctiles y semántica aun con glyphs pequeños.
- Navegación oficial, sidebar, proyectos/sesiones, titlebar/statusbar, menús,
  overlays con retorno, command center y settings; sin perder borradores.
- Salida: comparación visual y teclado de escenas en Linux y Android. No aceptar
  solo compilación, widgets presentes o una puntuación visual inventada.

### F2 — Conexión y ownership canónicos

- Local/remote/SSH/Cloud/OAuth según contract availability, selector de dispositivo,
  perfiles y Projects explícitos, tickets transitorios y credenciales seguras.
- Nunca arrancar runtime alternativo tras fallo remoto; trust fingerprint fail-closed.
- Salida: cancelar/error/reauth/reconnect/relaunch preservan endpoint/profile/session.
  Resolver adopción canónica antes de ampliar envíos/cola en F3.

### F3 — Chat diario idéntico

- Composer/attachments/slash/modelo/reasoning, transcript y herramientas, selección,
  búsqueda/exportación, tabs/ventanas, sesiones y Bot Chat con lineage canónico.
- Receipts/identidad durable de submit, unknown-outcome, queue autoritativa,
  clarifications y aprobaciones correlacionadas; Stop por dueño/generación exactos.
- Preservar backgrounds sin robar foco ni replay. No dar batch parcial por seguro
  cuando su recuperación aún no está establecida.
- Salida: generar→aprobar→Stop→relaunch→restaurar→envío deliberado con readback.

### F4 — Working context y administración

- Preview/browser, artifacts, files, terminal/review con persistencia al ocultar;
  primero revisar autoridad de cada integración nativa, nunca exponer shell bridge.
- Providers/modelos/Persona/Projects/Skills/MCP/memoria/cron/messaging/webhooks/
  cuentas con revisión/concurrencia y grants exactos. Contrato ausente bloquea esa
  operación, no todo el port.

### F5 — Contribuciones oficiales y funciones avanzadas

- Concretar Radio, Vault, paquetes, Screen, Pets, Starmap, guía y Kanban desde
  módulos oficiales. Reproducir UX Flutter, no cargar plugins Electron arbitrarios.
- Importación extranjera y OAuth/Cloud no son credenciales intercambiables.
- Cada contribución obtiene slice de contrato, UI/estado y prueba integrada.

### F6 — Voz, accesibilidad, rendimiento y entrega

- Dictado y conversación Live con interrupciones/re-arm, stop/dispose, permisos,
  locale, fallos, texto equivalente; validar acústica en teléfono físico.
- IME/Back/TalkBack, teclado/foco, contraste/reduced motion, escenas largas,
  suspensión/proceso muerto, varios perfiles/dispositivos sin mezcla de estado.
- Instalar/upgrade/rollback/desinstalar solo cliente, retención de keyring y datos,
  artefacto/certificado identificados. Mac/Windows no se califican desde Linux.
- Unir las lanes LINUXQA existentes y registros Android; no sumar fixtures como
  aceptación live ni borrar failures/retries para publicar un veredicto.

## Contrato de cada actividad de implementación

Cada slice debe tener source pin y paths oficiales; control visible y acción;
entrada→estado pendiente→commit Agent→readback→presentación; identidad/owner;
cancelación y resultado incierto; alcance de archivos; pruebas positivas/negativas;
dependencias y operación ausente; plataforma real y evidencia. Reusar task existente
cuando cubra todo ese resultado. Un task de estudio done no es implementación.

Checks comunes según alcance (propuestos, no ejecutados por este plan):
`dart format --output=none --set-exit-if-changed` sobre cambios, `flutter analyze`,
`flutter test --concurrency=1`; UI web: `flutter build web --release -t lib/main_e2e.dart`
antes de `npm run web:e2e`; `npm audit` cuando corresponda y `git diff --check`.
Toolchain documentado Flutter 3.44.2/Node 22: resolver compatibilidad explícitamente,
no cambiar lockfiles silenciosamente; las pruebas recientes usaron Flutter 3.44.9.

## Criterio de cierre del clon

Ninguna familia o control queda implícitamente completo. Deben existir: equivalencia
visual revisada en escenas comparables, mismas interacciones/atajos/estados y
recuperación, operación Agent verificada o divergencia explícita bloqueada,
regresión automatizada, y pruebas native/live del resultado cuando se reclame.
No se calcula porcentaje de paridad de conteos de documentos/tests. Si queda una
función oficial bloqueada, el producto no se declara clon completo.

## Cobertura completa de familias (actividad por familia)

Estas 50 familias provienen del inventario existente. Los paths siguientes son
leads históricos y se comprueban contra el nuevo pin antes del slice; no son nuevas
certificaciones ni garantía de que el archivo siga igual. La revisión actual de
fuente complementa esta cobertura sin sobrescribir snapshots anteriores.

### 1. HD-ENTRY — First-run connection choice and failure recovery

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/desktop-install-overlay.tsx`.
- Reusar tareas: `CONNECTION-OFFICIAL-DESKTOP-PORT`, `CONNECTION-SETUP-AUTH-MATRIX-LIVE`, `CONNECTION-LINK-RETIREMENT`, `ANDROID-CHAT-TOUCH-POLISH`.
- Brecha histórica a reconciliar: Install-versus-existing-runtime decision and managed bootstrap are not implemented equivalents; Linux discovery remains metadata-only and Android preparation manual. New canonical gateway attachment must not be inferred from unchanged overlay source.

### 2. HD-LOCAL — Local runtime discovery, bootstrap and launch

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/electron/local-gateway.ts`, `apps/desktop/electron/main.ts`, `apps/desktop/src/AGENTS.md`.
- Reusar tareas: `CONNECTION-SETUP-AUTH-MATRIX-LIVE`, `DOC-NATIVE-FAILURE-BOUNDARY`.
- Brecha histórica a reconciliar: Canonical attachment remains unimplemented: source trace resolves private identify/session-ticket, interactive WS and native HTTP grants, but Wing uses a different dashboard-ticket caller. Future native attach must exclude ensure/start/restart, lock repair and per-profile serve fallback; managed installation remains absent.

### 3. HD-REMOTE — Explicit remote URL/token connection test

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/remote-setup/use-remote-connection-test.ts`.
- Reusar tareas: `CONNECTION-REMOTE-AUTH-EXPLANATION`, `CONNECTION-REMOTE-AUTH-STORAGE-RETRY`, `CONNECTION-SETUP-AUTH-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Desktop native probe/test bridge equivalence, HTTP plus actual WS leg, custom header fidelity and OAuth are not established by the token path. Auth, connection, persistence and generation remain distinct outcomes.

### 4. HD-OAUTH — Remote OAuth sign-in/out and draft identity

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/remote-setup/use-remote-oauth.ts`.
- Reusar tareas: `CONNECTION-REMOTE-AUTH-EXPLANATION`, `CONNECTION-SETUP-AUTH-MATRIX-LIVE`, `DOC-ACCOUNT-REVOCATION-EVIDENCE`.
- Brecha histórica a reconciliar: Contract trace: docs/quality/remote-dashboard-oauth-contract.md. Agent dashboard cookie/native PKCE and per-dial ticket operations are source-resolved, not implemented or qualified in Wing. Cookie drafts can be connection-specific, but native tokens/logout are URL-keyed; editor fences do not prove acquisition cancellation or remote revocation. Secure-storage-only custody, exact-target logout and platform browser return remain design gaps. Provider-account OAuth and Cloud discovery/cascade are distinct.

### 5. HD-SSH — SSH connection configuration and trust

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/gateway-settings.tsx`.
- Reusar tareas: `BACKEND-SSH-CONNECT`, `BACKEND-SSH-KEY-AUTH`, `BACKEND-SSH-CONNECT-LIVE`, `BACKEND-SSH-KEY-NATIVE-LIVE`, `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Native target host trust/auth, actual document acquisition/secure key storage and live Agent session compatibility remain unqualified. Desktop remote startup/CLI paths cannot be copied as lifecycle authority; remote failure must never start local Agent.

### 6. HD-HOSTS — Saved connections and source switching

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/store/connections.ts`.
- Reusar tareas: `CONNECTION-SAVED-HOST-OWNER-SAFETY`, `CONNECTION-TWO-HOST-RECOVERY`, `CONNECTION-SAVED-WORKFLOWS-LIVE`, `CONNECTION-OWNER-RECONNECT-LIVE`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Source trace resolves profile-bound versus explicit host-scoped grants and control-home versus session-home ownership. Wing has no canonical owner/home binding or shared multiplexed attachment; source defaults and multiple active sockets remain broader than its single active connection. Remote failure must never start a local owner.

### 7. HD-SHELL — Chat home, workspace destinations and overlays

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/routes.ts`, `apps/desktop/src/app/contrib/surfaces.tsx`, `apps/desktop/src/app/contrib/controller.tsx`.
- Reusar tareas: `WING-TASK-408`, `WING-TASK-408-LIVE`, `DOC-PARITY-TAB-CONTRACT`, `ANDROID-CHAT-TOUCH-POLISH`, `VERIFY-SHELL-NATIVE-INPUT`.
- Brecha histórica a reconciliar: No import/Command Center/Artifacts/Messaging/Webhooks/Starmap equivalents are composed. Contribution-driven workspace panes and persistent tree lifetime are not matched by navigation imports or existing loaded-session modal.

### 8. HD-TABS — Concurrent panes, session/window ownership and close

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-message-stream/gateway-event/server-requests.ts`.
- Reusar tareas: `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`, `ANDROID-CANONICAL-BOT-CHAT`, `ANDROID-CHAT-TOUCH-POLISH`.
- Brecha histórica a reconciliar: No owner-safe concurrent pane tree/tab close model is shipped in inspected canonical composition. Need per-tab owner/run/draft focus, close/Stop uncertainty and reconnect; native-serve exclusions in existing candidate remain unavailable outcomes, not Android acceptance.

### 9. HD-PROFILE — Profiles, Agents and scoped persona configuration

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/profiles/index.tsx`.
- Reusar tareas: `DOC-M3-CONTRACT-CHECKPOINT-LIVE`, `DOC-M3-ROLLBACK-EVIDENCE-LIVE`, `VERIFY-PERSONA-LIVE-COMPATIBILITY`, `DOC-PARITY-TAB-CONTRACT`, `ANDROID-CHAT-TOUCH-POLISH`.
- Brecha histórica a reconciliar: All advertised runtime lifecycle/default/new-window and Agents outcomes are not established. Profile creation and rollback depend on exact suitable Agent contracts, not successful source lookup; no global profile-use side effects.

### 10. HD-PROJECT — Projects, folders and worktrees

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/store/projects.ts`.
- Reusar tareas: `DOC-M3-PROJECT-CONTRACT`, `DOC-M3-PROJECT-ASSIGNMENT-CONTRACT`, `DOC-M3-PROJECT-CONTRACT-LIVE`, `DOC-M3-PROJECT-ASSIGNMENT-CONTRACT-LIVE`, `FILES-TERMINAL-BROWSE`.
- Brecha histórica a reconciliar: Project create/assign/folder/worktree authority, containment and per-session routing remain absent. Desktop native IDEA/git writes and use state cannot become Wing arbitrary paths or profile workdir. Require exact unmodified Agent operations/grants and opaque directory handles.

### 11. HD-PROVIDER — Provider accounts, keys, endpoints and local model setup

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/providers-settings.tsx`.
- Reusar tareas: `DOC-M3-PROVIDER-CONTRACT`, `DOC-M3-PROVIDER-CONTRACT-LIVE`, `DOC-M3-PROVIDER-REMOVAL-CONTRACT`, `DOC-M3-PROVIDER-REMOVAL-CONTRACT-LIVE`, `DOC-ACCOUNT-REVOCATION-EVIDENCE`.
- Brecha histórica a reconciliar: OAuth account pools, custom endpoints, local acquisition and selected-credential revision-safe replacement/removal are not equivalent to inventory/key-sheet availability. No actual provider or native secret-storage qualification.

### 12. HD-MODEL — Session models, defaults, reasoning and auxiliary configuration

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/model-settings.tsx`.
- Reusar tareas: `DOC-M3-PROVIDER-CONTRACT-LIVE`, `PARITY-PAIR-READ`, `CONNECTION-SETUP-AUTH-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Profile defaults, auxiliary/fallback/MoA configuration and context budgets remain distinct missing outcomes. Session-pair restoration still needs authoritative read; no inference or native qualification upgrade.

### 13. HD-CHAT — Deliberate send, streaming and transcript/tools

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-prompt-actions/submit.ts`.
- Reusar tareas: `WING-TASK-406`, `WING-TASK-407`, `PARITY-LIVE-WORKFLOW-LIVE`, `VERIFY-CHAT-TRANSCRIPT-NATIVE`, `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART`, `ANDROID-CHAT-TOUCH-POLISH`.
- Brecha histórica a reconciliar: Contract trace: docs/quality/canonical-pending-input-contract.md. Unmodified canonical stable admission/receipt contracts exist but Wing has no consumer; the canonical receipt has no send-time user_row_id (standalone serve differs). Preserve queued/started/terminal/unknown reconciliation, exact explicit retry versus changed send and authoritative Stop uncertainty; do not merely expand Wing's legacy status allowlist.

### 14. HD-APPROVAL — Correlated approvals and expired input

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/assistant-ui/tool/approval.tsx`.
- Reusar tareas: `PARITY-APPROVAL-DISMISSAL`, `M1-NATIVE-APPROVAL-RESTORATION`, `VERIFY-CHAT-TRANSCRIPT-NATIVE`, `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART`, `PARITY-LIVE-WORKFLOW-LIVE`, `DOC-PARITY-TAB-CONTRACT`.
- Brecha histórica a reconciliar: Broader Desktop choices/grants/expiration and replay fidelity remain transport-specific. New multiplexing cannot retarget responses through foreground profile; existing source safety is intentional, not evidence of deployed grants.

### 15. HD-STOP — Stop presentation and backend interruption

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-prompt-actions/index.ts`.
- Reusar tareas: `M1-NATIVE-STOP-RECOVERY`, `PARITY-LIVE-WORKFLOW-LIVE`, `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Preserve stronger uncertainty semantics. Desktop optimistic UI is not proof of Agent termination, REST cancellation is not session.interrupt, and tab switching must not make an unresolved run idle-close eligible.

### 16. HD-CLARIFY — Live clarification questions and locked answers

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/assistant-ui/clarify/pending.tsx`.
- Reusar tareas: `DOC-PARITY-TAB-CONTRACT`, `VERIFY-CHAT-TRANSCRIPT-NATIVE`.
- Brecha histórica a reconciliar: Contract trace: docs/quality/canonical-pending-input-contract.md. Generation-bound clarify.respond and opted-in local-viewer clarify.lock batches are distinct unmodified contracts, neither consumed by Wing. Sequential Confirm is not atomic; Skip/timeout retain partial locks. Canonical authoritative batch/lock reconnect projection is absent at this pin; Desktop fixtures/staging do not supply it. Preview qids and ordinary chat are not answers.

### 17. HD-QUEUE — Queued follow-ups and explicit drain ownership

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/store/composer-queue.ts`, `apps/desktop/src/app/chat/composer/discard-lost-prompt.ts`.
- Reusar tareas: `PARITY-DOC-QUEUE-INTENT`, `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Contract trace: docs/quality/canonical-pending-input-contract.md. Agent FIFO, cancel/resolve_unknown and row-advertised steer_queued/replace_queued are source-resolved, not implemented in Wing. Cancel's queued-read/claim race may hard-interrupt and return started; replacement atomically retires old input and appends a new identity at FIFO tail. Local queue controls/drain are not this contract; never replay cached writes on reconnect.

### 18. HD-DRAFT — Composer scope, attachments and rejected submission restore

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/chat/composer/hooks/use-composer-submit.ts`, `apps/desktop/src/app/session/hooks/use-prompt-actions/submit.ts`.
- Reusar tareas: `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Contract trace: docs/quality/canonical-pending-input-contract.md. Exact owner/principal/ID/payload retry versus a changed send is resolved in canonical source but absent from Wing's volatile draft/submission model. A restored draft is not a deduplicated retry; canonical send-time user-row correlation is not supplied by standalone evidence. Per-pane lifecycle remains with the tabs owner; no automatic replay or inferred disk persistence.

### 19. HD-SEARCH — Session inventory, search, management and Command Center

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/command-center/index.tsx`.
- Reusar tareas: `DOC-SESSION-SEARCH-RESUME-QUALIFICATION`, `PORT-GLOBAL-SESSION-MODAL`, `VERIFY-GLOBAL-SESSION-MODAL-NATIVE`, `PARITY-NATIVE-LINUX`.
- Brecha histórica a reconciliar: Command Center system/usage/maintenance is not implemented by session picker. Neither this Desktop range nor Wing loaded filtering proves server transcript search or Project grouping. Keep bounded loaded-search claim.

### 20. HD-RESUME — Exact identity restore, replay and reconnect

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-session-actions/index.ts`.
- Reusar tareas: `WING-TASK-407`, `CONNECTION-OWNER-RECONNECT-LIVE`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`, `VERIFY-LIVE-WORKFLOW-RECOVERY-LIVE`, `M2-DEVICE-QUALIFICATION`.
- Brecha histórica a reconciliar: Canonical resume/replay and viewer-only disconnect are source-traced, not qualified. Desktop maps activate to resume and strips lazy; Wing still sends lazy:true, which the canonical resume schema rejects. Missing authenticated home/instance binding and native ticket acquisition remain; no replacement conversation or automatic replay after ambiguous recovery.

### 21. HD-ATTACH — Composer attachments and upload ownership

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-prompt-actions/submit.ts`.
- Reusar tareas: `PARITY-MAESTRO-ANDROID-DEVICE-LIVE`, `ANDROID-CHAT-TOUCH-POLISH`, `DOC-PARITY-TAB-CONTRACT`.
- Brecha histórica a reconciliar: Desktop multiple host-side refs/types/retry synchronization are not equivalent to Wing staged text/image. Native-serve product send explicitly rejects all attachment input; do not advertise attachment parity for SSH native serve merely because picker exists.

### 22. HD-EXPORT — Transcript export and format boundaries

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/lib/session-export.ts`.
- Reusar tareas: `PARITY-DOC-EXPORT-FEEDBACK`, `DOC-M5-LARGE-TEXT-EVIDENCE-LIVE`, `PARITY-MAESTRO-ANDROID-DEVICE-LIVE`.
- Brecha histórica a reconciliar: Paged JSON is not a frozen snapshot: external same-length edits can evade checks. Linux GTK JSON save/overwrite/cancel/owner-switch and destination-byte readback, actual Agent projection and other platforms remain unqualified. HD-EXPORT runtime cells remain open; Android native save is unsupported.

### 23. HD-VOICE — Draft dictation, voice conversation and playback

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/chat/composer/hooks/use-voice-conversation.ts`.
- Reusar tareas: `DOC-VOICE-QUALIFICATION-LIVE`, `DOC-VOICE-OUTPUT-CANCEL-EVIDENCE`, `ANDROID-CHAT-TOUCH-POLISH`.
- Brecha histórica a reconciliar: Desktop acoustic/barge-in/stop/finalize behavior is not established by controls or fixtures; device microphone, permission, locale, re-arm and output cancel remain separately unqualified. Do not port upstream provider-key extraction into Wing.

### 24. HD-COMMAND — Curated slash discovery and dispatch

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session/hooks/use-prompt-actions/slash.ts`, `apps/desktop/src/AGENTS.md`.
- Reusar tareas: `DOC-SLASH-CATALOG-CONTRACT`, `DOC-SLASH-DENIAL-EVIDENCE`, `VERIFY-SLASH-AUTHORITATIVE-TRANSPORT`.
- Brecha histórica a reconciliar: No qualified commands.catalog/complete.slash/slash.exec/command.dispatch contract in Wing consumed transport. Desktop curation must preserve skill/quick extensions but source availability is not advertised callable authority.

### 25. HD-SKILLS — Capabilities: skills, learning and discovery

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/capabilities/skills/skills-tab.tsx`.
- Reusar tareas: `DOC-M4-CONTRACT-CHECKPOINT`, `DOC-M4-CONTRACT-CHECKPOINT-LIVE`, `DOC-M4-DISCOVERY-SELECTION-CONTRACT`, `DOC-M4-DISCOVERY-SELECTION-CONTRACT-LIVE`.
- Brecha histórica a reconciliar: Hub discovery/install/update/uninstall, editing, usage/learning and enable/cache semantics require exact Agent operations. Preserve separately deferred slash execution; completion invalidation is not execution proof.

### 26. HD-MCP — Capabilities: connectors, MCP and toolset configuration

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/capabilities/connectors/connectors-tab.tsx`, `apps/desktop/src/app/capabilities/index.tsx`.
- Reusar tareas: `DOC-M4-MCP-CONTRACT`, `DOC-M4-MCP-CONTRACT-LIVE`, `DOC-M4-MCP-CONFIG-CONTRACT`, `DOC-M4-MCP-CONFIG-CONTRACT-LIVE`.
- Brecha histórica a reconciliar: Connector directory, hosted accounts/authenticate/install and MCP configuration must be traced to exact authoritative operations. Desktop handlers do not grant Wing remote/native authority or a shell fallback.

### 27. HD-MEMORY — Memory, context engine and provider configuration

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/memory/provider-config-panel.tsx`.
- Reusar tareas: `DOC-M4-MEMORY-CONTRACT`, `DOC-M4-MEMORY-CONTRACT-LIVE`, `DOC-M4-MEMORY-CAPACITY-CONTRACT`, `DOC-M4-MEMORY-CAPACITY-CONTRACT-LIVE`.
- Brecha histórica a reconciliar: Memory-provider settings must not be misreported as memory-entry CRUD. Entry/capacity/context-engine and provider operations remain unverified and secret-safe exact contracts required.

### 28. HD-SCHEDULE — Cron routines, blueprints, delivery and run history

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/cron/index.tsx`.
- Reusar tareas: `DOC-M4-SCHEDULE-CONTRACT`, `DOC-M4-SCHEDULE-CONTRACT-LIVE`, `DOC-M4-SCHEDULE-DELIVERY-CONTRACT`, `DOC-M4-SCHEDULE-DELIVERY-CONTRACT-LIVE`, `VERIFY-M4-LIVE-INVENTORY`.
- Brecha histórica a reconciliar: Create/edit/pause/resume/trigger/delete, blueprints, delivery and run history remain separate gated work. Do not infer trigger execution from optimistic pending row or confuse persisted update with refresh failure.

### 29. HD-KANBAN — Optional contributed Kanban planning

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/plugins/kanban/plugin.tsx`.
- Reusar tareas: `DOC-M4-KANBAN-CONTRACT`, `DOC-M4-KANBAN-CONTRACT-LIVE`, `DOC-M4-KANBAN-PAGINATION-EVIDENCE`, `DOC-M4-KANBAN-PAGINATION-EVIDENCE-LIVE`.
- Brecha histórica a reconciliar: Board pagination/identity, Project scope, dispatcher/write semantics and accessible non-drag actions remain unsupported. No duplicate board contract task or local shadow inventory.

### 30. HD-GATEWAY — Messaging, gateway setup, pairing and Webhooks

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/messaging/index.tsx`.
- Reusar tareas: `DOC-M4-PLATFORM-CONTRACT`, `DOC-M4-PLATFORM-CONTRACT-LIVE`, `DOC-M4-HOST-LIFECYCLE-EVIDENCE`, `DOC-M4-HOST-LIFECYCLE-EVIDENCE-LIVE`.
- Brecha histórica a reconciliar: Messaging pairing/revocation, Webhooks secrets and gateway/platform lifecycle remain absent. Official messaging pairing is not retired Wing Link. Hot-served distinction is persistence-versus-activation, not general restart permission.

### 31. HD-ARTIFACTS — Artifacts destination across session outputs

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/artifacts/index.tsx`.
- Reusar tareas: `DOC-ARTIFACT-CONTRACT`, `DOC-ARTIFACT-CONTRACT-LIVE`, `DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE`, `DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE-LIVE`, `FILES-TERMINAL-DOWNLOAD`.
- Brecha histórica a reconciliar: Exact retrieval/download authority, safe byte storage and inert preview remain missing; session transcript pagination is not unrestricted host file permission.

### 32. HD-PREVIEW — Preview/browser, files and working panes

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/chat/right-rail/preview-pane.tsx`.
- Reusar tareas: `FILES-TERMINAL-BROWSE`, `FILES-TERMINAL-DOWNLOAD`, `DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE-LIVE`.
- Brecha histórica a reconciliar: FILES-TERMINAL-BROWSE and DOWNLOAD already own effective terminal.cwd/root containment and native save. Keep their contract-unready/deferred gates; no SFTP, arbitrary paths or remote native-IPC inference. Browser isolation and remote-loopback resolution need separate trace.

### 33. HD-TERMINAL — Persistent terminal and native git review

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/right-sidebar/terminal/use-terminal-session.ts`.
- Reusar tareas: `DOC-NATIVE-DESIGN-REVIEW`, `DOC-NATIVE-FAILURE-BOUNDARY`, `DOC-NATIVE-DESIGN-REVIEW-LIVE`.
- Brecha histórica a reconciliar: Persistent terminal, process identity/lifetime, git staging/commit/push and remote topology remain unsupported. Reuse bounded-native design/failure gates; Files tasks cover browsing/download only, not PTY or publication.

### 34. HD-BOTS — Canonical Bot Chat and bot roster

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/plugins/hermes-bots/canonical-chat.ts`.
- Reusar tareas: `ANDROID-CANONICAL-BOT-CHAT`, `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT`.
- Brecha histórica a reconciliar: Canonical hidden-title lookup, compression lineage, adopt-before-create concurrency and roster preview/click identity remain unimplemented. New Bot Screen is a distinct product outcome, not ordinary canonical chat acceptance.

### 35. HD-CLOUD — Hermes Cloud connection topology

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/connections-registry.tsx`.
- Reusar tareas: `DOC-ACCOUNT-CONTRACT`, `DOC-ACCOUNT-CONTRACT-LIVE`, `DOC-ACCOUNT-REVOCATION-EVIDENCE`.
- Brecha histórica a reconciliar: Cloud discovery/service authority, OAuth private handoff/cookie partition and cancellation remain missing. Account acquisition tasks offer adjacent security coverage, not Cloud positive support.

### 36. HD-ACCOUNT — Nous free-tier status, sign-in and billing

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/store/free-tier.ts`.
- Reusar tareas: `DOC-ACCOUNT-CONTRACT`, `DOC-ACCOUNT-CONTRACT-LIVE`, `DOC-ACCOUNT-REVOCATION-EVIDENCE`.
- Brecha histórica a reconciliar: Status, notice acknowledgement/provisioning, challenge/sign-in and billing must remain distinct from Cloud topology, provider OAuth and money movement. Exact authority/effects and scope fencing need their own contract.

### 37. HD-SETTINGS — Settings navigation, schema fields and presentation

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/settings-manifest.ts`, `apps/desktop/src/app/settings/index.tsx`.
- Reusar tareas: `DOC-NATIVE-FAILURE-BOUNDARY`, `VERIFY-SHELL-NATIVE-INPUT`, `PARITY-NATIVE-LINUX`.
- Brecha histórica a reconciliar: Full schema configuration/search/deep links, save/reload/restart and platform preferences remain gaps. Native bridge availability stays operation-specific. Vault and plugin-package outcomes deserve explicit subgroup inventory, not blanket Settings support.

### 38. HD-DIAG — Diagnostics, logs and recovery

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/gateway-settings.tsx`.
- Reusar tareas: `DOC-DIAGNOSTICS-CONTRACT`, `DOC-DIAGNOSTICS-BACKUP-CONTRACT`, `VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY`.
- Brecha histórica a reconciliar: Native log reveal/export and authoritative atomic backup/import/recovery are not established. Keep existing blocked atomic recovery contract and do not infer repair from a searchable row.

### 39. HD-UPDATE — Artifact-owned install/update and uninstall

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/managed-updates-section.tsx`.
- Reusar tareas: `VERIFY-DESKTOP-NATIVE-DELIVERY`, `VERIFY-M6-ANDROID-INTEGRATED`, `DOC-DESKTOP-DELIVERY-EVIDENCE`.
- Brecha histórica a reconciliar: Native update engine/rollback/recovery and same-artifact signed install/uninstall qualification remain pending. UI receipt display alone is not update success; canonical gateway migration does not grant Wing lifecycle permission.

### 40. HD-NATIVE — Window, keyboard, HUD, tray and native integration

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/settings-manifest.ts`.
- Reusar tareas: `DOC-NATIVE-DESIGN-REVIEW`, `DOC-NATIVE-FAILURE-BOUNDARY`, `DOC-NATIVE-DESIGN-REVIEW-LIVE`, `VERIFY-SHELL-NATIVE-INPUT`, `M1-NOTIFICATION-CONTRACT-LIVE`.
- Brecha histórica a reconciliar: HUD/tray/quick-entry/zoom/screenshots/notifications/pane/window semantics require separately bounded platform traces and runtime evidence; no blanket Electron bridge parity.

### 41. HD-ACCESS — Accessible keyboard/focus/motion equivalents

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/hooks/use-keybinds.ts`.
- Reusar tareas: `VERIFY-SHELL-NATIVE-INPUT`, `DOC-M5-LARGE-TEXT-EVIDENCE-LIVE`, `PARITY-NATIVE-LINUX`, `PARITY-MAESTRO-ANDROID-DEVICE-LIVE`.
- Brecha histórica a reconciliar: No named-target screen-reader/physical IME/full focus ownership qualification. Equivalent text/keyboard paths and reduced-motion behavior must be verified for every added spatial/media/native outcome.

### 42. HD-IMPORT — Session import overlay

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/session-import/index.tsx`.
- Reusar tareas: `VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY`, `DOC-DIAGNOSTICS-BACKUP-CONTRACT`.
- Brecha histórica a reconciliar: Contract trace resolves Agent-host foreign list/preview/import and transactional provenance dedupe, not preview-content immutability or redaction. Wing has no consumer or qualified admission/readback; close suppresses navigation, not import commit. Backup recovery and local history seeding are not equivalents.

### 43. HD-STARMAP — Starmap learning/history visualization

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/starmap/index.tsx`.
- Reusar tareas: `PARITY-NATIVE-LINUX`, `PARITY-OFFICIAL-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Graph source/owner identity, timeline/share/playback and accessible non-canvas inspection remain unsupported; overlay composition alone cannot qualify them.

### 44. HD-GUIDE — Guided setup conversation and loading handoff

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/components/onboarding/first-run/kickoff.ts`, `apps/desktop/src/components/onboarding/first-run/kickoff.test.ts`.
- Reusar tareas: `CONNECTION-SETUP-AUTH-MATRIX-LIVE`, `DOC-M3-CONTRACT-CHECKPOINT`, `DOC-M3-CONTRACT-CHECKPOINT-LIVE`, `PARITY-OFFICIAL-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Map onboarding.start/session handoff, skip/failure/resume and free-tier effects before implementation. Never fabricate a greeting/progress, duplicate opening submit or seed local Agent history.

### 45. HD-PLUGINS — Bundled contributions and runtime plugin loading

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/contrib/plugins.ts`, `apps/desktop/src/contrib/settings-pages.ts`.
- Reusar tareas: `DOC-NATIVE-DESIGN-REVIEW`, `DOC-NATIVE-FAILURE-BOUNDARY`, `PARITY-OFFICIAL-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Do not invent a Flutter plugin ABI or port Electron disk execution. Distinguish bounded equivalent product outcomes, profile-owned Agent packages, client-local contributions and plugin settings. Hello Runtime is a demo fixture, not automatically a shipped bundled outcome.

### 46. HD-RADIO — Optional Radio station search, pinning and explicit playback

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/plugins/radio/plugin.js`, `apps/desktop/src/contrib/radio-plugin.test.ts`.
- Reusar tareas: `PARITY-OFFICIAL-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Contract trace identifies client-local default-disabled Radio, plugin-local pins and explicit external search/playback; no Agent operation/grant dependency. Wing has no player. Optional media/network consent, disposal/stale-event behavior, accessible text controls and named-platform audio remain separate work.

### 47. HD-VAULT — Agent credential vault sources, locked state and item management

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/settings/vault-settings.tsx`, `apps/desktop/src/app/settings/vault-settings.test.tsx`.
- Reusar tareas: `DOC-NATIVE-FAILURE-BOUNDARY`, `DOC-ACCOUNT-REVOCATION-EVIDENCE`.
- Brecha histórica a reconciliar: Contract trace resolves metadata-only vault sources/items, local add/remove and external source enable/lock/unlock, not revision-safe edits, durable add dedupe or unlock lifetime. Wing has no Vault consumer/qualified admission. Endpoint secure storage and provider revocation remain different assets/outcomes; secrets stay write-only.

### 48. HD-PLUGIN-PACKAGES — Catalog and Git plugin packages with separate Agent/Desktop halves and scoped settings

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/capabilities/plugins/plugins-tab.tsx`, `apps/desktop/src/contrib/settings-pages.ts`, `apps/desktop/src/contrib/settings-pages.test.ts`.
- Reusar tareas: `DOC-M4-MCP-CONFIG-CONTRACT`, `DOC-NATIVE-FAILURE-BOUNDARY`.
- Brecha histórica a reconciliar: Contract trace distinguishes profile-scoped plugins.manage actions/catalog lookup from Electron app-global probe/install/reconcile/remove and JS loading. No Wing package manager, atomic dual-half transaction or durable retry receipt is established. MCP configuration is not package lifecycle; no Flutter ABI or Git/shell fallback is admitted.

### 49. HD-SCREEN — Bot computer Screen observe/control with per-viewer lease and explicit clipboard

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/plugins/hermes-bots/plugin.tsx`, `apps/desktop/src/plugins/hermes-bots/screen-portal.tsx`, `apps/desktop/src/plugins/hermes-bots/screen-pane.tsx`, `apps/desktop/src/plugins/hermes-bots/screen-connection.ts`.
- Reusar tareas: `ANDROID-CANONICAL-BOT-CHAT`, `DOC-NATIVE-FAILURE-BOUNDARY`.
- Brecha histórica a reconciliar: Contract trace resolves display status/observe, transport-minted viewers, server input leases and clean-close versus dropped-link exclusion. Wing has no viewer; upstream ticket-in-URL delivery violates Wing custody rules, full RPC reconnect cannot reclaim an old viewer, and non-canvas access is unresolved. Bot Chat and lifecycle authority remain separate.

### 50. HD-PETS — Generate, hatch, preview, adopt or discard an Agent pet

- [ ] Comparar controles, visual y estados con Desktop oficial; implementar únicamente el delta confirmado.
- [ ] Probar resultado positivo, cancelación, denegación, reconexión y stale-owner; registrar plataforma/backend.
- Referencias a verificar: `apps/desktop/src/app/pet-generate/pet-generate-content.tsx`, `apps/desktop/src/store/pet-generate.ts`, `apps/desktop/src/app/settings/settings-manifest.ts`.
- Reusar tareas: `PARITY-OFFICIAL-MATRIX-LIVE`.
- Brecha histórica a reconciliar: Contract trace resolves pet generate/hatch/install versus select/adopt/remove and cooperative token cancellation, not universal profile/run fencing or durable reconnect/spend reconciliation. Wing has no pet flow; mascot assets do not qualify it. Exact admission, provider consent, accessible preview and named-platform execution remain gated; no image calls authorized.

## Delta actual corroborado y actividades de construcción

El caller actual se inspeccionó en el pin declarado, no solo en la matriz anterior.
La referencia es código, no una sesión Desktop ejecutada. Estas son actividades
propuestas por el planificador; IDs CLONE-* son claves de plan, no tasks admitidas.

| Clave / orden | Fuentes actuales Desktop (relativas a apps/desktop/) | Actividad y salida observable | Dependencias / owning Wing |
| --- | --- | --- | --- |
| CLONE-01 | DESIGN.md; src/styles.css; src/components/ui/ | Traducir tokens y primitives Flutter. Escenas luz/oscuro iguales; flat panels, hairlines, jerarquía, menús, loader/error, iconografía y controles accesibles. | Primero; lib/theme/, lib/shared/widgets/, test/theme/ |
| CLONE-02 | src/app/routes.ts; src/app/chat/sidebar/index.tsx; src/app/shell/ | Reproducir Chat home, Capabilities y Messaging como destinos, Artifacts/Cron según modo avanzado; overlays Settings/Profiles/Command Center/Agents/Starmap y contexto previo al cerrar. No links ficticios. | 01; lib/router/, lib/shared/widgets/app_shell* |
| CLONE-03 | src/app/settings/index.tsx; settings-manifest.ts; constants.ts; subpages.ts | Árbol Settings y búsqueda/deep links: padre abre primer hijo, caret solo expande, breadcrumb único, selector estrecho. Portar primero ajustes locales reales. | 01 para árbol/local; 02 para integración overlay final; lib/features/settings/ |
| CLONE-04 | src/components/desktop-install-overlay.tsx; src/components/remote-setup/; src/components/onboarding/ | Separar elegir local/existente, preparación, Test/Apply, provider setup y guía conversacional. Nunca simular instalación ni saludo/resume. | 01/02; lib/features/enrollment/, local_setup/ |
| CLONE-05 | src/app/settings/gateway-settings.tsx; connections-registry.tsx; src/components/remote-setup/use-remote-oauth.ts | Local/Cloud/Remote/SSH, prueba vs guardado/activación, primary/last-used, OAuth. Ticket fresco y owner exacto; viewer disconnect no para Agent. | Contratos exactos; lib/core/hermes/, features/gateway/ |
| CLONE-06 | src/app/settings/providers-settings.tsx; custom-endpoints-settings.tsx; local-models-settings.tsx; model-settings.tsx | Accounts/API keys/custom/local separados; main/fallback/auxiliary/delegation/MoA. UI y canal rechazan contrato insuficiente; conflicto/revisión/efectos no se inventan. | 03/05; features/providers/, core/hermes/policy/ |
| CLONE-07 | src/store/projects.ts; src/app/chat/sidebar/projects/; project-dialog.tsx | Home, proyecto multifolder, workspace/worktree lanes y acciones reales. Entrar no cambia sesión/cwd guardada; nueva sesión captura contexto explícito. | Calificar RPC y handles/concurrencia primero; Projects sigue gap |
| CLONE-08 | src/app/chat/composer/; src/components/assistant-ui/thread/; tool/ | Composer con @/slash/URL/path chips/pegado/adjuntos/modelo; transcript con edición/branch/rewind/reacciones/embeds/subagentes cuando contractualmente elegibles. | 01/05; features/hermes_chat/ |
| CLONE-09 | src/app/session/hooks/use-prompt-actions/; src/store/composer-queue.ts; clarify/; store/server-requests.ts | Admisión durable, receipt/unknown, FIFO editar/cancelar/steer y aclaraciones independientes de approvals. Verificar operación exacta y generaciones antes de habilitar. | Adopción canónica de 05; core/hermes/client/, channel/ |
| CLONE-10 | src/components/pane-shell/; src/store/route-tiles.ts; src/plugins/hermes-bots/ | Workspace multipane/tabs/peer windows, roster/grupos/Bot routines y side-chats; no confundir Bot Chat acotado existente con roster completo. Ocultar no destruye trabajo ni mueve foco. | Lifecycle/Stop 09; no reabrir lookup ya implementado |
| CLONE-11 | src/app/right-sidebar/{files,terminal,review}/; electron/{fs,terminal,git}-ipc.ts | Files/PTY/review por integración nativa revisada o contrato Agent suficiente. Files aún CONTRACT-UNREADY; no copiar IPC ni shell genérico. | 05/07/10; tareas Files existentes |
| CLONE-12 | src/app/artifacts/; src/store/artifacts.ts; src/app/chat/right-rail/; sandboxed-frame.tsx | Destino artifacts con versiones/registro y browser/preview aislado. Cero navegación externa automática; export de transcript no satisface preview. | 05/10; contratos de artifacts existentes |
| CLONE-13 | src/app/capabilities/{skills,toolsets,connectors,mcp,catalog}/; src/app/settings/memory/; src/app/cron/ | Capabilities, memoria/contexto, cron CRUD/delivery/history; separar jobs de runtime de cron; Kanban opcional apagado por defecto. | 05 y cada operación autorizada; no inventario como CRUD |
| CLONE-14 | src/plugins/hermes-bots/screen-*; src/app/settings/vault-settings.tsx; contrib/plugins.ts; app/pet-generate/ | Screen observe/control con lease, Vault/sources, paquetes Agent vs Desktop, Pets generar/hatch/adopt/discard. JS/React no compatible por sí solo con Flutter. | 05/10, contratos y equivalentes nativos; soporte sigue gap |
| CLONE-15 | src/plugins/radio/plugin.js; src/app/starmap/; src/app/session-import/ | Radio opcional off, sin autoplay, audio/red deliberados; Starmap e importación con UX oficial y procedencia. No requieren un loader universal. | Radio presentación independiente; importación contrato específico |
| CLONE-16 | DESIGN.md; app/settings/voice*; electron/ | Misma UX adaptable: OS IME/Back/TalkBack, short/narrow/200%, voice física, lifecycle, rendimiento largo, empaquetado/upgrade/client-only uninstall. | Prueba por slice + campaña Linux/Android existente |

### Árbol Settings que debe cubrirse

Model: main/fallback/auxiliary/delegation/MoA. Chat: behavior/attachments.
Appearance: general/theme/typography/window-layout/chat-display/pet.
Workspace: projects/shell/files. Safety: approvals/privacy/checkpoints.
Browser: profile/network. Memory & Context: persistent/context.
Voice: conversation/transcription/speech. Advanced: desktop/runtime/tools/terminal/output.
Además Providers, Gateway, Keybinds, Keys, Vault, Notifications, Billing, Sessions,
Plugins y About cuando correspondan a plataforma/capacidad. Su mera presencia en
un árbol no autoriza operaciones ni cuenta como funcionalidad implementada.

### Frontera inmediata decidida por el planificador

Primer lote de producto: CLONE-01 + la estructura y ajustes locales seguros de
CLONE-03. Reusar el master/detail actual, no montar otra shell/settings paralela.
Después CLONE-02/04, conexión canónica CLONE-05 y Chat CLONE-08/09/10. El orden
de QA no sustituye al port: LINUXQA excluye implementación de features nuevas.
El refuerzo contractual de proveedores precede toda habilitación real de CLONE-06.

Aceptación del primer lote: mismos grupos/orden/nombres y navegación Settings del
pin en escenas emparejadas; cancelar/cerrar retorna al contexto/foco/draft exactos;
ajustes locales persisten en su scope; subfunciones Agent ausentes tienen gap
explícito sin abrir formularios de secreto o rutas simuladas. Test positivo y
owner/cancel/denial; capturas fuente/Wing con mismo tamaño/tema/locale/escala.
Archivos: lib/theme/, lib/shared/widgets/, lib/features/settings/, lib/router/,
lib/l10n/app_en.arb y tests correspondientes. Generar l10n, analizar y probar UI;
no editar Agent ni abrir provider/inference por navegar Settings.

## Resoluciones del builder-check

### Nueva dirección visual y avatares locales autorizados

El propietario aprobó inspiración visual Muse/Duet y una excepción explícita
para avatares locales deterministas (ver ADR product). Chat usa burbujas de
20 px y compositor de 22 px, conservando funciones, claves y autorización.
Settings Appearance ofrece doce familias de criaturas aladas; la elección es
local a la instalación. Contacts dibuja cada criatura a partir de la identidad
exacta gateway/perfil con SHA-256 y JSON delimitado, sin red, imágenes externas,
escrituras Agent ni asignación de avatar al perfil. No es un generador por IA.
La cabecera conserva su layout para no recortar títulos estrechos.

Verificación Flutter 3.44.9 (fuera del pin documental): 146 pruebas de avatar,
Settings/composición/transcript y 144 de compositor/gateways; análisis limpio,
build web E2E. Chromium: 4 escenas Chat claro/oscuro móvil/escritorio, 2 de
paletas y 2 de selección/recarga de familias. Galería renderizada inspeccionada.
Esto es una primera implementación, no aprobación de marca ni paridad visual
con los productos de referencia. El botón antiguo de generación Agent en
Profiles permanece no disponible: no se simula esa API.

### Lote visual de Chat y navegación

Implementado: sidebar de 237 px según `styles.css --sidebar-width` del pin
oficial, sesiones con foreground/peso diferenciado por selección, cabecera de
52 px con separación de superficie y propietario secundario, esquinas compactas
de mensaje/compositor y prosa con interlineado 1.5. El ancho de lectura conserva
el contrato del pin (`--composer-width: 100%`, gutters 24/16), no un cap inventado.
El editor crece hasta seis líneas sin cambiar Send/Stop ni orden de teclado;
texto grande mantiene la cabecera de 104 px y controles de 48 px.
Se conserva el default, la autoridad Agent y la identidad de borrador/sesión.

Verificado con Flutter 3.44.9 (fuera del pin documental): 220 pruebas focalizadas
Chat/presentación, 179 de widgets compartidos, análisis y formato; build web E2E;
4 recorridos Chromium sin retries (390/1280, claro/oscuro), con borrador y Send
habilitado sin enviarlo. Capturas finales de móvil oscuro/escritorio claro
inspeccionadas; no hay comparación renderizada 1:1 con Desktop. `npm audit`:
cero vulnerabilidades. La suite ampliada fue interrumpida por timeout y no cuenta
como aprobada; dos casos de confirmación por Back también fallan en main previo
(`hermes_chat_gateway_confirmation_owner_test`, 390/1280). Quedan como defecto
previo, no se suprimen ni se califican verdes. El test de menú contextual usa
ahora un punto dentro del texto visible, no el centro vacío de una fila ancha.

### Primer cambio implementado de CLONE-03

Refinamiento visual: Appearance agrupa modo y galería bajo Theme y separa
Typography después de la galería, conforme al orden de secciones del pin oficial.
En móvil el control de modo usa una fila cuando cabe y las miniaturas son más
bajas; texto grande mantiene distribución vertical y área mínima de 48 px.
Verificación con Flutter 3.44.9: 48 pruebas Settings/router, análisis, formato,
build web E2E y 2 recorridos Chromium sin retries a 390/1280 px. Capturas
inspeccionadas durante el refinamiento; no equivalen a comparación 1:1 Desktop.
El árbol completo de subpáginas sigue pendiente.

Tamaño de conversación: Appearance expone la preferencia de escala de transcript
ya existente, antes accesible por pinch. Reutiliza el provider y clave actuales;
preserva el default Wing y los valores intermedios guardados. Los presets
90/100/110/125/150/175 siguen `appearance-settings.tsx:689-703` y
`store/chat-text-scale.ts` del pin oficial. No es escala global ni selector de
fuentes, y no completa el subárbol Typography. Dos regresiones a 390/1280 px con
texto 200% verifican selección, persistencia y recarga sin alterar el modo de tema.
Pasaron 48 pruebas Settings/router, análisis, formato y build Linux debug con
Flutter 3.44.9 (fuera del pin documental 3.44.2). No se ejecutó E2E web ni se
declara comparación visual Desktop o calificación física por ese build.

Galería visual de Appearance: el selector de paleta es ahora una cuadrícula de
miniaturas seleccionables, siguiendo el patrón `ThemeGallery` de
`apps/desktop/src/app/settings/appearance-settings.tsx` del pin `47b23fa048`.
Se conservan las cinco paletas Wing y sus claves/defaults existentes; no se
presentan como el catálogo completo de temas Desktop. La selección tiene nombre,
estado semántico y check visible. La cuadrícula adapta columnas al ancho del panel
y texto grande; las miniaturas decorativas no entran en el árbol accesible.

Verificación local: 46 pruebas Settings/router; análisis sin issues; formato de
los tres Dart modificados y `git diff --check`; build web E2E release. Chromium:
2 casos a 390/1280 px verifican selección, recarga persistida y desplazamiento a
la última paleta sin errores de render. Se inspeccionaron ambas capturas. Un
intento de teclado mediante foco DOM no activó el control; no se declara
calificación de teclado nativo. La prueba final usa click semántico. No se ejecutó
la suite E2E completa ni comparación renderizada con Desktop.
Se usó Flutter 3.44.9 instalado: evidencia fuera del pin 3.44.2 de CONTRIBUTING,
cuyo SDK no está disponible localmente. No equivale a aceptación con ese pin.

Seguimiento: `/settings?tab=voice|appearance|chat|connections` abre la categoría
local correspondiente; también se admiten los IDs oficiales `config:voice`,
`config:appearance`, `config:chat` y `gateway`. La selección manual actualiza
la URL con replace (sin apilar una ruta por categoría) y preserva otros parámetros.
Los aliases cortos existentes siguen admitidos para no romper enlaces guardados.
Pasaron las mismas 46 pruebas Settings/router y análisis tras esta extensión.

Un cambio de intent sobre la misma pantalla actualiza
contenido y selector; valores desconocidos o Chat sin spellcheck caen a Appearance
sin categoría vacía. Se conserva la navegación manual y no hay llamadas Agent al
abrir el deep link. Pasaron 46 pruebas Settings/router y análisis con Flutter
3.44.9. Esto no implementa búsqueda global, todo el árbol ni deep links de campos.

Voice tiene categoría propia en Settings, separada de Chat como en el árbol
oficial. Reutiliza la pantalla y preferencias de voz existentes; Chat conserva
spellcheck solo donde el sistema lo soporta y no ofrece una categoría vacía en
plataformas sin ese control. El selector compacto y navegación por teclado usan
la misma lista; no se cambian claves, defaults, credenciales ni operaciones Agent.
Flutter 3.44.9: 45 pruebas de Settings/router pasaron y análisis sin issues.
Es un subconjunto de estructura, no cierre de CLONE-03 ni fidelidad visual:
tokens, subárbol completo, deep links/búsqueda y comparación renderizada siguen
pendientes. No se ejecutó baseline visual Desktop ni prueba física de voz.

Las decisiones siguientes son del planificador; cierran ambigüedades sin afirmar
aprobación visual ni ejecución.

### Primer lote cerrado: CLONE-01 y parte local de CLONE-03

Incluido: primitivas visuales compartidas y su aplicación a Settings; estructura
Appearance/Chat/Voice con nombres y ubicación correspondientes al pin; únicamente
preferencias ya existentes de Wing: modo claro/oscuro/sistema, paleta, opciones
existentes de presentación de Chat, spellcheck cuando esté soportado, dictado/TTS
ya configurables y diagnósticos redactados. Leer sus providers/controles actuales
antes de migrar, conservar claves/valores y semántica; no cambiar defaults ni borrar
preferencias guardadas para aparentar fidelidad. Preferencias de presentación siguen
su scope actual de instalación; modelo/proveedor/perfil continúan siendo Agent-owned.

Diferido: idioma nuevo, UI Scale global, nuevos selectores de fuentes/densidad/tips/
embeds y cualquier control ausente, tray/glass, billing, cambios de modelos/proveedores,
configuración runtime y llamadas Agent. El árbol futuro se documenta; no llenar
Settings de controles ficticios para simular cobertura.

Durante este lote se conserva router/overlay existente y se verifica su cancelación,
retorno y preservación actuales. No se exige todavía la shell final ni una command
palette nueva. Búsqueda global de Settings y clasificación completa página/overlay
son CLONE-02 + cierre de CLONE-03. Por tanto, «misma navegación» en la aceptación
inmediata significa solo categorías/controles incluidos; retorno/foco/draft se prueba
sobre el mecanismo actual. La aceptación final 1:1 sigue pendiente hasta CLONE-02.

### Baseline visual reproducible

El código oficial fijado es la autoridad de intención; la comparación visual
requiere otra evidencia. Antes de cerrar CLONE-01: usar un checkout/export privado
inmutable del mismo pin, dependencias bloqueadas y entrypoint/fixture Desktop ya
existente y documentado, sin modificar la referencia ni conectar cuentas personales.
Registrar source/build/target y escenas sintéticas iguales en Desktop y Wing:
Settings Appearance, Chat y Voice; luz/oscuro; 1280×900 y estrecho 390×844; escala
100/200%; locale inglés y motion reducido. En el estrecho Desktop es referencia de
jerarquía, no prueba de soporte Android. La entrada Android/IME se prueba aparte.

Si el entrypoint oficial no permite una escena sin datos privados o faltan dependencias,
no crear respuestas Agent ficticias ni adaptar upstream: baseline visual NOT_CHECKED.
Puede entregarse traducción de tokens con tests, pero el lote queda visualmente sin
calificar. Revisión pareada por composición, texto, estados, tamaños y foco contra
capturas del mismo pin; cero discrepancias estructurales inexplicadas en el alcance.
Un porcentaje de píxeles no sustituye revisión; diferencias Flutter/font rasterization
se anotan sin convertirlas en paridad automática.

### Delta Bot Chat reconciliado

La descripción de HD-BOTS arriba es una brecha del snapshot histórico, no una orden
actual. Lookup por título exacto oculto, resolución de lineage, adopción de conflicto
y staging con historia ya están implementados en Wing. No reimplementarlos. Restan
roster y presentación Bots/grupos/routines/side-chats de CLONE-10, multipane lifecycle
y calificación real de autenticación/SSH/concurrencia/proceso muerto. Conservar
ANDROID-CANONICAL-BOT-CHAT-LIVE y sus tres casos Android ya aprobados.

### Dueños de resultados antes implícitos

CLONE-13 incluye expresamente Messaging/Webhooks (HD-GATEWAY): inventario,
configuración, pairing y recuperación solo con contratos admitidos, usando las
familias DOC-M4-PLATFORM-CONTRACT-LIVE y DOC-M4-HOST-LIFECYCLE-EVIDENCE-LIVE
sin asumir que un estudio terminado implementa el producto.
CLONE-06 incluye HD-ACCOUNT: free-tier status, sign-in y Billing con estado
Agent/Portal autorizado y UI oficial; usar DOC-ACCOUNT-CONTRACT-LIVE y
DOC-ACCOUNT-REVOCATION-EVIDENCE-LIVE. No efectuar compras, pagos, sign-out o
revocación para verificar presentación. Cloud/OAuth de conexión sigue CLONE-05.

## Backlog connection

Disposición: **Proposal** en la [cobertura plan→tarea](README.md#plan-to-task-coverage).
El mandato de producto no admite por sí solo tareas nuevas: CLONE-* sigue siendo
clave de plan, no tarea ejecutable. Los dueños existentes citados arriba conservan
su alcance, estado y gates; este enlace no los reabre ni amplía.

[MAIN-REPAIR-001](../../tasks/items/MAIN-REPAIR-001.md) enlaza este plan como fuente
para reparar su trazabilidad y los fallos offline registrados. No es dueño de
implementar el clon ni un recibo de admisión, paridad o calificación native/live.
`tasks/` sigue siendo la única cola; el coordinador conserva la admisión pendiente
para el trabajo nuevo de este plan.

## Handoff y limitación del gestor de tareas

`tasks/` sigue siendo la autoridad. La lista completa vigente es
[pendientes consolidados](../tasks/pending-complete.md). No recrear TODO.md ni
goals.json. En esta sesión el ejecutable `autowork tasks --help` devuelve
subcomando inexistente (exit 2); no se fabrican transiciones ni se modifica el
runtime para eludirlo. Las actividades de implementación faltantes se conservan
en este plan con IDs HD y paquetes F0–F6, pendientes de registro mediante la CLI
soportada. Esto es plan guardado, no cola admitida ni ejecución iniciada.
