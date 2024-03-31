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

echo "LatestSupportedYT=$LatestSupported" >> $env:GITHUB_ENV
