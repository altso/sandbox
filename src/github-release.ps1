$PSVersionTable.PSVersion

$username = "81b00ad1ab7d38804f4cc69002bff2db0af1e3ae"
$password = ""

$hash = (gci env:BUILD_VCS_NUMBER).Value
$version = (gci env:BUILD_NUMBER).Value
$name = ("v{0}" -f $version)

$json = @{ tag_name = $name; target_commitish = $hash; name = $name; body = ("Automatic release {0}" -f $name); prerelease = $true } | ConvertTo-Json

$authorization = @{ Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))) }
$response = Invoke-RestMethod "https://api.github.com/repos/altso/sandbox/releases" -Method Post -Headers $authorization -ContentType "application/json" -Body $json

[array]$artifacts = @("src")
$artifacts.GetType()
$artifacts.Length
$artifacts[0]

foreach ($artifact in $artifacts)
{
    Write-Host "foreach #1"
    $files = gci $artifact | where { ! $_.PSIsContainer }
    foreach ($file in $files)
    {
        Write-Host "foreach #2"
        $uploadUrl = $response.upload_url -replace "\{\?name\}", ("?name={0}" -f $file.Name)
        Write-Host ("Uploading {0} to {1}..." -f $file.FullName, $uploadUrl)
        Invoke-RestMethod $uploadUrl -Method Post -InFile $file.FullName -Headers $authorization -ContentType "application/octet-stream"
    }
}
