param([Parameter(Mandatory=$true, HelpMessage="Increments revision number in manifest file")][string] $loc)

# Resolve candidate paths relative to provided location
[string[]] $manifestCandidates = @(
    (Join-Path $loc "..\ClangPowerTools\source.extension.vsixmanifest"),
    (Join-Path $loc "ClangPowerTools\source.extension.vsixmanifest"),
    (Join-Path $loc "..\source.extension.vsixmanifest"),
    (Join-Path $loc "source.extension.vsixmanifest")
)

[string[]] $aipCandidates = @(
    (Join-Path $loc "..\ClangPowerTools.aip"),
    (Join-Path $loc "ClangPowerTools.aip")
)

$manifestPath = $manifestCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$aipPath      = $aipCandidates      | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $manifestPath)
{
    Write-Error "Invalid manifest file path"
    exit 1
}

# Load VSIX manifest
[xml] $data = Get-Content -LiteralPath $manifestPath
[Version] $currentVersion = [Version]::new($data.PackageManifest.Metadata.Identity.Version.ToString())

# Compute new version by incrementing the Revision component (create it if missing)
[Version] $newVersion = $null
if ($currentVersion.Revision -ge 0) {
    $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build, ($currentVersion.Revision + 1))
}
else {
    # If Revision is missing, start at .1 (keep existing Build)
    $newVersion = [Version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build, 1)
}

# Update manifest
$data.PackageManifest.Metadata.Identity.Version = $newVersion.ToString()
$data.Save($manifestPath)

# Optionally update .aip if present
if ($aipPath)
{
    [xml] $aipData = Get-Content -LiteralPath $aipPath
    $aipData.DOCUMENT.COMPONENT[0].ROW[7].Value = $newVersion.ToString()
    $aipData.Save($aipPath)
    $resultData = Get-Content $aipPath -Encoding utf8
    $result = $resultData -replace " />", "/>"
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
    [System.IO.File]::WriteAllLines($aipPath, $result, $Utf8NoBomEncoding)
}


