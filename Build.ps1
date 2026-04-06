<#
    .SYNOPSIS
    Build ReVanced app using latest components:
      * YouTube (latest supported);
      * ReVanced CLI;
      * ReVanced Patches;
      * ReVanced Integrations;
      * ReVanced microG GmsCore;
      * Azul Zulu.

    .NOTES
    After compiling, microg.apk and compiled revanced.apk will be located in "Script location folder folder\ReVanced"

    .LINKS
    https://github.com/revanced
#>

# Requires -Version 5.1
# Doesn't work on PowerShell 7.2 due it doesn't contains IE parser engine. You have to use a 3rd party module to make it work like it's presented in CI/CD config: AngleSharp

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Host.Version.Major -eq 5)
{
    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $Script:ProgressPreference = "SilentlyContinue"
}

# Download all files to "Script location folder\ReVanced"
$CurrentFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
if (-not (Test-Path -Path "$CurrentFolder\ReVanced"))
{
    New-Item -Path "$CurrentFolder\ReVanced" -ItemType Directory -Force
}

Write-Host "" -ForegroundColor Green
Write-Host "Downloading ReVanced CLI" -ForegroundColor Green
# https://github.com/revanced/revanced-cli
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-cli/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\ReVanced\revanced-cli.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

Write-Host "" -ForegroundColor Green
Write-Host "Downloading ReVanced patches" -ForegroundColor Green
# https://github.com/revanced/revanced-patches
$Parameters = @{
    Uri             = "https://api.revanced.app/v5/patches"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\ReVanced\revanced-patches.rvp"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

Write-Host "" -ForegroundColor Green
Write-Host "Downloading ReVanced GmsCore" -ForegroundColor Green
# https://github.com/ReVanced/GmsCore
$Parameters = @{
    Uri             = "https://api.github.com/repos/ReVanced/GmsCore/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).assets
foreach($url in $URL) {
    if ($url.name.Contains("-hw-")) {
        $url.name = "microg-hw.apk"
    } else {
        $url.name = "microg.apk"
    }
    $Parameters = @{
        Uri             = $url.browser_download_url
        Outfile         = "$CurrentFolder\ReVanced\$($url.name)"
        UseBasicParsing = $true
        Verbose         = $true
    }
    Invoke-RestMethod @Parameters
}

# Sometimes older version of zulu-jdk causes conflict, so remove older version before proceeding.
if (Test-Path -Path "$CurrentFolder\ReVanced\jdk")
{
    Remove-Item -Path "$CurrentFolder\ReVanced\jdk" -Recurse -Force
}

Write-Host "" -ForegroundColor Green
Write-Host "Downloading Azul Zulu" -ForegroundColor Green
# https://github.com/ScoopInstaller/Java/blob/master/bucket/zulu-jdk.json
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/ScoopInstaller/Java/master/bucket/zulu-jdk.json"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).architecture."64bit".url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$CurrentFolder\ReVanced\jdk_windows-x64_bin.zip"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# Expand jdk_windows-x64_bin archive
$Parameters = @{
    Path            = "$CurrentFolder\ReVanced\jdk_windows-x64_bin.zip"
    DestinationPath = "$CurrentFolder\ReVanced\jdk"
    Force           = $true
    Verbose         = $true
}
Expand-Archive @Parameters

Remove-Item -Path "$CurrentFolder\ReVanced\jdk_windows-x64_bin.zip" -Force

# Get the latest supported YouTube version to patch
$patches_list = & "$CurrentFolder\ReVanced\jdk\zulu*win_x64\bin\java.exe" `
-jar "ReVanced\revanced-cli.jar" list-patches `
--packages `
--versions `
--filter-package-name "com.google.android.youtube" `
-p "ReVanced\revanced-patches.rvp" `
-b
$LatestSupported = ([regex]::Matches($patches_list, "\d{2}\.\d{2}\.\d{2}") | ForEach-Object { $_.Value } | Sort-Object -Descending -Unique | Select-Object -First 1).Replace('.', '-')

Write-Host "" -ForegroundColor Green
Write-Host "Download 'nodpi' version from: https://www.apkmirror.com/apk/google-inc/youtube/youtube-$LatestSupported-release/" -ForegroundColor Green
Write-Host "Place the file in the 'ReVanced' folder with the name 'youtube.apk'." -ForegroundColor Green
Write-Host "Press Enter to continue." -ForegroundColor Green
Read-Host

# Let's create patched APK
& "$CurrentFolder\ReVanced\jdk\zulu*win_x64\bin\java.exe" `
-jar "$CurrentFolder\ReVanced\revanced-cli.jar" patch `
--patches "$CurrentFolder\ReVanced\revanced-patches.rvp" `
--disable "Always repeat" `
--disable "Disable auto captions" `
--disable "Hide timestamp" `
--disable "Hide seekbar" `
--purge `
--temporary-files-path "$CurrentFolder\ReVanced\Temp" `
--out "$CurrentFolder\ReVanced\revanced.apk" `
-b `
"$CurrentFolder\ReVanced\youtube.apk"

# Open working directory with builded files
# Invoke-Item -Path "$CurrentFolder\ReVanced"

# Remove temp directory, because cli failed to clean up directory
# Remove-Item -Path "$CurrentFolder\ReVanced\Temp" -Recurse -Force -Confirm:$false

$Files = @(
    # "$CurrentFolder\ReVanced\Temp",
    "$CurrentFolder\ReVanced\jdk",
    "$CurrentFolder\ReVanced\revanced-cli.jar",
    "$CurrentFolder\ReVanced\revanced-patches.rvp",
    "$CurrentFolder\ReVanced\youtube.apk"
)
Remove-Item -Path $Files -Recurse -Force

Write-Warning -Message "Latest available revanced.apk & microg.apk are ready in `"$CurrentFolder\ReVanced`""
