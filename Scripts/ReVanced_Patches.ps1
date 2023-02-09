# https://github.com/revanced/revanced-patches
$Parameters = @{
    Uri             = "https://api.github.com/repos/revanced/revanced-patches/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
# $Patchesvtag = (Invoke-RestMethod @Parameters).tag_name
# $Patchestag = $Patchesvtag.replace("v", "")
$apiResult = Invoke-RestMethod @Parameters
$URL = ($apiResult.assets | Where-Object -FilterScript {$_.content_type -eq "application/java-archive"}).browser_download_url
$TAG = $apiResult.tag_name
$Parameters = @{
    # Uri             = "https://github.com/revanced/revanced-patches/releases/download/$Patchesvtag/revanced-patches-$Patchestag.jar"
    Uri             = $URL
    Outfile         = "Temp\revanced-patches.jar"
    UseBasicParsing = $true
    Verbose         = $true
}
Invoke-RestMethod @Parameters

echo "Patchesvtag=$TAG" >> $env:GITHUB_ENV
