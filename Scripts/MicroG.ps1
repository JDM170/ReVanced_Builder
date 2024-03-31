# https://github.com/ReVanced/GmsCore
$Parameters = @{
    Uri             = "https://api.github.com/repos/ReVanced/GmsCore/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = $apiResult.assets.browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Temp\microg.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "MicroGTag=$TAG" >> $env:GITHUB_ENV
