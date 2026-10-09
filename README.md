# Sari-Sari Tindahan

**Sari-Sari Tindahan** is a cozy 2D shopkeeping game inspired by a Filipino neighborhood store. Play as the shopkeeper: prepare stock, serve customers, weigh loose goods, give the correct sukli, and handle simulated TindaPay services.

The game is written in **Lua** using **LÖVE 11.5**. It introduces new tasks across ten days, followed by endless play. Your goal is to manage the shop's stock and money while keeping customers satisfied.

## What you can do

- **Cabinet:** sell packaged goods and keep track of remaining stock.
- **Sukli:** choose coins and bills to give the correct change. Exact payments finish automatically.
- **Timbangan:** weigh goods such as rice, flour, sugar and salt; prepare repacked goods and oil orders as they unlock.
- **TindaPay:** verify simulated cash-in and cash-out requests from Day 2 onward. Compare the transfer details before accepting.
- **Preparation:** buy supplies, adjust prices, exchange cash for smaller denominations, and prepare stock before opening.
- **Daily report:** review sales, service fees, profit, losses, Suki rating and stars.
- **Save and load:** resume your shop using local save files and a backup.
- **Pause and settings:** pause the game, adjust text size and enable reduced motion.

Customers begin with a 50-second patience allowance. Keep an eye on their timers and the order ticket; waiting customers can lose patience too. Later days introduce more demanding orders and shop events.

## Requirements

- A computer with **LÖVE 11.5** installed separately. The supplied launcher is for Windows.
- All game files together in one extracted folder.
- Permission to write to that folder so the game can save progress.

You do not need a separate Lua installation or an SQL database. Gameplay and saving work offline. GitHub stores the source files; this game runs locally rather than inside the GitHub website.

## Download and assemble the four batches

If you downloaded the complete GitHub repository, extract its ZIP and open the folder containing **main.lua**. You can skip these batch-assembly steps if the repository already has the combined folder structure shown below.

If you received four separate ZIPs or extracted batch folders, **you need all four**:

| Batch | Contents |
|---|---|
| 01-root-assets-data | Launcher, main files, prepared artwork and game data |
| 02-game-code-a | First part of the game code |
| 03-game-code-b-tools | Remaining game code and developer tools |
| 04-tests-docs | Tests and documentation |

1. Create a new folder named **Sari-Sari Tindahan**.
2. Extract each ZIP separately if it has not already been extracted.
3. Open **01-root-assets-data** and copy everything inside it into your new game folder.
4. Repeat with the contents of **02-game-code-a**, **03-game-code-b-tools**, and **04-tests-docs**.
5. Merge matching folders, such as **src**, so their contents are combined. Keep all subfolders in their original structure.

**Copy the contents of each batch, not the outer batch folders.** Do not flatten the files into one directory. The four batches are parts of one game, not four separate games.

The finished folder should look like this:

```text
Sari-Sari Tindahan/
├── main.lua
├── conf.lua
├── Play Tindahan.bat
├── run-game.ps1
├── README.md
├── .gitignore
├── src/
├── data/
├── assets/
│   └── img/
├── tests/
├── tools/
├── docs/
└── saves/
```

Other included guides, such as CHANGELOG.md, may also appear at the top level. Keep them with the project.

## Start playing

1. Install LÖVE 11.5 if it is not already installed.
2. Open your assembled game folder.
3. Double-click **Play Tindahan.bat** on Windows.
4. Start a new shop, or continue if you have an existing checkpoint.

If the launcher cannot find LÖVE, ensure it is installed in the standard Windows location or available on PATH. You can also open PowerShell in the assembled folder and run:

```powershell
& 'C:\Program Files\LOVE\love.exe' .
```

The command above assumes LÖVE is installed at that location. Do not run the game directly from inside a ZIP file.

## Basic gameplay

1. **Prepare:** buy stock and get your shop ready, then open the store.
2. **Serve:** select a customer and read their order ticket.
3. **Fulfill:** use Cabinet, Timbangan or TindaPay for the requested lines. For measured goods, hold to fill and release in the green range.
4. **Receive payment:** complete the order, then receive payment. If change is required, use Sukli and confirm the correct coins and bills.
5. **Review:** finish the day, check your report, save and proceed to the next morning.

Day 1 introduces goods and change; Day 2 adds TindaPay; Day 3 adds weighing; Day 4 adds repacking; Day 5 adds oil pouring. Previously unlocked tasks remain available. After Day 10, the shop continues in endless mode.

### Controls

| Input | Action |
|---|---|
| Mouse | Select customers, stations, products and buttons |
| Hold and release | Fill measured goods at Timbangan |
| 1 | Counter |
| 2 | Cabinet |
| 3 | Sukli |
| 4 | Timbangan |
| 5 | TindaPay, when unlocked |
| Tab / Enter | Select / activate a button |
| Escape | Close an open dialog or toggle pause |

See [the complete player guide](docs/controls.md) for detailed controls and transaction handling.

## Progress and saved games

The download includes **no personal player progress**. A fresh copy starts a new shop and creates its own saves.

Save with **Save shop** when no transaction is active. Completed reports and successful stock purchases also checkpoint progress. The game stores data locally in **saves/checkpoint.tinda**, with **checkpoint.tinda.bak** as the last-good backup. Keep this folder if you want to retain your progress.

## Troubleshooting

- **Missing module or asset:** confirm that all four batches were combined and that src/, data/ and assets/ are beside main.lua.
- **Launcher cannot find the game:** open the assembled folder, not one isolated batch folder.
- **Save warning:** move your extracted game to a folder you can write to, and retry saving without an active transaction.
- **No Continue option on a fresh download:** this is expected when no checkpoint exists yet.
- **No sound:** the current version has no connected audio playback.

## For students and developers

The source separates game data, rules, commands, screens and UI. Prepared images are included in assets/img; original editable artwork, old builds and personal saves are excluded from this download. Money uses integer centavos, and saves contain game data rather than an SQL database.

See [architecture](docs/ARCHITECTURE.md) and [GitHub upload instructions](docs/GITHUB.md). With the installed runtime, developers can run these commands from the complete source folder:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test
& 'C:\Program Files\LOVE\lovec.exe' . --smoke
```

Smoke checks generate screenshots for inspection. They supplement automated tests; they do not replace a full human playthrough.
