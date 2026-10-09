# Sari-Sari Tindahan

A cozy 2D shopkeeping game for **Lua/LuaJIT and LÖVE 11.5**. Prepare stock, serve neighbors, measure loose goods, count sukli, and verify TindaPay transfers across ten teaching days followed by endless play.

## Play the current game

The **parent folder** containing this README and main.lua is the authoritative source project. Double-click **Play Tindahan.bat** here to run the edited source. LÖVE 11.5 must already be installed; the launcher installs nothing.

For presentation, use the fresh **dist/presentation-20261008** release folder (or its fresh suffix if that name already existed), and double-click its **Play Tindahan.bat**. Keep the whole release folder together. Its launcher runs the colocated Tindahan.love. Obsolete builds and the earlier skeleton were removed. The current runnable release remains in dist/. Old recovery archives, redundant presentation ZIPs and generated screenshots are excluded from GitHub; their permanent removal is pending explicit confirmation after automatic approval review blocked deletion.

The exact final release path, verification results, and remaining limitations are recorded in [the readiness report](docs/presentation-readiness/REPORT.md).

## Main workflow

1. **Preparation:** buy stock, adjust prices, optionally prepare sugar bags or oil bottles, then open the store.
2. **Counter:** serve a neighbor and read the order ticket. Sukli and Timbangan are on the left; Cabinet and TindaPay are on the right of the central customer.
3. **Fulfill orders:** pick cabinet goods; hold and release at Timbangan; verify eligible TindaPay requests.
4. **Payment:** after all lines are complete, receive payment. Exact payment completes automatically; otherwise select real drawer pieces and confirm sukli.
5. **Report:** inspect sales, fees, profit, losses, Suki, and stars; save or continue to the next morning.

Customers start with **50 seconds of patience on every day, including endless play**. Existing queued customers receive the new allowance on load while keeping elapsed time; reloading cannot refill the timer. Queue waiting rates, pause behavior and line bonuses remain the same. See [timing verification](docs/patience-50/REPORT.md).

Day 2 introduces cash_in and cash_out, spotlighted by its first two customers. Later days retain earlier unlocks. Day 3 adds weighing, Day 4 repacking, and Day 5 oil pouring. Later days add transfer scams, events, and coin shortages. There is **no utang gameplay** and **no SQL/database server**.

Measured orders vary by product and quantity. Repacking offers 1/4 kg, 1/2 kg, P10, and P20; oil offers 50 ml, 100 ml, P10, and P20. A service container choice never changes the customer's quoted request or price. Hold to fill, release in the green range, and use **Ulitin** to restart. Oil spilling consumes stock and charges the configured P1 penalty.

## Saves and settings

Saves are validated, data-only **saves/checkpoint.tinda** files with a last-good **checkpoint.tinda.bak**. Source saves beside this project; the package saves beside its .love file. Finish or cancel the active transaction before saving.

Reports and successful restock operations checkpoint the shop. Next morning saves before advancing. A save failure leaves the current game available and displays a warning; retry **Save shop**. Backup recovery also displays a warning.

Escape pauses. Reduced motion and text size are available in Settings. There is no connected audio playback, and level balance follows the prescribed day plan. F1 toggles runtime statistics.

## Source checks and build

Run from the source folder with the installed runtime:

    & 'C:\Program Files\LOVE\lovec.exe' . --test
    & 'C:\Program Files\LOVE\lovec.exe' . --smoke

Tests exercise domain rules; smoke checks render screens and exercise selected real UI paths. They do not substitute for a complete human playthrough. The readiness report records what was actually verified.

Build a fresh release directory inside the project:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/build.ps1 -OutputDirectory dist/presentation-20261008

Existing release folders are preserved; choose a fresh suffix if needed. Source diagnostics require tests and tools. The runtime package contains main.lua, conf.lua, src, data, and runtime assets, excluding player saves and development files.

See [controls](docs/controls.md), [architecture](docs/ARCHITECTURE.md), and [current status](docs/STATUS.md).

## Folder organization

- `src/`, `data/`, `assets/`, main.lua and conf.lua: the playable game.
- `assets_raw/`: your original artwork, used by the normalization tool.
- `tests/` and `tools/`: validation, smoke checks and packaging.
- `docs/`: guides and short verification reports; generated evidence stays local and is excluded from GitHub.
- `saves/`: active source checkpoint/backup and preserved legacy player saves.
- `dist/presentation-20261008/`: the current playable release, with the checkpoint preserved from the previously extracted copy.
- `dist/Tindahan_Source_GitHub.zip`: a curated source copy for GitHub, without raw artwork, builds or player saves. Extract it before uploading the files.

See [current cleanup results](docs/github-cleanup-20261009/REPORT.md) and [GitHub upload instructions](docs/GITHUB.md). The old recovery archive is excluded from GitHub and queued for permanent removal; it remains local until deletion is confirmed. Historical evidence and restore tools are not included in the source-upload ZIP.
