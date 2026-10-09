# Regression: execute the launcher's resolver against source and packaged fixtures.
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $project 'run-game.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Launcher parse errors' }
$function = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Resolve-GameTarget' }, $true)
if (-not $function) { throw 'FAIL launcher has no testable source-first resolver' }
Invoke-Expression $function.Extent.Text
$fixture = Join-Path $project ('docs/completion-phase-b/batch-02/launcher-fixtures-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $fixture 'source'
$release = Join-Path $fixture 'release'
New-Item -ItemType Directory -Path (Join-Path $source 'tests'),(Join-Path $source 'dist'),$release | Out-Null
[IO.File]::WriteAllText((Join-Path $source 'main.lua'), '-- source')
[IO.File]::WriteAllText((Join-Path $source 'tests/run.lua'), '-- tests')
[IO.File]::WriteAllText((Join-Path $source 'dist/Tindahan.love'), 'old package')
[IO.File]::WriteAllText((Join-Path $release 'Tindahan.love'), 'package')
function Check-Target($directory, $useSource, $runTests, $expected) {
    $actual = Resolve-GameTarget -ProjectDirectory $directory -UseSource $useSource -RunTests $runTests
    if ($actual -ne $expected) { throw "FAIL target: $actual expected: $expected" }
}
Check-Target $source $false $false $source
Check-Target $source $false $true $source
Check-Target $source $true $false $source
Check-Target $release $false $false (Join-Path $release 'Tindahan.love')
foreach ($mode in @('test','source')) {
    $rejected = $false
    try { Resolve-GameTarget -ProjectDirectory $release -UseSource ($mode -eq 'source') -RunTests ($mode -eq 'test') | Out-Null }
    catch { $rejected = $_.Exception.Message -match 'source' }
    if (-not $rejected) { throw "FAIL packaged $mode must explain source requirement" }
}
Write-Output 'LAUNCHER PASS source-first play/test; source flag; packaged play; packaged diagnostics reject clearly'
