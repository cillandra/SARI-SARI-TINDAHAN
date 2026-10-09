# GitHub preparation — 9 October 2026

OBSERVED: original project size was 1754.50 MiB. The old recovery ZIP alone is 1365.48 MiB. Lua source is under 1 MiB; source architecture was not the cause of the size problem.

## Permanent cleanup is pending

Automatic approval review rejected the permanent deletion: 239 files, 1450.86 MiB. The reviewer requires explicit confirmation for deleting files not created by the agent, especially the old recovery archive and numbered save backups. No existing files were deleted in this pass. The exact candidate list and pre-change protected hashes are in the local inventory.json, excluded from GitHub.

Candidates:

- Old cleanup recovery archive/evidence: 27 files, 1376.54 MiB.
- Timing-pass backup/captures: 30 files, 39.07 MiB.
- Presentation captures: 14 files, 6.32 MiB.
- Redundant presentation distribution ZIP: 1 file, 24.59 MiB.
- Numbered archived save backups: 167 files, 4.35 MiB.

The primary checkpoint.tinda and checkpoint.tinda.bak files in all locations are protected, along with all source, runtime and raw assets, tests, tools and the current .love release. Original artwork remains locally and is excluded from GitHub. No further recovery ZIP was created.

## Prepared source copy

OBSERVED: dist/Tindahan_Source_GitHub.zip contains 224 files. Its prepared runtime images are included; raw artwork, releases, player saves and generated evidence are excluded. Extract it and upload its contents, including .gitignore. See [instructions](../GITHUB.md). All 139 runtime entries matched the existing presentation .love byte-for-byte; ZIP CRC and source byte comparisons passed. Largest source file: 3.35 MiB.

Changed files: .gitignore, README.md, docs/GITHUB.md, docs/STATUS.md, notices in the three historical reports, two screenshot-directory .gitkeep files, this report and local verification records, and the new source ZIP. No Lua source, public function, game rule, asset or player checkpoint changed. Small original documentation copies were retained locally before edits.

## Actual verification

Commands run in C:\04 Programming Language Lua with the installed LÖVE runtime:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test 2>&1 | Tee-Object -FilePath 'docs/github-cleanup-20261009/before-tests.txt' | Select-String -Pattern 'FAIL|suites passed'
exit $LASTEXITCODE
& 'C:\Program Files\LOVE\lovec.exe' 'docs/github-cleanup-20261009/source-check' --test 2>&1 | Tee-Object -FilePath 'docs/github-cleanup-20261009/fresh-source-tests.txt' | Select-String -Pattern 'FAIL|suites passed'
exit $LASTEXITCODE
& 'C:\Program Files\LOVE\lovec.exe' 'docs/github-cleanup-20261009/source-check' --smoke --smoke-scenes counter,tindapay-counter 2>&1 | Tee-Object -FilePath 'docs/github-cleanup-20261009/fresh-source-smoke.txt' | Select-String -Pattern 'PASS|FAIL|COMPLETE|SMOKE '
exit $LASTEXITCODE
```

The real invocations piped output to the local before-tests.txt, fresh-source-tests.txt and fresh-source-smoke.txt files using Tee-Object, filtering displayed status lines using Select-String. All three processes exited 0. Exact test result for both runs:

```text
44 suites passed, 0 failed
```

Exact smoke status lines include:

```text
CONTRAST SHADER PASS
SAVE UI CHECK PASS rendered save/menu/load, exact cash and transient cleanup
PRESENTATION UI CHECK PASS restock save/retry, disabled mouse/keyboard, oil bottle and honest settings
TINDAPAY UI CHECK PASS rendered phone tabs, verification staging, exact-fee cash_out drawer and payout
GLOBAL CHECK PASS no new or reassigned _G keys
SMOKE COMPLETE 8 captures
```

OBSERVED: visually inspected counter at 1280x720 and Day 2 TindaPay counter at 1024x768. Prepared customer, props and background rendered in the extracted source with no assets_raw present. The default screenshot output directory worked. Only those two images were retained locally as new evidence.

Git ignore checks used an isolated repository fixture under this report directory, with git init --quiet, git --git-dir <fixture> --work-tree <project> check-ignore --no-index, and ls-files --others --exclude-standard. The actual project was not initialized as a repository. Exact output:

```text
IGNORE CHECK PASS 6 excluded paths; 11 retained paths
SOURCE PACKAGE PASS 224 files; 139 runtime entries identical; CRC and byte comparison pass
INTEGRITY PASS 256 protected files unchanged
```

A read-only independent review found no runtime dependency on the proposed junk files and identified the need to retain default screenshot directories and data/asset_mapping.lua; both were retained. Temporary extracted-source and Git fixtures created by this pass are removed after checks; the ZIP and two inspected images remain.

## Limits

OBSERVED: no upload, network use, installation or existing-file deletion took place. INFERRED: the curated source is suitable for a smaller GitHub upload, based on the verified payload; actual GitHub account/network/upload acceptance was not checked. A complete human playthrough and re-normalization from raw artwork were not repeated. Numbered archived save backups can grow again during play; they are excluded from GitHub, and persistence rules were not changed. The original folder remains large until permanent cleanup is approved.
