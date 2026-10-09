# Putting the game on GitHub

The playable source is the folder containing main.lua and conf.lua. Keep src/, data/ and assets/ together. Tests and tools help maintain it. LÖVE 11.5 must already be installed to run the game.

## Small source upload

1. Extract dist/Tindahan_Source_GitHub.zip to a new folder.
2. Upload the extracted files and folders into your GitHub repository, including .gitignore. Do not upload the ZIP itself as a replacement for source code.
3. Keep main.lua, conf.lua, src/, data/ and assets/ at the same repository level. The launcher runs this source folder.

Alternatively, use Git locally from the original source folder. The supplied .gitignore excludes builds, saves, original artwork and generated evidence from new staging operations. This folder was not a Git repository when the cleanup began. No repository was created or uploaded by the cleanup. If you already tracked unwanted files elsewhere, ignore rules alone do not remove those tracked files.

## Kept locally, excluded from the source copy

- assets_raw/: your editable original artwork. The game draws the smaller prepared assets/img images. Only --normalize needs assets_raw; normal play and tests do not. Keep your originals separately if you need to regenerate assets.
- dist/: the current runnable release and the source-upload ZIP.
- saves/: private progress and backups. The source copy includes its README, not player data. The game writes new checkpoints as you play.
- Generated screenshots, old archives and local verification logs. Short reports remain as text; old report links to excluded local evidence are historical.

Empty screenshot directories are retained using .gitkeep so default --smoke and --check-contrast have output locations in a fresh source copy.

## Check the extracted source

Run PowerShell in the extracted folder:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --test
& 'C:\Program Files\LOVE\lovec.exe' . --smoke
```

For play, double-click Play Tindahan.bat. No SQL server or asset normalization step is needed. GitHub connectivity, account permissions and an actual upload were not checked; this preparation uses local tools only.
