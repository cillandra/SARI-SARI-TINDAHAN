param([string]$OutputName = 'Tindahan.love', [string]$OutputDirectory = 'dist/release-20261007')
$ErrorActionPreference = 'Stop'
$projectDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if ([IO.Path]::GetFileName($OutputName) -ne $OutputName -or -not $OutputName.EndsWith('.love')) { throw 'OutputName must be a .love filename without directories.' }
$distDirectory = [IO.Path]::GetFullPath((Join-Path $projectDirectory $OutputDirectory))
if (-not $distDirectory.StartsWith($projectDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'OutputDirectory must stay inside the project.' }
if (Test-Path -LiteralPath $distDirectory) { throw 'Release folder already exists. Choose a fresh OutputDirectory; existing releases are preserved.' }
New-Item -ItemType Directory -Path (Join-Path $distDirectory 'saves') | Out-Null
$packagePath = Join-Path $distDirectory $OutputName
$stagedPath = $packagePath + '.building'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$files = @()
foreach ($name in @('main.lua','conf.lua','src','data','assets/img')) {
 $path = Join-Path $projectDirectory $name
 if (Test-Path -LiteralPath $path -PathType Container) { $files += Get-ChildItem -LiteralPath $path -File -Recurse | Where-Object { $_.Extension -in @('.lua','.png') } }
 else { $files += Get-Item -LiteralPath $path }
}
$stream = [IO.File]::Open($stagedPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite)
$archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $false)
try {
 foreach ($file in $files) {
  $entryName = $file.FullName.Substring($projectDirectory.Length+1).Replace('\','/')
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$entryName,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
 }
} finally { $archive.Dispose(); $stream.Dispose() }
Move-Item -LiteralPath $stagedPath -Destination $packagePath
Copy-Item -LiteralPath (Join-Path $projectDirectory 'Play Tindahan.bat'),(Join-Path $projectDirectory 'README.md'),(Join-Path $projectDirectory 'CHANGELOG.md') -Destination $distDirectory
$quotedName = $OutputName.Replace("'", "''")
$launcher = [IO.File]::ReadAllText((Join-Path $projectDirectory 'run-game.ps1')).Replace("'Tindahan.love'", "'$quotedName'")
[IO.File]::WriteAllText((Join-Path $distDirectory 'run-game.ps1'), $launcher)
[IO.File]::WriteAllText((Join-Path $distDirectory 'saves/README.txt'), 'Use Play Tindahan.bat. Saves are data-only checkpoint.tinda and last-good checkpoint.tinda.bak. No player saves are included.')
Write-Output "PACKAGE=$packagePath"
Write-Output "PACKAGE_FILES=$($files.Count)"
Write-Output "PACKAGE_IMAGES=$(($files | Where-Object Extension -eq '.png').Count)"
Write-Output "PACKAGE_BYTES=$((Get-Item -LiteralPath $packagePath).Length)"
