$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & .\gradlew.bat :1.21.11:build --console=plain
    if ($LASTEXITCODE -ne 0) { throw 'OpSec — mhv1 build failed' }
    New-Item -ItemType Directory -Path dist -Force | Out-Null
    Copy-Item -LiteralPath 'versions/1.21.11/build/libs/opsec-mhv1.jar' -Destination 'dist/opsec-mhv1.jar'
    $hash = (Get-FileHash -LiteralPath 'dist/opsec-mhv1.jar' -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath 'dist/opsec-mhv1.jar.sha256' -Value "$hash  opsec-mhv1.jar" -Encoding ascii
} finally {
    Pop-Location
}
