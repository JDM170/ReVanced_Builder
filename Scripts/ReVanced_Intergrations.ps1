# https://github.com/revanced/revanced-integrations
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-integrations/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
# $Tag = (Invoke-RestMethod @Parameters).tag_name
# $Tag2 = $Tag.replace("v", "")
$URL = (Invoke-RestMethod @Parameters).assets.browser_download_url
$Parameters = @{
    # Uri             = "https://github.com/revanced/revanced-integrations/releases/download/$Tag/revanced-integrations-$Tag2.apk"
    Uri             = $URL
    Outfile         = "Temp\revanced-integrations.apk"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "IntegrationsTag=$IntegrationsTag" >> $env:GITHUB_ENV
