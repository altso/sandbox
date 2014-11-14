Param([string]$repo, [string]$username, [string]$password, [string]$artifacts)

$hash = (gci env:BUILD_VCS_NUMBER).Value
$version = (gci env:BUILD_NUMBER).Value
$name = ("v{0}" -f $version)
$json = @{ tag_name = $name; target_commitish = $hash; name = $name; body = ("Automatic release {0}" -f $name); prerelease = $true } | ConvertTo-Json
$authorization = @{ Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))) }

$response = Invoke-RestMethod ("https://api.github.com/repos/{0}/releases" -f $repo) -Method Post -Headers $authorization -ContentType "application/json" -Body $json

Foreach ($artifact in $artifacts.Split(';'))
{
    If ([System.IO.Directory]::Exists($artifact))
    {
        $zip = [System.IO.Path]::ChangeExtension($artifact, ".zip")
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") > $null
        [System.IO.Compression.ZipFile]::CreateFromDirectory($artifact, $zip)
        $artifact = $zip
    }
    $file = New-Object System.IO.FileInfo $artifact
    $uploadUrl = $response.upload_url -replace "\{\?name\}", ("?name={0}" -f $file.Name)
    Write-Host ("Uploading {0} to {1}..." -f $file.FullName, $uploadUrl)
    Invoke-RestMethod $uploadUrl -Method Post -InFile $file.FullName -Headers $authorization -ContentType "application/octet-stream" > $null
}

