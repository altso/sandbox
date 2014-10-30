Param([string]$username, [string]$password)

$hash = (gci env:BUILD_VCS_NUMBER).Value
$version = (gci env:BUILD_NUMBER).Value
$name = ("v{0}" -f $version)

$json = @{ tag_name = $name; target_commitish = $hash; name = $name; body = ("Automatic release {0}" -f $name); prerelease = $true } | ConvertTo-Json

$authorization = @{ Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))) }
$response = Invoke-RestMethod "https://api.github.com/repos/altso/sandbox/releases" -Method Post -Headers $authorization -ContentType "application/json" -Body $json

gci -Recurse

[array]$artifacts = @("src")

Foreach ($artifact in $artifacts)
{
    Write-Host ("Looking for files in {0}..." -f $artifact)
    $files = gci $artifact | where { ! $_.PSIsContainer }
    foreach ($file in $files)
    {
        $uploadUrl = $response.upload_url -replace "\{\?name\}", ("?name={0}" -f $file.Name)
        Write-Host ("Uploading {0} to {1}..." -f $file.FullName, $uploadUrl)
        Invoke-RestMethod $uploadUrl -Method Post -InFile $file.FullName -Headers $authorization -ContentType "application/octet-stream"
    }
}

