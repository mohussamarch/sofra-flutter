Set-StrictMode -Version Latest

function Get-DeWikibooksNextArchiveSequence {
    param([Parameter(Mandatory)][string]$LanePath)
    $numbers = @(Get-ChildItem -LiteralPath $LanePath -File | Where-Object {
        $_.Name -match '^(\d{2,})-(?:pages|prefix-recovery-new)(?:-failure)?\.(?:json|body)$'
    } | ForEach-Object { [int]$Matches[1] })
    if ($numbers.Count -eq 0) { return 1 }
    return ([long]($numbers | Measure-Object -Maximum).Maximum + 1)
}

function Write-DeWikibooksArchiveNoClobber {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][byte[]]$Bytes
    )
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush()
    } finally {
        $stream.Dispose()
    }
}


function Assert-DeWikibooksQuota {
    param([string]$UsageGatePath)
    if (-not $UsageGatePath -or -not (Test-Path -LiteralPath $UsageGatePath -PathType Leaf)) { throw 'Fresh actual usage evidence required; no request allowed.' }
    $q = Get-Content -LiteralPath $UsageGatePath -Raw | ConvertFrom-Json
    if ($q.ordinaryUsageAllowed -isnot [bool] -or -not $q.ordinaryUsageAllowed) { throw 'Ordinary usage is unavailable.' }
    foreach ($value in @($q.primary, $q.weekly)) {
        if ($value -isnot [ValueType] -or $value -is [bool] -or [double]::IsNaN([double]$value) -or $value -lt 0 -or $value -ge 90) { throw 'Unknown usage or quota reserve reached.' }
    }
    if (-not $q.checkedAt) { throw 'Missing usage timestamp.' }
    $age = ([DateTimeOffset]::UtcNow - [DateTimeOffset]$q.checkedAt).TotalSeconds
    if ($age -lt -5 -or $age -gt 30) { throw 'Usage evidence is stale or in the future.' }
}

Export-ModuleMember -Function Get-DeWikibooksNextArchiveSequence, Write-DeWikibooksArchiveNoClobber, Assert-DeWikibooksQuota
