$ErrorActionPreference = 'Stop'
$module = Join-Path $PSScriptRoot 'de-wikibooks-archive-safety.psm1'
Import-Module $module -Force
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ('de-wikibooks-archive-test-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($sandbox) | Out-Null
try {
    [IO.File]::WriteAllText((Join-Path $sandbox '06-pages.json'), '{}')
    [IO.File]::WriteAllText((Join-Path $sandbox '08-prefix-recovery-new.json'), '{}')
    if ((Get-DeWikibooksNextArchiveSequence -LanePath $sandbox) -ne 9) { throw 'Sequence selection did not include every approved archive filename.' }

    [IO.File]::WriteAllText((Join-Path $sandbox '100-pages.json'), '{}')
    if ((Get-DeWikibooksNextArchiveSequence -LanePath $sandbox) -ne 101) { throw 'Archive sequence failed above 99.' }
    [IO.File]::WriteAllText((Join-Path $sandbox '102-pages.body'), 'failed-response')
    [IO.File]::WriteAllText((Join-Path $sandbox '104-pages-failure.json'), '{}')
    if ((Get-DeWikibooksNextArchiveSequence -LanePath $sandbox) -ne 105) { throw 'Failed response reservations were ignored.' }
    $gate = Join-Path $sandbox 'usage.json'
    function Write-TestUsage($ordinary, $primary, $weekly, $offset) {
        @{ ordinaryUsageAllowed=$ordinary; primary=$primary; weekly=$weekly; checkedAt=[DateTimeOffset]::UtcNow.AddSeconds($offset).ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath $gate -Encoding utf8
    }
    Write-TestUsage $true 0 80 0
    Assert-DeWikibooksQuota -UsageGatePath $gate
    $rejected=0
    foreach ($case in @(@($false,0,80,0),@($true,90,80,0),@($true,0,90,0),@($true,0,80,-60),@($true,0,80,60),@($true,'unknown',80,0),@($true,0,([double]::PositiveInfinity),0))) {
        Write-TestUsage $case[0] $case[1] $case[2] $case[3]
        $blocked=$false
        try { Assert-DeWikibooksQuota -UsageGatePath $gate } catch { $blocked=$true }
        if (-not $blocked) { throw 'Invalid quota evidence was accepted.' }
        $rejected++
    }
    $blocked=$false
    try { Assert-DeWikibooksQuota -UsageGatePath (Join-Path $sandbox 'absent.json') } catch { $blocked=$true }
    if (-not $blocked) { throw 'Missing quota evidence was accepted.' }
    $target = Join-Path $sandbox '09-pages.body'
    $bytes = [Text.Encoding]::UTF8.GetBytes('fixed-bytes')
    Write-DeWikibooksArchiveNoClobber -Path $target -Bytes $bytes
    $firstHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    $collisionRejected = $false
    try { Write-DeWikibooksArchiveNoClobber -Path $target -Bytes ([Text.Encoding]::UTF8.GetBytes('overwrite')) }
    catch [IO.IOException] { $collisionRejected = $true }
    if (-not $collisionRejected) { throw 'A colliding archive write was not rejected.' }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $firstHash) { throw 'A collision changed existing archive bytes.' }
    Write-Output "archive-safety=passed collision-rejected=1 existing-bytes-preserved=1 quota-invalid-rejected=$($rejected+1) sequence-101=passed failure-reservation-105=passed"
} finally {
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolved=[IO.Path]::GetFullPath($sandbox)
    if (-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notmatch '^de-wikibooks-archive-test-[a-f0-9]{32}$') { throw 'Unsafe temporary cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
    Remove-Module de-wikibooks-archive-safety -ErrorAction SilentlyContinue
}
