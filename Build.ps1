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
$WorkingFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
if (-not (Test-Path -Path "$WorkingFolder\ReVanced"))
{
    New-Item -Path "$WorkingFolder\ReVanced" -ItemType Directory -Force
}

# Get the latest supported YouTube version to patch
# https://api.revanced.app/docs/swagger
$Parameters = @{
    Uri             = "https://api.revanced.app/v2/patches/latest"
    UseBasicParsing = $true
}
$JSON = (Invoke-RestMethod @Parameters).patches
$versions = ($JSON | Where-Object -FilterScript {$_.compatiblePackages.name -eq "com.google.android.youtube"}).compatiblePackages.versions
$LatestSupported = $versions | Sort-Object -Descending -Unique | Select-Object -First 1

# We need a NON-bundle version
<#
# https://apkpure.net/ru/youtube/com.google.android.youtube/versions
$Parameters = @{
    Uri             = "https://apkpure.net/youtube/com.google.android.youtube/download/$($LatestSupported)"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-Webrequest @Parameters).Links.href | Where-Object -FilterScript {$_ -match "APK/com.google.android.youtube"} | Select-Object -Index 1

$Parameters = @{
    Uri             = $URL
    OutFile         = "$WorkingFolder\ReVanced\youtube.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-Webrequest @Parameters
#>

# https://www.apkmirror.com/apk/google-inc/youtube/
$apkMirrorLink = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupported)-release/"
$Parameters = @{
    Uri             = $apkMirrorLink
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
$Request.ParsedHtml.getElementsByClassName("table-row headerFont") | ForEach-Object -Process {
    foreach ($child in $_.children)
    {
        if ($child.innerText -eq "nodpi")
        {
            $apkPackageLink = ($_.getElementsByTagName("a") | Select-Object -First 1).nameProp
            break
        }
    }
}
$apkMirrorLink += $apkPackageLink # actual APK link (not BUNDLE)

# Get unique key to generate direct link
$Parameters = @{
    Uri             = $apkMirrorLink
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
$nameProp = $Request.ParsedHtml.getElementsByClassName("accent_bg btn btn-flat downloadButton") | ForEach-Object -Process {$_.nameProp}

$Parameters = @{
    Uri = $apkMirrorLink + "/download/$($nameProp)"
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$URL_Part = ((Invoke-Webrequest @Parameters).Links | Where-Object -FilterScript {$_.innerHTML -eq "here"}).href
# Replace "&amp;" with "&" to make it work
$URL_Part = $URL_Part.Replace("&amp;", "&")

# Finally, get the real link
$Parameters = @{
    Uri             = "https://www.apkmirror.com$URL_Part"
    OutFile         = "$WorkingFolder\ReVanced\youtube.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-Webrequest @Parameters

# https://github.com/revanced/revanced-cli
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-cli/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\revanced-cli.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/revanced/revanced-patches
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-patches/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\revanced-patches.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/revanced/revanced-integrations
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-integrations/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = ((Invoke-RestMethod @Parameters).assets | Where-Object -FilterScript {$_.content_type -eq "application/vnd.android.package-archive"}).browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\revanced-integrations.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

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
        Outfile         = "$WorkingFolder\ReVanced\$($url.name)"
        UseBasicParsing = $true
        Verbose         = $true
    }
    Invoke-RestMethod @Parameters
}

# Sometimes older version of zulu-jdk causes conflict, so remove older version before proceeding.
if (Test-Path -Path "$WorkingFolder\ReVanced\jdk")
{
    Remove-Item -Path "$WorkingFolder\ReVanced\jdk" -Recurse -Force
}

# https://github.com/ScoopInstaller/Java/blob/master/bucket/zulu-jdk.json
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/ScoopInstaller/Java/master/bucket/zulu-jdk.json"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).architecture."64bit".url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\jdk_windows-x64_bin.zip"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# Expand jdk_windows-x64_bin archive
$Parameters = @{
    Path            = "$WorkingFolder\ReVanced\jdk_windows-x64_bin.zip"
    DestinationPath = "$WorkingFolder\ReVanced\jdk"
    Force           = $true
    Verbose         = $true
}
Expand-Archive @Parameters

Remove-Item -Path "$WorkingFolder\ReVanced\jdk_windows-x64_bin.zip" -Force

# Let's create patched APK
& "$WorkingFolder\ReVanced\jdk\zulu*win_x64\bin\java.exe" `
-jar "$WorkingFolder\ReVanced\revanced-cli.jar" patch `
--patch-bundle "$WorkingFolder\ReVanced\revanced-patches.jar" `
--merge "$WorkingFolder\ReVanced\revanced-integrations.apk" `
--exclude "Always repeat" `
--exclude "Hide captions button" `
--exclude "Hide timestamp" `
--exclude "Hide seekbar" `
--purge `
--temporary-files-path "$WorkingFolder\ReVanced\Temp" `
--out "$WorkingFolder\ReVanced\revanced.apk" `
"$WorkingFolder\ReVanced\youtube.apk"

# Open working directory with builded files
# Invoke-Item -Path "$WorkingFolder\ReVanced"

# Remove temp directory, because cli failed to clean up directory
# Remove-Item -Path "$WorkingFolder\ReVanced\Temp" -Recurse -Force -Confirm:$false

Write-Warning -Message "Latest available revanced.apk & microg.apk are ready in `"$WorkingFolder\ReVanced`""
