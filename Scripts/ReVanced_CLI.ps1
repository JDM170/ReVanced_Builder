# https://github.com/revanced/revanced-cli
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-cli/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = $apiResult.assets.browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Temp\revanced-cli.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "CLIvtag=$TAG" >> $env:GITHUB_ENV
