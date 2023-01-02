# https://github.com/revanced/revanced-integrations
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-integrations/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$IntegrationsTag = $apiResult.tag_name.replace("v", "")
$Parameters = @{
    # Uri             = "https://github.com/revanced/revanced-integrations/releases/download/$Tag/revanced-integrations-$Tag2.apk"
    Uri             = $apiResult.assets.browser_download_url
    Outfile         = "Temp\revanced-integrations.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "IntegrationsTag=$IntegrationsTag" >> $env:GITHUB_ENV
