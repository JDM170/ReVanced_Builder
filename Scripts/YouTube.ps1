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
$LatestSupportedYT = $LatestSupported.replace(".", "-")

$AngleSharpAssemblyPath = (Get-ChildItem -Path (Split-Path -Path (Get-Package -Name AngleSharp).Source) -Filter "*.dll" -Recurse | Where-Object -FilterScript {$_ -match "standard"} | Select-Object -Last 1).FullName
Add-Type -Path $AngleSharpAssemblyPath

# Create parser object
$angleparser = New-Object -TypeName AngleSharp.Html.Parser.HtmlParser

# Try to find correct NON-Bundle version
$Parameters = @{
    Uri             = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-android-apk-download/"
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$URLParse = (Invoke-Webrequest @Parameters).Links.outerHTML | Where-Object -FilterScript {$_ -like "*YouTube $($LatestSupportedYT) (nodpi)*"}
# Check if variable contains a data
if ($URLParse)
{
    $URL = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-android-apk-download/"
}
else
{
    $URL = "https://www.apkmirror.com/apk/google-inc/youtube/youtube-$($LatestSupportedYT)-release/youtube-$($LatestSupportedYT)-2-android-apk-download/"
}

# Get unique key to generate direct link
$Parameters = @{
    Uri             = $URL
    UseBasicParsing = $false # Disabled
    Verbose         = $true
}
$Request = Invoke-Webrequest @Parameters
$Parsed = $angleparser.ParseDocument($Request.Content)
$Key = $Parsed.All | Where-Object -FilterScript {$_.ClassName -match "accent_bg btn btn-flat downloadButton"} | ForEach-Object -Process {$_.Search}

$Parameters = @{
    Uri             = "$($URL)/download/$($Key)"
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
