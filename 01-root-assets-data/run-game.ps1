param([switch]$Test, [switch]$Source)
$ErrorActionPreference = 'Stop'
# Choose edited source when present; release folders contain only a package.
function Resolve-GameTarget {
    param([string]$ProjectDirectory, [bool]$UseSource, [bool]$RunTests)
    $hasSource = Test-Path -LiteralPath (Join-Path $ProjectDirectory 'main.lua') -PathType Leaf
    if ($RunTests) {
        $hasTests = Test-Path -LiteralPath (Join-Path $ProjectDirectory 'tests/run.lua') -PathType Leaf
        if (-not $hasSource -or -not $hasTests) {
            throw 'Tests require the source project with tests/run.lua. Run -Test from the source folder.'
        }
        return $ProjectDirectory
    }
    if ($hasSource) { return $ProjectDirectory }
    if ($UseSource) { throw 'Source files are absent. Run the packaged game without -Source.' }
    foreach ($name in @('Tindahan.love', 'dist/Tindahan.love')) {
        $candidate = Join-Path $ProjectDirectory $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'No source project or Tindahan.love package was found.'
}

$projectDirectory = [IO.Path]::GetFullPath($PSScriptRoot)
$runtimeName = if ($Test) { 'lovec.exe' } else { 'love.exe' }
$runtimePath = Join-Path ${env:ProgramFiles} ('LOVE\' + $runtimeName)
if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) {
    $runtimeCommand = Get-Command $runtimeName -ErrorAction SilentlyContinue
    if ($runtimeCommand) { $runtimePath = $runtimeCommand.Source }
    else { throw 'LÃ–VE 11.5 was not found. Install it separately, then run this launcher again.' }
}
$gamePath = Resolve-GameTarget -ProjectDirectory $projectDirectory -UseSource $Source.IsPresent -RunTests $Test.IsPresent
$saveBase = if ($gamePath -eq $projectDirectory) { $projectDirectory } else { Split-Path -Parent $gamePath }
$saveDirectory = Join-Path $saveBase 'saves'
if (-not (Test-Path -LiteralPath $saveDirectory)) { New-Item -ItemType Directory -Path $saveDirectory | Out-Null }
if ($Test) { & $runtimePath $gamePath --test } else { & $runtimePath $gamePath }
exit $LASTEXITCODE
