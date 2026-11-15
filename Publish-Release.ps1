#Requires -Version 7.3
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$AppRoot,
    [switch]$ForceUpdate,
    [string]$MinimumVersion='1.0.0',
    [string]$Notes=''
)
$ErrorActionPreference='Stop'
$app=[IO.Path]::GetFullPath($AppRoot)
$site=[IO.Path]::GetFullPath($PSScriptRoot)
$receipt=Get-Content -LiteralPath (Join-Path $app 'out/validation.json') -Raw | ConvertFrom-Json
if($receipt.pkg_integrity -ne 'passed' -or $receipt.title_id -ne 'SCBY00001' -or
    $receipt.package_version -notmatch '\A\d{2}\.\d{2}\z' -or
    $receipt.package_sha256 -notmatch '\A[0-9a-fA-F]{64}\z') { throw 'Build receipt is invalid.' }
$prefix=$receipt.package_sha256.Substring(0,12).ToLowerInvariant()
$leaf="Scooby-PS4-Manager-$($receipt.package_version)-$prefix.pkg"
$bundle="Scooby-Manager-$($receipt.package_version)-$prefix-relink.zip"
$bundleSource=Join-Path $app "out/$bundle"
if(-not(Test-Path -LiteralPath $bundleSource -PathType Leaf)) { throw 'Build the matching relink companion first.' }
if($receipt.relink_companion -cne $bundle) { throw 'Build receipt does not identify this matching relink companion.' }
$url="https://scoobyp98.github.io/scooby-manager-update/packages/$leaf"
$manifest=Join-Path $site 'version.json'
$packages=Join-Path $site 'packages'
if((Get-Item -LiteralPath $site -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked publication directory refused.' }
if((Test-Path -LiteralPath $packages) -and ((Get-Item -LiteralPath $packages -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked packages directory refused.' }
New-Item -ItemType Directory -Path $packages -Force | Out-Null
function Test-Companion([string]$Path) {
    $zip=[IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entries=@($zip.Entries | Where-Object FullName -CEQ 'relink.json')
        if($entries.Count -ne 1 -or $entries[0].Length -lt 2 -or $entries[0].Length -gt 65536) { throw 'Relink recipe is missing, duplicate or oversized.' }
        $reader=[IO.StreamReader]::new($entries[0].Open(),[Text.UTF8Encoding]::new($false,$true))
        try { $recipe=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if($recipe.format -ne 1 -or $recipe.version -cne $receipt.version -or $recipe.package_version -cne $receipt.package_version -or $recipe.package_sha256 -ine $receipt.package_sha256) { throw 'Relink recipe disagrees with the validated release.' }
    } finally { $zip.Dispose() }
}
Test-Companion $bundleSource
$bundleHash=(Get-FileHash -LiteralPath $bundleSource -Algorithm SHA256).Hash
foreach($pair in @(@((Join-Path $app 'out/Scooby-PS4-Manager.pkg'),$leaf,$receipt.package_sha256),@($bundleSource,$bundle,$bundleHash))) {
    $target=Join-Path $packages $pair[1]
    if(Test-Path -LiteralPath $target) {
        $item=Get-Item -LiteralPath $target -Force
        if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ine $pair[2]) { throw "Existing release differs: $target" }
    } else {
        $part=$target+'.part-'+[Guid]::NewGuid().ToString('N')
        $inputFile=[IO.File]::Open($pair[0],[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        try {
            $outputFile=[IO.File]::Open($part,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try { $inputFile.CopyTo($outputFile); $outputFile.Flush($true) } finally { $outputFile.Dispose() }
        } finally { $inputFile.Dispose() }
        if((Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash -ine $pair[2]) { throw 'Release copy verification failed; manifest remains unchanged.' }
        [IO.File]::Move($part,$target)
    }
    if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ine $pair[2]) { throw 'Release copy verification failed.' }
}
Test-Companion (Join-Path $packages $bundle)
# Publish the pointer last, after both immutable artifacts are complete and
# hash-checked. The generator verifies the copied PKG's full metadata/hash and
# uses its existing atomic manifest writer; a failed copy cannot advance it.
& (Join-Path $app 'scripts/New-UpdateManifest.ps1') -PackageUrl $url -PackagePath (Join-Path $packages $leaf) -OutputPath $manifest -ForceUpdate:$ForceUpdate -MinimumVersion $MinimumVersion -Notes $Notes | Out-Null
Write-Host "Prepared $($receipt.version) / PKG $($receipt.package_version). Review and publish this repository."
