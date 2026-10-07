[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $projectRoot 'MeowPlay\Resources\SoundCatalog.json'
$audioRoot = Join-Path $projectRoot 'MeowPlay\Resources\Audio'
$rightsPath = Join-Path $projectRoot 'Docs\Audio-Rights-Register.csv'
$iconPath = Join-Path $projectRoot 'MeowPlay\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png'
$configurationPath = Join-Path $projectRoot 'MeowPlay\App\AppConfiguration.swift'
$legalSiteRoot = Join-Path $projectRoot 'LegalSite'

$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$rights = @(Import-Csv -LiteralPath $rightsPath)
$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    $errors.Add('Missing 1024x1024 App Icon.')
}

if ((Get-Content -LiteralPath $configurationPath -Raw) -match 'example\.com') {
    $errors.Add('Replace example.com legal and support URLs before release.')
}

$legalSiteText = Get-ChildItem -LiteralPath $legalSiteRoot -Filter '*.html' -File |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }
if (($legalSiteText -join "`n") -match 'MeowPlay publisher|Support email will be added') {
    $errors.Add('Replace the legal-site publisher placeholder and add a monitored support email.')
}

if ($catalog.Count -lt 1) {
    $errors.Add('Catalog must contain at least one audio card.')
}


$duplicateIds = $catalog | Group-Object id | Where-Object Count -gt 1
foreach ($duplicate in $duplicateIds) {
    $errors.Add("Duplicate catalog id: $($duplicate.Name)")
}

$duplicateAssets = $catalog | Group-Object assetName | Where-Object Count -gt 1
foreach ($duplicate in $duplicateAssets) {
    $errors.Add("Duplicate audio asset: $($duplicate.Name)")
}

$duplicateSortOrders = $catalog | Group-Object sortOrder | Where-Object Count -gt 1
foreach ($duplicate in $duplicateSortOrders) {
    $errors.Add("Duplicate sort order: $($duplicate.Name)")
}


if (($catalog | Where-Object tier -eq 'free').Count -lt 1) {
    $errors.Add('Catalog must contain at least one free card.')
}

foreach ($card in $catalog) {
    $assetPath = Join-Path $audioRoot $card.assetName
    if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
        $errors.Add("Missing audio: $($card.assetName)")
    }

    $right = $rights | Where-Object asset_name -eq $card.assetName | Select-Object -First 1
    if ($null -eq $right) {
        $errors.Add("Missing rights record: $($card.assetName)")
    } elseif ($right.commercial_rights_confirmed -notin @('yes', 'confirmed') -or
              $right.editing_allowed -notin @('yes', 'confirmed') -or
              $right.cat_safety_reviewed -notin @('yes', 'confirmed')) {
        $errors.Add("Incomplete rights/safety approval: $($card.assetName)")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Release asset validation passed: catalog audio and rights/safety approvals are complete.'
