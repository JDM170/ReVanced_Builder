<#
    .SYNOPSIS
    Build ReVanced app using latest components:
      * YouTube (latest supported);
      * ReVanced CLI;
      * ReVanced Patches;
      * ReVanced Integrations;
      * microG GmsCore;
      * Azul Zulu.

    .NOTES
    After compiling, microg.apk and compiled revanced.apk will be located in "Script location folder folder\ReVanced"

    .LINKS
    https://github.com/revanced
#>

# Requires -Version 5.1
# Doesn't work on PowerShell 7.2 due it doesn't contains IE parser engine. You have to use a 3rd party module to make it work like it's presented in CI/CD config: AngleSharp

# Download all files to "Script location folder\ReVanced"
$WorkingFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
if (-not (Test-Path -Path "$WorkingFolder\ReVanced"))
{
    New-Item -Path "$WorkingFolder\ReVanced" -ItemType Directory -Force
}

# Get latest supported YouTube client version via ReVanced JSON
# It will let us to download always latest YouTube apk supported by ReVanced team
# https://github.com/revanced/revanced-patches/blob/main/patches.json
$Parameters = @{
    Uri             = "https://raw.githubusercontent.com/revanced/revanced-patches/main/patches.json"
    UseBasicParsing = $true
}
$JSON = Invoke-RestMethod @Parameters
$versions = ($JSON | Where-Object -FilterScript {$_.compatiblePackages.name -eq "com.google.android.youtube"}).compatiblePackages.versions
$LatestSupported = $versions | Sort-Object -Descending -Unique | Select-Object -First 1
$LatestSupported = $LatestSupported.replace(".", "-")

# Get unique key to generate direct link
# https://www.apkmirror.com/apk/google-inc/youtube/
$apkMirrorLink = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupported)-release/"
$Parameters = @{
    Uri             = $apkMirrorLink
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
# Trying to find correct APK link (not BUNDLE)
$nameProp = $Request.ParsedHtml.getElementsByClassName("table-row headerFont")
foreach ($element in $nameProp)
{
    foreach ($child in $element.children)
    {
        if ($child.innerText -eq "nodpi")
        {
            $apkPackageLink = ($element.getElementsByTagName("a") | Select-Object -First 1).nameProp
            break
        }
    }
}
$apkMirrorLink += $apkPackageLink # actual APK link (not BUNDLE)

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
$URL = (Invoke-RestMethod @Parameters).assets.browser_download_url
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
$URL = (Invoke-RestMethod @Parameters).assets.browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\revanced-integrations.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

# https://github.com/TeamVanced/VancedMicroG
$Parameters = @{
    Uri             = "https://api.github.com/repos/TeamVanced/VancedMicroG/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-RestMethod @Parameters).assets.browser_download_url
$Parameters = @{
    Uri             = $URL
    Outfile         = "$WorkingFolder\ReVanced\microg.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

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

# https://github.com/revanced/revanced-patches
& "$WorkingFolder\ReVanced\jdk\zulu*win_x64\bin\java.exe" `
-jar "$WorkingFolder\ReVanced\revanced-cli.jar" `
--apk "$WorkingFolder\ReVanced\youtube.apk" `
--bundle "$WorkingFolder\ReVanced\revanced-patches.jar" `
--merge "$WorkingFolder\ReVanced\revanced-integrations.apk" `
--exclude hide-time-and-seekbar `
--exclude always-autorepeat `
--exclude hide-captions-button `
--exclude disable-fullscreen-panels `
--exclude old-quality-layout `
--clean `
--temp-dir "$WorkingFolder\ReVanced\Temp" `
--out "$WorkingFolder\ReVanced\revanced.apk"

# Open working directory with builded files
# Invoke-Item -Path "$WorkingFolder\ReVanced"

# Remove temp directory, because cli failed to clean up directory
# Remove-Item -Path "$WorkingFolder\ReVanced\Temp" -Recurse -Force -Confirm:$false

Write-Warning -Message "Latest available revanced.apk & microg.apk are ready in `"$WorkingFolder\ReVanced`""
