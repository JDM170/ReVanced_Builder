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
# https://apkpure.net/ru/youtube/com.google.android.youtube/versions
<#
$Parameters = @{
    Uri             = "https://apkpure.net/youtube/com.google.android.youtube/download/$($LatestSupported)"
    UseBasicParsing = $true
    Verbose         = $true
}
$URL = (Invoke-Webrequest @Parameters).Links.href | Where-Object -FilterScript {$_ -match "APK/com.google.android.youtube"} | Select-Object -Index 1

$Parameters = @{
    Uri             = $URL
    OutFile         = "Temp\youtube.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-Webrequest @Parameters
#>

$AngleSharpAssemblyPath = (Get-ChildItem -Path (Split-Path -Path (Get-Package -Name AngleSharp).Source) -Filter "*.dll" -Recurse | Where-Object -FilterScript {$_ -match "standard"} | Select-Object -Last 1).FullName
Add-Type -Path $AngleSharpAssemblyPath

# Create parser object
$angleparser = New-Object -TypeName AngleSharp.Html.Parser.HtmlParser

# Trying to find correct APK link (not BUNDLE)
# https://www.apkmirror.com/apk/google-inc/youtube/
$apkMirrorLink = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupported)-release/"
$Parameters = @{
    Uri             = $apkMirrorLink
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
$Parsed = $angleparser.ParseDocument($Request.Content)
$Parsed.All | Where-Object -FilterScript {$_.ClassName -match "table-row headerFont"} | ForEach-Object -Process {
    foreach($child in $_.children)
    {
        if ($child.InnerHtml -eq "nodpi")
        {
            $apkPackageLink = (($_.getElementsByTagName("a") | Select-Object -First 1).Href).Substring(57)
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
$Parsed = $angleparser.ParseDocument($Request.Content)
$Key = $Parsed.All | Where-Object -FilterScript {$_.ClassName -match "accent_bg btn btn-flat downloadButton"} | ForEach-Object -Process {$_.Search}

$Parameters = @{
    Uri             = $apkMirrorLink + "download/$($Key)"
    UseBasicParsing = $true
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
$Parsed = $angleparser.ParseDocument($Request.Content)
$Key = ($Parsed.All | Where-Object -FilterScript { $_.InnerHtml -eq "here" }).Search

# Finally, get the real link
$Parameters = @{
    Uri             = "https://www.apkmirror.com/wp-content/themes/APKMirror/download.php$Key"
    OutFile         = "Temp\youtube.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-Webrequest @Parameters

echo "LatestSupportedYT=$LatestSupported" >> $env:GITHUB_ENV
