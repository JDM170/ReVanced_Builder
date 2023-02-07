# https://github.com/revanced/revanced-integrations
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-integrations/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = $apiResult.assets.browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Temp\revanced-integrations.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "IntegrationsTag=$TAG" >> $env:GITHUB_ENV
