> Historical report: the 9 October 2026 GitHub preparation excludes old backup archives and generated captures from the source-upload ZIP. Links and commands for those local artifacts below are historical records, and their targets are not included in the ZIP. Proposed permanent deletion is pending confirmation. See [GitHub preparation](../GITHUB.md).

# Presentation readiness verification — 8 October 2026

Subsequent authorized cleanup: obsolete releases, verification slots and historical backup folders were removed from the working tree after recovery archival. Statements below about their preservation describe the earlier verification run. See [cleanup results](../cleanup-20261008/REPORT.md). Final test logs and inspected screenshots remain available.

OBSERVED: the parent game at `C:\04 Programming Language Lua` passes the checks below. The fresh presentation release is `dist/presentation-20261008/Tindahan.love`; run it with that folder's `Play Tindahan.bat`. A clean distributable is `dist/Tindahan_Presentation_20261008.zip`. The historical nested skeleton and older releases were preserved.

## Fixes and boundaries

- Disabled controls consume mouse hits without running commands and are skipped by keyboard focus.
- Restock and Barya commit once, then checkpoint. If saving fails, the purchase remains committed and further purchases/opening are blocked until Save shop succeeds. Retrying does not charge twice.
- Oil preparation starts in pour mode with a valid 50 ml bottle. Bin-switch guarding preserves an open portion. Equivalent peso/quantity options no longer highlight twice.
- Barya can use a larger bill or several smaller bills and receive supplier change. Drawer value stays identical; wallet, revenue and stock are not created by this exchange. This repairs the observed Day 7 exact-P50 exchange deadlock.
- New game clears stale preparation transients; missing pour timing arguments refuse safely. Preparation large-text heading overlap was removed.
- Inert difficulty/audio controls are hidden; settings accurately describe fixed day balance and silent audio. Reduced motion/text size remain available.
- Docs describe the authoritative parent game, ten teaching days then endless play, four props, five bins, Day 2 TindaPay, controls and local data-only saves. No SQL is used.
- No public functions were renamed. New preparation App entry points delegate to the coordinator and existing backend commands. Level tuning, money units and save schema were preserved. No assets/software were installed, files deleted or network accessed. A broad folder migration was deferred to protect the presentation build.

## Changed source, tests and documentation

- `src/ui/widgets.lua`
- `src/app.lua`
- `src/app/portion_station.lua`
- `src/app/preparation.lua`
- `src/views/preparation.lua`
- `src/views/timbangan.lua`
- `src/ui/pause.lua`
- `src/ui/pour_meter.lua`
- `src/systems/restock.lua`
- `src/app/runtime_check.lua`
- `tests/run.lua`
- `tests/test_presentation_readiness.lua`
- `tests/test_day_presentation.lua`
- `tests/support/day_playthrough.lua`
- `tests/test_day_playthrough.lua`
- `tools/smoke.lua`
- `tools/presentation_checks.lua`
- `README.md`
- `docs/controls.md`
- `docs/ARCHITECTURE.md`
- `docs/STATUS.md`

New evidence files, screenshots, backups and release outputs live under `docs/presentation-readiness`, `saves/verification-20261008075610` and `dist/presentation-20261008`. Original edited files were backed up under the readiness `backup`, `documentation/backup` and `progression/backup` directories.

## Final suite

Working directory for every command below: `C:\04 Programming Language Lua`.

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test 2>&1 | Tee-Object -FilePath 'docs/presentation-readiness/final-tests.txt' | Select-String -Pattern 'FAIL|READINESS|PLAYTHROUGH SEED|suites passed'
exit $LASTEXITCODE
```

Observed exit code: 0. Exact relevant output:

```text
PRESENTATION READINESS PASS disabled input, restock checkpoint/retry, barya, oil mode and safe timing
PASS tests.test_presentation_readiness
PLAYTHROUGH SEED 1 PASS twelve days; continuous/resumed state identical; scams=13; exchanges=68
PLAYTHROUGH SEED 42 PASS twelve days; continuous/resumed state identical; scams=12; exchanges=71
44 suites passed, 0 failed
```

[Full suite output](final-tests.txt). Two seeds each ran Days 1–12 continuously and with save/load: 48 complete day executions. All six line types, scams, events, low-coin mornings, cancellation/reservation release, cash/wallet/report reconciliation, pause and report saving were exercised. At least one actual successful transaction per day is asserted; legal cancellations remain possible. Continuous and resumed encoded states matched. [Independent progression report](progression/REPORT.md).

## Rendered source checks

The following invocations used the real LÖVE renderer, with output captured through `2>&1 | Tee-Object -FilePath <log>` and the process exit code checked. Each exited 0.

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --smoke --smoke-scenes menu,preparation-day2-large-text,preparation-day8,counter,peso-oil,peso-repack,pour-spilled-large-text,tindapay-cash-in,tindapay-cash-out,tindapay-scam-status,sukli-large-text,pause-settings,report-warning,lose --smoke-dir 'C:\04 Programming Language Lua\docs\presentation-readiness\screens'
& 'C:\Program Files\LOVE\lovec.exe' . --smoke --smoke-scenes tindapay-counter,pause-settings,preparation-day2-large-text,peso-oil --smoke-dir 'C:\04 Programming Language Lua\docs\presentation-readiness\screens'
& 'C:\Program Files\LOVE\lovec.exe' . --smoke --smoke-scenes preparation-day2-large-text,pour-spilled-large-text --smoke-dir 'C:\04 Programming Language Lua\docs\presentation-readiness\screens'
```

Exact completion lines, in that order:

```text
SMOKE COMPLETE 56 captures
SMOKE COMPLETE 16 captures
SMOKE COMPLETE 8 captures
```

[56-capture log](smoke.txt), [service log](service-smoke.txt), [final visual log](visual-final-smoke.txt). Sizes: 1024×768, 1280×720, 1920×1080, 2560×1440. The 80 source captures include actual rendered input checks for restock/save failure/retry, disabled keyboard/mouse, oil preparation, cupboard drag/drop, held fill/release/spill/reset/pause, staged cash, undo/cancel/repeated confirmations and modal/ticket guards. Service checks exercised all four scam-field mismatches, accepted scam loss, repeated rejection, matching phone tabs, verified transfers and exact-fee cash-out payout. Global checks found no new or reassigned `_G` keys.

## Native save/load and recovery

An isolated project-local slot was created at `saves/verification-20261008075610`. Player checkpoints were untouched. The verification slot's primary was copied to `checkpoint.tinda.before-corruption` before deliberately corrupting that verification primary.

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --save-check write 20261008075610
& 'C:\Program Files\LOVE\lovec.exe' . --save-check load 20261008075610
& 'C:\Program Files\LOVE\lovec.exe' . --save-check recover 20261008075610
```

All repaired/final invocations exited 0 in separate processes. Exact output:

```text
NATIVE SAVE WRITE PASS cash_centavos=100600 tips=1000 sugar_g=1750 sold=1 primary_reputation=53 backup_reputation=52
NATIVE SAVE LOAD PASS day=1 cash_centavos=100600 tips=1000 reputation=53 sugar_g=1750 history=1 paused=true duplicate_commit_unchanged=true
NATIVE SAVE RECOVER PASS day=1 cash_centavos=100600 tips=1000 reputation=52 sugar_g=1750 history=1 paused=true duplicate_commit_unchanged=true
RECOVERY WARNING Recovered last good backup: Invalid save data header or size
```

[Write](native-write-repair.txt), [load](native-load.txt), [recovery](native-recover.txt). This verifies native file round trips and backup fallback, not power-loss durability.

## Fresh package

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build.ps1 -OutputDirectory dist/presentation-20261008
& 'C:\Program Files\LOVE\lovec.exe' 'C:\04 Programming Language Lua\dist\presentation-20261008\Tindahan.love' --verify-release --verify-dir 'C:\04 Programming Language Lua\dist\presentation-20261008\verification'
```

Both exited 0. Exact build output:

```text
PACKAGE=C:\04 Programming Language Lua\dist\presentation-20261008\Tindahan.love
PACKAGE_FILES=139
PACKAGE_IMAGES=38
PACKAGE_BYTES=25772575
```

Exact packaged verification output includes:

```text
RELEASE ART PASS 38 imported assets decoded and uploaded
RUNTIME CHECK COMPLETE 8 cases; no save writes
```

[Build log](build.txt), [runtime log](release-runtime.txt), [source identity](package-identity.txt), [entry hashes](package-manifest.sha256). A local Python zipfile check compared all 139 archived entries byte-for-byte with current runtime source, required new modules, checked unique entries and excluded tests/tools/raw assets/player saves. All matched. The clean presentation ZIP includes the package, launcher, launch script, player README, changelog, verification summary and save-directory README; evidence screenshots and verification/player saves are excluded.

Eight packaged cases: counter and cabinet at 1920×1080 and 2560×1440; Timbangan, Phone, Sukli and oil preparation at 1280×720. Each measured 180 frames after 60 warm-up frames. Observed FPS range 63.96–64.45; texture memory 223.32–235.95 MiB. These values apply to this machine and this scripted run. Logs report two optional asset fallbacks (`prop_utang_notebook` and `prop_cash_drawer_open`); required imported art decoded successfully. Utang is excluded; the working drawer screen uses its existing rendering.

## Screenshots actually inspected

Ten captures were visually inspected, rather than treating all generated captures as human-reviewed:

- Source run 1791417011: 1024×768 preparation Day 2 large text, 1280×720 counter, 1024×768 spilled pour large text.
- Source run 1791417163: 1024×768 pause settings.
- Final source run 1791417429: 1024×768 preparation Day 2 large text and spilled pour large text. Confirmed the repaired heading and single selected oil option.
- Packaged run 1791417460: 1920×1080 counter; 1280×720 oil preparation, Phone and Sukli. Four props flank the customer, station content renders and staged receipt values are visible.

See [source screenshots](screens/) and [packaged screenshots](../../dist/presentation-20261008/verification/). The Phone fixture toast temporarily covers part of the lower action area; this pass did not find a blocked transaction from it. No claim is made that every screen state has been manually inspected.

## Failures found and repaired

Tests were written/run before relevant money/input fixes. Failed batches were investigated and rerun before packaging:

1. Extended progression fixture: `tests/support/day_playthrough.lua:17: Unexpected day profile`; six-day fixture was stale. Updated test driver to the actual ten-day/endless profile.
2. Disabled-input RED: `tests/test_presentation_readiness.lua:16: Disabled mouse and keyboard actions must not call game commands`; blocked callbacks and keyboard focus were corrected.
3. Day 7 progression failure: `Prepared player must complete at least one transaction on day 7`. Observed drawer P1×8, P100×1, P500×3 with no P50 subset; the exchange action refused despite enough bill value.
4. Barya RED: `tests/test_day_presentation.lua:32: A larger bill must fund the P50 coin bundle`; implemented bill payment plus supplier change with cash conservation and atomic refusal checks. Final suite 44/0.
5. First native write failed: `Cannot write temporary save: .../verification-20261008075610/checkpoint.tinda.tmp.1: No such file or directory`; created the missing isolated verification directory and reran write/load/recovery successfully. No production save change was needed.
6. Screenshot inspection found overlapping preparation heading and duplicate equivalent oil-choice highlights. Corrected both, reran final tests and eight final source captures, then built the package.

Historical failed outputs: [input RED](input-red-tests.txt), [input intermediate run](input-green-tests.txt), [Barya RED](barya-red-tests.txt), [Barya green](barya-green-tests.txt), [first native write](native-write.txt), and the progression report/logs. No unresolved test failure remains in the final run.

## Independent review

The progression subagent independently inspected the final Restock payment/change/conservation path and reported no blocker. The documentation subagent separately reviewed game changes against backups: disabled input, checkpoint retry/guard, preparation oil mode and bin preservation, settings, and timing guards. It reported no actionable blocker. Neither reviewer claimed its own independent full-suite execution; root executed the final suite, smoke and native/package checks. Small final visual corrections and runtime instrumentation were verified by root afterwards.

## Limits and last presentation rehearsal

OBSERVED: automated logic/UI/source/native/package checks above pass. INFERRED: these results support presenting this build, but do not prove every possible input sequence or balance outcome.

Not verified: unrestricted human mouse/keyboard play through all days, subjective timing/difficulty, power loss mid-save, a fresh computer without LÖVE, independent StyLua/luacheck output. Audio remains silent and difficulty uses the fixed existing balance. No installer or self-contained Windows executable was built; LÖVE 11.5 must already be installed. The nested historical skeleton remains preserved; the parent game and fresh package are the authoritative deliverables.

Before presenting, extract the clean ZIP to a writable folder, double-click Play Tindahan.bat, start a new game, demonstrate a cabinet sale and Sukli, reach Day 2 for both TindaPay services, demonstrate weighing/oil preparation, pause, Save shop and load. Use the source project's test/smoke tools for verification; they are intentionally excluded from the player release.
