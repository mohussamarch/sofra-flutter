param([string]$UsageGatePath)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'de-wikibooks-archive-safety.psm1') -Force
$root = 'E:\work\SOFRA\app'
$lane = Join-Path $root 'data\recipes\source-discovery\de-wikibooks'
$lockPath = Join-Path $lane 'collector.lock'
$checkpointPath = Join-Path $lane 'checkpoint.json'
$indexPath = Join-Path $lane 'index.json'
$lock = $null
$errors = @()
$completed = 0

if (Test-Path -LiteralPath $lockPath) { throw 'German Wikibooks lane lock already exists; inspect its owner before continuing.' }
Assert-DeWikibooksQuota -UsageGatePath $UsageGatePath
$otherWriters = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
    $_.ProcessId -ne $PID -and $_.CommandLine -match '(fetch-de-wikibooks-next-batch\.ps1|extract-de-wikibooks-research\.mjs)'
})
if ($otherWriters.Count -gt 0) { throw 'Another German recipe writer is running; inspect ownership first.' }
$lock = [IO.File]::Open($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
$lockText = "pid=$PID`nstartedAt=$([DateTimeOffset]::UtcNow.ToString('o'))`nsource=de-wikibooks`n"
$lockBytes = [Text.Encoding]::UTF8.GetBytes($lockText)
$lock.Write($lockBytes, 0, $lockBytes.Length)
$lock.Flush()

try {
    $index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
    $continuation = $index.continuationAfterBatch
    if (Test-Path -LiteralPath $checkpointPath) {
        $previous = Get-Content -LiteralPath $checkpointPath -Raw | ConvertFrom-Json
        if ($previous.nextAttemptAt) {
            $gate = [DateTimeOffset]::Parse($previous.nextAttemptAt)
            if ([DateTimeOffset]::UtcNow -lt $gate) { throw "Source backoff remains active until $($previous.nextAttemptAt); no request made." }
        }
        if ($previous.continuationAfterLastSuccess) { $continuation = $previous.continuationAfterLastSuccess }
    }
    if ($null -eq $continuation -or [string]::IsNullOrEmpty($continuation.gapcontinue)) { throw 'No saved German prefix continuation; stopping without a request.' }
    $sequence = Get-DeWikibooksNextArchiveSequence -LanePath $lane
    $checkpoint = [ordered]@{
        source = 'de-wikibooks Kochbuch/'
        batchStartedAt = [DateTimeOffset]::UtcNow.ToString('o')
        state = 'running'
        maxRequestsThisBatch = 3
        successfulRequestsThisBatch = 0
        continuationAfterLastSuccess = $continuation
        lastArchive = $null
        lastResponseSha256 = $null
        nextAttemptAt = $null
        errors = @()
    }
    $checkpoint | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $checkpointPath -Encoding utf8

    for ($i = 0; $i -lt 3; $i++) {
        if ($null -eq $continuation) { break }
        if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) { throw 'Collector lock disappeared before a source request.' }
        try { Assert-DeWikibooksQuota -UsageGatePath $UsageGatePath } catch {
            $checkpoint.state = 'quota-evidence-stop'
            $checkpoint | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $checkpointPath -Encoding utf8
            throw
        }
        $gap = [Uri]::EscapeDataString([string]$continuation.gapcontinue)
        $continueValue = [Uri]::EscapeDataString([string]$continuation.'continue')
        $url = 'https://de.wikibooks.org/w/api.php?action=query&generator=allpages&gapnamespace=0&gapprefix=Kochbuch%2F&gaplimit=50&prop=info%7Crevisions&inprop=url&rvprop=ids%7Ctimestamp%7Cuser%7Ccontent&rvslots=main&format=json&formatversion=2&gapcontinue=' + $gap + '&continue=' + $continueValue
        $stem = '{0:D2}-pages' -f $sequence
        $bodyPath = Join-Path $lane ($stem + '.body')
        $archivePath = Join-Path $lane ($stem + '.json')
        if ((Test-Path -LiteralPath $bodyPath) -or (Test-Path -LiteralPath $archivePath)) { throw "Archive collision at $stem; no request made." }
        $retrievedAt = [DateTimeOffset]::UtcNow
        try {
            $temporaryBody = Join-Path $lane ('.response-' + [Guid]::NewGuid().ToString('N') + '.tmp')
            $response = Invoke-WebRequest -Uri $url -Headers @{ 'User-Agent' = 'SofraRecipeResearch/1.0 (research-only; source attribution preserved)' } -TimeoutSec 60 -OutFile $temporaryBody
            [IO.File]::Move($temporaryBody, $bodyPath)
            $bytes = [IO.File]::ReadAllBytes($bodyPath)
            $body = [Text.Encoding]::UTF8.GetString($bytes)
            $bodyHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
            $data = $body | ConvertFrom-Json
            if ($data.error -or -not $data.query.pages -or @($data.query.pages).Count -eq 0) { throw 'API response had an error or no source pages; stopping this batch.' }
            $entry = [ordered]@{
                requestUrl = $url
                continuationIn = $continuation
                retrievedAt = $retrievedAt.ToString('o')
                httpStatus = 200
                bodySha256 = $bodyHash
                bodyBase64 = [Convert]::ToBase64String($bytes)
                responseBody = $body
            }
            $entryBytes = [Text.Encoding]::UTF8.GetBytes(($entry | ConvertTo-Json -Depth 8))
            Write-DeWikibooksArchiveNoClobber -Path $archivePath -Bytes $entryBytes
            $continuation = $data.continue
            $completed++
            $sequence++
            $checkpoint.successfulRequestsThisBatch = $completed
            $checkpoint.continuationAfterLastSuccess = $continuation
            $checkpoint.lastArchive = Split-Path -Leaf $archivePath
            $checkpoint.lastResponseSha256 = $bodyHash
            $checkpoint.state = if ($null -eq $continuation) { 'source-exhausted' } else { 'ready-for-next-resume' }
            $checkpoint | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $checkpointPath -Encoding utf8
            Write-Output "saved=$($entry.requestUrl) status=200 pages=$(@($data.query.pages).Count) sha256=$bodyHash next=$($null -ne $continuation)"
            if ($null -ne $continuation -and $i -lt 2) { Start-Sleep -Seconds 2 }
        } catch {
            $statusCode = $null
            $retryAfter = $null
            try { $statusCode = [int]$_.Exception.Response.StatusCode } catch { }
            try { $retryAfter = [string]$_.Exception.Response.Headers['Retry-After'] } catch { }
            $retrySeconds = 600
            if ($retryAfter -match '^\d+$') { $retrySeconds = [Math]::Max(600, [int]$retryAfter) }
            elseif ($retryAfter) { try { $retryTime = [DateTimeOffset]::Parse($retryAfter); $retrySeconds = [Math]::Max(600, [int][Math]::Ceiling(($retryTime - [DateTimeOffset]::UtcNow).TotalSeconds)) } catch { } }
            $gate = [DateTimeOffset]::UtcNow.AddSeconds($retrySeconds)
            $failureArchive = $null
            if (Test-Path -LiteralPath $bodyPath -PathType Leaf) {
                $failureBytes = [IO.File]::ReadAllBytes($bodyPath)
                $failureBody = [Text.Encoding]::UTF8.GetString($failureBytes)
                $failureHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($failureBytes)).ToLowerInvariant()
                $failureArchive = [ordered]@{
                    requestUrl = $url
                    retrievedAt = $retrievedAt.ToString('o')
                    httpStatus = $statusCode
                    retryAfter = $retryAfter
                    bodySha256 = $failureHash
                    bodyBase64 = [Convert]::ToBase64String($failureBytes)
                    responseBody = $failureBody
                }
                $failurePath = Join-Path $lane ($stem + '-failure.json')
                $failureBytesJson = [Text.Encoding]::UTF8.GetBytes(($failureArchive | ConvertTo-Json -Depth 6))
                Write-DeWikibooksArchiveNoClobber -Path $failurePath -Bytes $failureBytesJson
            }
            $errors += [ordered]@{ requestUrl = $url; occurredAt = [DateTimeOffset]::UtcNow.ToString('o'); httpStatus = $statusCode; retryAfter = $retryAfter; message = $_.Exception.Message }
            $checkpoint.errors = $errors
            $checkpoint.state = 'source-error-stop'
            $checkpoint.nextAttemptAt = $gate.ToString('o')
            $checkpoint.continuationAfterLastSuccess = $continuation
            $checkpoint | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $checkpointPath -Encoding utf8
            throw "Source request failed; no retry or alternate path. Backoff until $($checkpoint.nextAttemptAt). $($_.Exception.Message)"
        }
    }
    Write-Output "batchSuccesses=$completed nextCursor=$($null -ne $continuation)"
} finally {
    if ($lock) { $lock.Dispose() }
    if (Test-Path -LiteralPath $lockPath) { Remove-Item -LiteralPath $lockPath -Force }
}
