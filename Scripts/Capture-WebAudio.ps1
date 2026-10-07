[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Label,

    [string]$SessionName = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [string]$SourceUrl = '',
    [string]$InputDevice = 'default',

    [ValidateRange(1, 300)]
    [int]$DurationSeconds = 10
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$captureRoot = Join-Path $projectRoot 'codex-cat-audio-stage\CapturedWebAudio'
$safeSessionName = ($SessionName -replace '[^a-zA-Z0-9._-]', '_').Trim('_')
if ([string]::IsNullOrWhiteSpace($safeSessionName)) {
    throw 'SessionName must contain at least one letter or number.'
}

$sessionRoot = Join-Path $captureRoot $safeSessionName
$rawRoot = Join-Path $sessionRoot 'raw'
$manifestPath = Join-Path $sessionRoot 'recording-manifest.csv'
New-Item -ItemType Directory -Path $rawRoot -Force | Out-Null

function Write-Manifest {
    param(
        [string]$Status,
        [string]$RawFile = '',
        [string]$Notes = ''
    )

    [pscustomobject]@{
        raw_filename                = $RawFile
        display_label               = $Label
        source_url                  = $SourceUrl
        source_owner                = 'PENDING_USER_CONFIRMATION'
        recorded_at_utc             = (Get-Date).ToUniversalTime().ToString('o')
        status                      = $Status
        commercial_rights_confirmed = 'pending'
        territory                   = 'worldwide'
        term                        = 'perpetual'
        editing_allowed             = 'pending'
        cat_safety_reviewed         = 'pending'
        notes                       = $Notes
    } | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($null -eq $ffmpeg) {
    Write-Manifest -Status 'blocked_missing_ffmpeg' -Notes 'Install ffmpeg with WASAPI support, then rerun this script.'
    throw "ffmpeg was not found on PATH. The session manifest was saved at $manifestPath."
}

$deviceOutput = (& $ffmpeg.Source -hide_banner -devices 2>&1 | Out-String)
if ($deviceOutput -notmatch '(?im)^\s*[D\.][E\.][A\.][L\.].*wasapi\b|\bwasapi\b') {
    Write-Manifest -Status 'blocked_no_wasapi' -Notes 'This ffmpeg build does not advertise a WASAPI input device; no capture was started.'
    throw "The installed ffmpeg build does not advertise WASAPI input. The session manifest was saved at $manifestPath."
}

$safetyConfirmation = Read-Host '确认猫咪自愿、自然发声，未被惊吓或限制，且没有电视/音乐/第三方背景声？输入 YES 继续'
if ($safetyConfirmation -cne 'YES') {
    Write-Manifest -Status 'cancelled_safety_confirmation' -Notes 'Capture cancelled because the safety confirmation was not provided.'
    Write-Host "已取消录音，清单已保存到 $manifestPath"
    exit 3
}

$rawName = 'raw_{0}.wav' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
$rawPath = Join-Path $rawRoot $rawName
$quotedDevice = '"{0}"' -f ($InputDevice -replace '"', '\"')
$quotedOutput = '"{0}"' -f ($rawPath -replace '"', '\"')
$arguments = "-hide_banner -y -f wasapi -loopback 1 -i $quotedDevice -t $DurationSeconds -vn -acodec pcm_s16le -ar 48000 -ac 2 $quotedOutput"

Write-Host "即将录音 $DurationSeconds 秒。按 Enter 开始；开始后再播放网页音频。"
$start = Read-Host '按 Enter 开始，输入 Q 取消'
if ($start -match '^[qQ]$') {
    Write-Manifest -Status 'cancelled_before_capture' -Notes 'Capture cancelled before ffmpeg started.'
    Write-Host "已取消录音，清单已保存到 $manifestPath"
    exit 3
}

Write-Host "正在录音，输入设备：$InputDevice"
$process = Start-Process -FilePath $ffmpeg.Source -ArgumentList $arguments -PassThru -Wait -NoNewWindow
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $rawPath -PathType Leaf)) {
    Write-Manifest -Status 'capture_failed' -Notes "ffmpeg exited with code $($process.ExitCode)."
    throw "ffmpeg capture failed with exit code $($process.ExitCode). The session manifest was saved at $manifestPath."
}

$fileInfo = Get-Item -LiteralPath $rawPath
if ($fileInfo.Length -le 44) {
    Write-Manifest -Status 'capture_empty' -RawFile $rawName -Notes 'The WAV file was created but contains no usable audio payload.'
    throw "The capture file is empty: $rawPath"
}

Write-Manifest -Status 'captured_pending_review' -RawFile $rawName -Notes 'Review the clip for natural cat behavior and third-party audio before editing or release.'
Write-Host "录音完成：$rawPath"
Write-Host "标签清单：$manifestPath"
