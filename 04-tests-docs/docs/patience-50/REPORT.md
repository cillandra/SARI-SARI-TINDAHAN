> Historical report: the 9 October 2026 GitHub preparation excludes old backup archives and generated captures from the source-upload ZIP. Links and commands for those local artifacts below are historical records, and their targets are not included in the ZIP. Proposed permanent deletion is pending confirmation. See [GitHub preparation](../GITHUB.md).

# Fifty-second customer patience — 8 October 2026

OBSERVED: new customers start with 50 seconds on Days 1–10 and endless play. Queued customers still spend patience while waiting at the existing half-speed rate. Pausing, event drain modifiers and once-only completion bonuses are unchanged.

On load/refresh, an old customer with starting patience 30 and remaining 20 becomes starting 50 and remaining 40. The ten elapsed seconds are preserved; repeated refresh leaves 40 unchanged. Legacy customers without a starting field are still clamped safely. Player checkpoint files were preserved byte-for-byte.

## Changed files

Runtime:
- `data/config.lua`: patience cap 50.
- `data/levels.lua`: all starting patience reads the configured value, including endless.
- `src/systems/order.lua`: migrate starting allowance while preserving elapsed patience, once.

Tests:
- `tests/test_customer_flow.lua`: survival through 49 seconds, expiration at 50, pause, capped bonuses and idempotent old-customer migration.
- `tests/test_level_generation.lua`: updated intended day/endless patience expectations; mutable cap test restores its previous value.
- `tests/test_payment_outcomes.lua`: full-patience fixture uses the customer's actual starting allowance; the 70 percent boundary is 35/50. Reward rules did not change.

Documentation/distribution:
- Source `README.md` and current release `README.md`, `VERIFICATION.md` describe the timer.
- Existing `dist/presentation-20261008/Tindahan.love` and `dist/Tindahan_Presentation_20261008.zip` updated in place after verification. No additional dist release folder remains.

Original text files and the prior clean distribution are retained under `backup/`. No public functions were renamed; no money, inventory, order, arrival or queue-limit rules changed.

## Verification and actual output

All commands used `C:\04 Programming Language Lua` as the working directory and the installed local runtime. Test runs used:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test 2>&1 | Tee-Object -FilePath 'docs/patience-50/final-tests.txt' | Select-String -Pattern 'FAIL|PLAYTHROUGH SEED|suites passed'
exit $LASTEXITCODE
```

Final exit code 0:

```text
PLAYTHROUGH SEED 1 PASS twelve days; continuous/resumed state identical; scams=13; exchanges=68
PLAYTHROUGH SEED 42 PASS twelve days; continuous/resumed state identical; scams=12; exchanges=71
44 suites passed, 0 failed
```

[Final full suite log](final-tests.txt). The expected first RED run ended `42 suites passed, 2 failed` for customer timing and level metadata. After configuration adjustment, `tests.test_payment_outcomes` failed at line 25 with `attempt to compare number with nil`: its fixture still called 30 seconds full/happy patience. Updating that fixture to full starting patience fixed it. A separate migration RED run ended `43 suites passed, 1 failed` with `Old thirty-second customer gains twenty seconds while preserving elapsed time`. The elapsed-time migration repaired that assertion; the final suite passed. [Initial RED](red-tests.txt), [intermediate reward failure](tests.txt), [migration RED](save-timing-red.txt).

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --smoke --smoke-scenes counter,tindapay-counter --smoke-dir 'C:\04 Programming Language Lua\docs\patience-50\screens'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build.ps1 -OutputDirectory docs/patience-50/build
& 'C:\Program Files\LOVE\lovec.exe' 'C:\04 Programming Language Lua\docs\patience-50\build\Tindahan.love' --verify-release --verify-dir 'C:\04 Programming Language Lua\docs\patience-50\build\verification'
```

All final invocations exited 0. Exact relevant output:

```text
SMOKE COMPLETE 8 captures
PACKAGE_FILES=139
PACKAGE_IMAGES=38
PACKAGE_BYTES=25772581
RELEASE ART PASS 38 imported assets decoded and uploaded
RUNTIME CHECK COMPLETE 8 cases; no save writes
UPDATED RELEASE PASS 139 source-matching package entries; clean distribution CRC passes; player save hashes unchanged
```

[Smoke output](smoke.txt), [build output](build.txt), [packaged runtime output](release-runtime-final.txt), [package hashes](package.txt). A first package verification invocation rejected its screenshot path with `ERROR src/app/runtime_check.lua:21: Verification output must stay inside source/package folder`. The harness directory was corrected and the package run succeeded; production was not changed for this guard. [Rejected invocation](release-runtime.txt).

The temporary build package's 139 entries were compared byte-for-byte to current runtime source before promotion. Distribution ZIP CRC and all seven entry bytes were checked; it contains no player checkpoints. Source and current release checkpoint hashes were identical before/after replacement. The temporary build directory was removed using a checked absolute project-local path only after promotion succeeded. Its verification images were retained in `release-screens/`.

The 1280×720 source counter capture `1791419575-1280x720-counter.png` was actually inspected: the customer's circular timer visibly displays 50. Other generated images were not all manually inspected. [Source captures](screens/), [package captures](release-screens/).

An independent subagent reviewed the three runtime changes against backups and reported no blocker: 50 applies to every day, 30/20 migrates to 50/40 once, pause/bonuses remain intact, and money/arrival/event rates were unchanged. It performed source review, not an independent test run.

## Limits

No full unrestricted human playthrough was repeated. Existing player checkpoints were not overwritten or loaded in a live session for this verification; migration was exercised through the real domain refresh path, while the full suite also covered save/resume progression. Older readiness/cleanup reports and their package hashes describe those previous versions. Restart the running game to use this updated source/package; re-extract the updated presentation ZIP if playing a separate extracted copy.
