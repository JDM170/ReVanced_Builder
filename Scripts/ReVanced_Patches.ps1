# https://github.com/revanced/revanced-patches
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-patches/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$URL = ($apiResult.assets | Where-Object -FilterScript {$_.content_type -eq "text/plain"}).browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    Uri             = $URL
    Outfile         = "Temp\revanced-patches.rvp"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "Patchesvtag=$TAG" >> $env:GITHUB_ENV
