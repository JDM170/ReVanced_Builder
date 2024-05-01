# https://github.com/ReVanced/GmsCore
$Parameters = @{
    Uri             = "https://api.github.com/repos/ReVanced/GmsCore/releases/latest"
    UseBasicParsing = $true
    Verbose         = $true
}
$apiResult = Invoke-RestMethod @Parameters
$TAG = $apiResult.tag_name
foreach($url in $apiResult.assets) {
    if ($url.name.Contains("-hw-")) {
        $url.name = "microg-hw.apk"
    } else {
        $url.name = "microg.apk"
    }
    $Parameters = @{
        Uri             = $url.browser_download_url
        Outfile         = "Temp\$($url.name)"
        UseBasicParsing = $true
        Verbose         = $true
    }
    Invoke-RestMethod @Parameters
}

echo "MicroGTag=$TAG" >> $env:GITHUB_ENV
