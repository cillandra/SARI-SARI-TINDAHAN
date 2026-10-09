> Historical report: the 9 October 2026 GitHub preparation excludes old backup archives and generated captures from the source-upload ZIP. Links and commands for those local artifacts below are historical records, and their targets are not included in the ZIP. Proposed permanent deletion is pending confirmation. See [GitHub preparation](../GITHUB.md).

# Authorized project cleanup — 8 October 2026

OBSERVED: removed 6,280 obsolete files after a verified recovery backup. Gameplay code and assets were unchanged. The project and current release still pass the checks below.

Removed material: 2138.63 MiB. Deduplicated recovery archive: 1365.48 MiB, storing 3,514 unique files for all 6,280 original paths. Net saving from these removals minus the recovery archive: 773.15 MiB (before small new logs/manifests). One recovery archive remains inside the project.

## Removed from the working folders

- The obsolete `sari-sari-tindahan` skeleton.
- All obsolete dist builds, batch/fix ZIPs, old launchers and the duplicate extracted presentation copy.
- Historical review/screenshot/milestone folders, old plans, mockups, redundant kit copy, old backup folders and obsolete documentation.
- Generated save-verification slots and old archived checkpoint copies.
- Uninspected duplicate-run presentation screenshots; the six previously inspected source captures and eight packaged verification captures remain.

The exact original paths, hashes and removal targets are in [plan.json](plan.json). Removed content is recoverable; active player checkpoints were not deleted.

## Retained and protected

- Current parent source, `data/`, normalized `assets/`, and your original `assets_raw/`. Original artwork is retained for the asset-normalization workflow.
- Tests and developer tools; current architecture, controls, status, reference images, original guides and final verification evidence.
- Source `saves/checkpoint.tinda` and `saves/checkpoint.tinda.bak`, byte-for-byte unchanged.
- `dist/presentation-20261008/`, the playable presentation release. The played checkpoint from the duplicate extracted release was copied byte-for-byte to this retained release.
- `dist/Tindahan_Presentation_20261008.zip`, the clean distribution. It still excludes player saves.
- Four older player-save files preserved independently at `saves/legacy-player-saves/`, retaining their old folder identities.

The retained release package, clean ZIP and all 253 protected files matched their pre-cleanup hashes. All 139 package entries match current runtime source. Package ZIP CRC validation passed. No Lua source, public function, money rule or gameplay setting changed.

## Updated documents

- `README.md`: current folder map and cleanup link.
- `docs/ARCHITECTURE.md` and `docs/STATUS.md`: obsolete skeleton/releases are archived rather than active.
- `docs/presentation-readiness/REPORT.md`: notice distinguishes historical verification statements from subsequent cleanup.

Original versions are retained in [documentation-before](documentation-before/). Cleanup-specific manifests, scripts, logs and current smoke captures are in this folder.

## Actual checks and commands

Working directory: `C:\04 Programming Language Lua`. Commands were run with local filesystem permission; no software installation or network access occurred.

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test 2>&1 | Tee-Object -FilePath 'docs/cleanup-20261008/before-tests.txt' | Select-String -Pattern 'FAIL|suites passed'
exit $LASTEXITCODE
& 'docs/cleanup-20261008/remove-obsolete.ps1' 2>&1 | Tee-Object -FilePath 'docs/cleanup-20261008/removal.txt'
& 'C:\Program Files\LOVE\lovec.exe' . --test 2>&1 | Tee-Object -FilePath 'docs/cleanup-20261008/after-tests.txt' | Select-String -Pattern 'FAIL|suites passed'
exit $LASTEXITCODE
& 'docs/cleanup-20261008/restore-recovery.ps1' 2>&1 | Tee-Object -FilePath 'docs/cleanup-20261008/recovery-dry-run.txt'
& 'C:\Program Files\LOVE\lovec.exe' . --smoke --smoke-scenes counter,tindapay-counter --smoke-dir 'C:\04 Programming Language Lua\docs\cleanup-20261008\screens' 2>&1 | Tee-Object -FilePath 'docs/cleanup-20261008/smoke.txt' | Select-String -Pattern 'PASS|FAIL|COMPLETE'
exit $LASTEXITCODE
```

All exited 0. Exact test output, before and after cleanup:

```text
44 suites passed, 0 failed
```

Exact recovery dry-run output:

```text
RECOVERY DRY RUN PASS 6280 missing files; no writes; use -Restore only if you want the removed files back
```

Exact post-cleanup integrity output:

```text
INTEGRITY PASS 253 protected files unchanged; 139 package entries match source; distribution CRC passes; preserved release save identical
```

Rendered output includes:

```text
PRESENTATION UI CHECK PASS restock save/retry, disabled mouse/keyboard, oil bottle and honest settings
SERVICE UI CHECK PASS four scam-field rejections, accepted scam loss, valid rejection and repeated click
TINDAPAY UI CHECK PASS rendered phone tabs, verification staging, exact-fee cash_out drawer and payout
GLOBAL CHECK PASS no new or reassigned _G keys
SMOKE COMPLETE 8 captures
```

[Baseline tests](before-tests.txt), [post-cleanup tests](after-tests.txt), [removal log](removal.txt), [integrity](integrity.txt), [recovery dry run](recovery-dry-run.txt), [smoke log](smoke.txt). The original removal log printed a repetitive property-count value because of PowerShell enumeration formatting; the independent integrity check confirms the correct count of 253. The log-format expression was corrected without repeating deletion.

The deletion script verified the archive checksum, complete unchanged file inventory, target containment within the project, absence of reparse points and protected hashes before any `Remove-Item -LiteralPath` call. It also checked that every target was gone afterwards. A local Python zipfile/hashlib check created and verified the deduplicated archive, and separately checked unchanged source/package/ZIP/player-save bytes.

Two of the eight new captures were actually visually inspected: `1791418672-1280x720-counter.png` and `1791418672-1024x768-tindapay-counter.png`. The centered customer, four flanking props, Day 1 locked phone and Day 2 cash_in ticket/phone render. [Screenshots](screens/).

## Recovery, if needed

`recovery.zip` stores each distinct file once at an original path; `__cleanup_manifest.json` maps duplicate original paths to the stored entries. Use the provided helper rather than ordinary extraction to recover every duplicate path.

To validate recovery without writing files:

```powershell
& 'docs/cleanup-20261008/restore-recovery.ps1'
```

To intentionally put the removed material back in this original project folder:

```powershell
& 'docs/cleanup-20261008/restore-recovery.ps1' -Restore
```

The helper verifies the archive, restricts writes to the original project, rejects reparse-point parents and refuses to overwrite a changed existing file. The actual restore was not run because it would undo the requested cleanup. This recovery archive is not used by the game. Keep it until you are comfortable with the cleaned project.

## Limits

OBSERVED: baseline/final tests, smoke and byte-integrity checks pass. INFERRED: the removed files are not runtime dependencies; source/package integrity and rendered tests support that conclusion. A full human playthrough was not repeated. Older saves were preserved, but their gameplay compatibility was not independently revalidated. The current presentation progress was preserved byte-for-byte; it was not loaded into an unrestricted live session. No new performance or native-disk corruption test was run in this cleanup pass.
