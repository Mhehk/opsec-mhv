param(
    [string]$ProfilePath = 'C:\Users\Murat\AppData\Roaming\ModrinthApp\profiles\Mihehehek Kilient',
    [switch]$WithoutAxiom,
    [switch]$FullPack
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot
$metaPath = Join-Path (Split-Path (Split-Path $ProfilePath)) 'meta'
$versionDir = Join-Path $metaPath 'versions/1.21.11-0.19.3'
$manifest = Get-Content (Join-Path $versionDir '1.21.11-0.19.3.json') -Raw | ConvertFrom-Json
$runName = if ($FullPack) { 'full-pack' } elseif ($WithoutAxiom) { 'without-axiom' } else { 'with-axiom' }
$runPath = Join-Path $projectPath ('test-runs/' + $runName + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path (Join-Path $runPath 'mods'),(Join-Path $runPath 'harness-classes'),(Join-Path $runPath 'natives') -Force | Out-Null
$libraryRoot = Join-Path $metaPath 'libraries'
$libraries = [System.Collections.Generic.List[string]]::new()
foreach ($library in $manifest.libraries) {
    if ($library.PSObject.Properties.Name -contains 'include_in_classpath' -and -not $library.include_in_classpath) { continue }
    $allowed = $true
    if ($library.rules) {
        $allowed = $false
        foreach ($rule in $library.rules) {
            if ((-not $rule.os -or (-not $rule.os.name -or $rule.os.name -eq 'windows')) -and
                (-not $rule.os.arch -or $rule.os.arch -eq 'amd64' -or $rule.os.arch -eq 'x86_64')) {
                $allowed = $rule.action -eq 'allow'
            }
        }
    }
    if (-not $allowed) { continue }
    $rel = $library.downloads.artifact.path
    if (-not $rel) {
        $parts = $library.name.Split(':')
        $classifier = if ($parts.Length -gt 3) { '-' + $parts[3] } else { '' }
        $rel = $parts[0].Replace('.','/') + '/' + $parts[1] + '/' + $parts[2] + '/' + $parts[1] + '-' + $parts[2] + $classifier + '.jar'
    }
    $path = Join-Path $libraryRoot $rel
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing local library: $path" }
    $libraries.Add($path)
}
$gameJar = Join-Path $versionDir '1.21.11-0.19.3.jar'
$libraries.Add($gameJar)
$loaderJar = Join-Path $libraryRoot 'net/fabricmc/fabric-loader/0.19.3/fabric-loader-0.19.3.jar'
& javac -encoding UTF-8 --release 21 -cp $loaderJar -d (Join-Path $runPath 'harness-classes') (Join-Path $PSScriptRoot 'SmokeTest.java')
if ($LASTEXITCODE -ne 0) { throw 'Test harness compilation failed' }
$testMetadata = '{"schemaVersion":1,"id":"mhv_smoke_test","version":"1.0.0","environment":"client","entrypoints":{"client":["mhv.test.SmokeTest"]},"depends":{"opsec_mhv":"*"}}'
Set-Content -LiteralPath (Join-Path $runPath 'harness-classes/fabric.mod.json') -Value $testMetadata -Encoding utf8NoBOM
& jar --create --file (Join-Path $runPath 'mods/mhv-smoke-test.jar') -C (Join-Path $runPath 'harness-classes') .
if ($LASTEXITCODE -ne 0) { throw 'Test harness packaging failed' }
Get-ChildItem -LiteralPath (Join-Path $ProfilePath 'mods') -File -Filter '*.jar' | Where-Object {
    $_.Name -notmatch '^opsec' -and
    (($FullPack -and (-not $WithoutAxiom -or $_.Name -notmatch '^Axiom-')) -or
     $_.Name -match '^fabric-api-' -or (-not $WithoutAxiom -and $_.Name -match '^Axiom-'))
} | Copy-Item -Destination (Join-Path $runPath 'mods')
Copy-Item -LiteralPath (Join-Path $projectPath 'versions/1.21.11/build/libs/opsec-mhv1.jar') -Destination (Join-Path $runPath 'mods')
Copy-Item -Path (Join-Path $metaPath 'natives/1.21.11-0.19.3/*') -Destination (Join-Path $runPath 'natives')
Set-Content -LiteralPath (Join-Path $runPath 'options.txt') -Value "onboardAccessibility:false`nskipMultiplayerWarning:true`nmaxFps:30`nrenderDistance:4`nsoundCategory_master:0.0" -Encoding utf8NoBOM
$nativesPath = Join-Path $runPath 'natives'
$axiomExpected = (-not $WithoutAxiom).ToString().ToLowerInvariant()
$launchArgs = @('-Xmx3G', "-Djava.library.path=$nativesPath",
    "-Dorg.lwjgl.system.SharedLibraryExtractPath=$nativesPath",
    "-Dfabric.gameJarPath=$gameJar", "-Dmhv.test.axiom=$axiomExpected",
    '-cp', ($libraries -join ';'), $manifest.mainClass,
    '--username', 'MhvLocalTest', '--version', '1.21.11', '--gameDir', $runPath,
    '--assetsDir', (Join-Path $metaPath 'assets'), '--assetIndex', $manifest.assetIndex.id,
    '--accessToken', '0', '--uuid', '00000000000000000000000000000001', '--userType', 'msa',
    '--width', '854', '--height', '480')
$argsFile = Join-Path $runPath 'java-args.txt'
$launchArgs | ForEach-Object { '"' + ([string]$_).Replace('\','/').Replace('"','\"') + '"' } | Set-Content -LiteralPath $argsFile -Encoding utf8NoBOM
$process = Start-Process -FilePath (Get-Command java).Source -ArgumentList ('@"' + $argsFile + '"') -WorkingDirectory $runPath -WindowStyle Hidden -RedirectStandardOutput (Join-Path $runPath 'stdout.log') -RedirectStandardError (Join-Path $runPath 'stderr.log') -PassThru
[pscustomobject]@{ RunPath=$runPath; ProcessId=$process.Id; Mode=$runName } | ConvertTo-Json
