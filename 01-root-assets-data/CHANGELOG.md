## 2026-10-07 — M5 / release preparation
- F1 presentation-only FPS/frame-time/texture overlay, including pause; no serialized state changes.
- Opt-in runtime graphics check with denied persistence and blocked input; imported artwork validation and four short performance cases.
- Release builder includes runtime PNGs, excludes development tools/tests, stages the archive, preserves existing releases and quotes custom launcher filenames.
- README corrected for imported art, disabled wallet/utang and source/release launch behavior.

# Latest 2026-10-07 M3 verification

Added deterministic six-day App scenario and --m3-check fresh-process driver in isolated saves. Tests verify all profiles/exact180s/queuedpause/full-state resume/dailycash/autosaveonce.25suites0failed; native Day6 cash112200/fullstate identical. Fixed preparation header overlap; no backend changes. Evidence docs/screenshots/m1fix/m3-day-flow-20261007/REPORT.md. Release/performance/humanplay gates remain.

# Latest - 2026-10-07 M2 cabinet/Sukli

Added cabinet geometry/query/input, six-section grid, prices/stock,400ms tooltip, quantity badges and click/hold/drag. Fixed fully reserved portion reopening. Added Sukli layout/query and receipt/fivebill/threecoin/tray view; actual-font fit prevents label wrapping. Economic commands/public names retained. Added cabinet/Sukli/full-sale regressions and rendered checks; smoke now2560x1440.24suites0failed, asset/navigation/protected checksPASS, independent findings fixed. Evidence/limits: docs/screenshots/m1fix/m2-cabinet-sukli/REPORT.md. M3/release/performance remain.

# Changelog

## 2026-10-05 — Task 1

Added the 36-product fictional catalog, six cabinet sections, units, measured/peso portions, day demand, customer/day/tuning data and optional product asset manifest. Added independent serializable run construction/cloning with FIFO batch records, integer money and morning snapshot. Added headless catalog/state tests plus a visible foundation boot and foundation-only smoke capture. Task 2 onward is not implemented; balance and full gameplay remain unverified. See docs/reviews/task-1-build.md for RED/GREEN evidence and limits.

Task 2: Added FIFO stock reservations/cost conservation, actual denomination validation, immutable retail quotes, staged tender, atomic/idempotent cash retail and cancellation, separate profit/cash-flow reports, reputation bounds and last-200 command gateway. Added tests/test_retail.lua and registered full suite. Wallet recovery excludes balances below conversion charge plus smallest payable denomination. Task 3 portions/credit and graphical transaction views remain subsequent tasks.
Task 2 review fix: atomically reject projected ledger/drawer safe-integer overflow and signed purchase cashflow underflow using centralized monetary validation; added normal-suite boundary regressions. Full headless suite remains 3 passed, 0 failed.

## 2026-10-05 — FAST MODE MVP domain batch
- Added measured portion target/adjust/confirm and preparation prepack with exact quote, actual FIFO consumption, cancellation spoilage, age/cost-preserving splits and duplicate guards.
- Added deterministic five-day customer/service lifecycle, capped ordinary endless rush, finite queue, global patience, pause, closing report, morning retry and new-run recovery command.
- Retail binds MVP sales to the active requested customer basket; purchase prioritizes MVP supplier data, daily financial activity resets on new day, dormant wallet cannot block MVP recovery.
- Added domain lifecycle tests; no UI, persistence or deferred wallet/debt service.

## 2026-10-06 — approved procedural restyle (in progress)

Reference: eleven user-supplied images under docs/reference and the supplied STYLE OVERHAUL. Original thin related-color drawing helpers, dusty palette, density-aware texture/product/character/font caches, maroon HUD/ticket, street/window/cropped counter, title storefront, six-section named cabinet, actual-piece drawer and rice/oil/sugar stations now replace the baseline art. Added wooden pause board and frontend placement-pop/silent injected sound hook. Save/load hooks still unconnected; no release-ready save claim. Existing domain/data/persistence files remain byte-identical to the restyle backup. No public functions renamed. New optional UI presentation arguments preserve existing callers.

Verification:8 headless suites passed,0failed. Stations smoke1791217177 produced80 captures acrossfour sizes, both actual input-check groups passed, exit0. Independent reviewer accepted cabinet/stations and all36-picture gallery. Fixed real cabinet cache loss, held-bottle label overlap and20-peso denomination picture. Raw PNG pixel inspection corrected a false font-clipping report; no font fix claimed. Full cast and preparation/report are the continuing stages.

## 2026-10-06 — frontend restyle accepted

Added final12-role/four-expression cast, original desk/paper preparation/report/recovery views, inactive notebook/phone/equipment art hooks, accurate unavailable-save styling and pressed/tooltip feedback. Product canvases now reuse product/window-density cache entries during placement animation. Added smoke-only global-key, letterbox, empty-cubby and real-input checks; no existing economic test expectation changed. Public APIs retained.

Root final tests:8suites passed,0failed. Final smoke1791218432:92captures, both UI CHECK groups and GLOBAL CHECK passed, exit0. Independent read-only reviewer accepted representative screens/source.18backend/data/persistence files and command gateway match the backup. Save/load integration/schema repair and release packaging remain pending; see docs/reviews/restyle-verification.md for exact evidence/limits and docs/reviews/mvp-save-review.md for the reproduced save defect.

## 2026-10-06 — persistence and local delivery

Fixed malformed profile and unsupported run-mode checkpoints after observed failing regressions. Connected default persistence to App with safe Save/Load, recovery warning and transient cleanup; autosave once on report, save before Next morning with failure blocking. Added real-store App regression suite and fresh-process native checkpoint verification. Smoke uses isolated memory storage and verifies actual Save/Menu/Load hitboxes without touching player saves. Source and .love build10suites passed; both92capture runs and UI/global checks passed. Separate read-only reviewer accepted persistence scope and reran native backup recovery. Created local launcher and source-only .love package; LÖVE11.5 must already be installed. No public API renamed; optional constructor parameters preserve previous calls. Full human playthrough, sound/FPS/power-loss and external lint remain unverified.

Clean Windows handoff ZIP created: dist/Tindahan_Windows_MVP.zip (90006bytes). Final .love81entries/93117bytes; unused review probes/build scripts excluded, original generated builds preserved. Clean extracted-copy launcher ran10passing suites, exit0. Runtime code matches the earlier packaged smoke-tested code; diagnostics/player files are excluded from the handoff ZIP. See save-integration-20261006.md for verification.

## 2026-10-07 M1 and approved M2 discard foundation

M1 complete within accepted fallback policy:33 normalized portrait/foreground PNGs, explicit fallback validation, five computed counter props, customer order interaction, data navigation/keys/locks, pause/settings/summary/quit and loading.14suite/112capture evidence in docs/reviews/master-m1-verification.md. Removed unused visual helpers Props.register/cat/jar (menu caller updated) and Shapes.jar (no callers). No public economic API renamed; source launcher runs current source, release package remains old.

M2 partial: new Portions.discard(state,id,reservationRef), discardPortion gateway and regression suite.15suites pass. Discard preserves other basket lines/customer, consumes opened actual quantity as FIFO spoilage, releases reservation, rejects stale/confirmed/tender references, and publishes nothing on overflow/stock failure. Separate review accepted extension. Four-bin UI and tolerance decision pending; no M2 completion claim.

## 2026-10-07 - M2 Timbangan slice

Added data-driven four-bin weigh/repack window, catalog bag tray, safe portion-only bin switch dialog, direct sack/pan/scoop interactions, open-order marker and correct return flow. Service UI Confirm uses approved0..5g overfill range; preparation retains FIFO cost/expiry. Large orders show repeated catalog bags without changing prices/quantities. Added validated optional --smoke-scenes for focused verification.22suites pass; final48focused captures plus prior172full smoke; independent findings fixed. Cabinet and Sukli overhaul pending; wallet transactions still disabled. Evidence: docs/screenshots/m1fix/m2-timbangan/REPORT.md.
