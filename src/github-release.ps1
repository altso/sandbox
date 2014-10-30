$username = "81b00ad1ab7d38804f4cc69002bff2db0af1e3ae"
$password = ""

$hash = (gci env:BUILD_VCS_NUMBER).Value
$version = (gci env:BUILD_NUMBER).Value
$name = ("v{0}" -f $version)

$json = @{ tag_name = $name; target_commitish = $hash; name = $name; body = ("Automatic release {0}" -f $name); prerelease = $true } | ConvertTo-Json

$authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$request = Invoke-RestMethod "https://api.github.com/repos/altso/sandbox/releases" -Method Post -Headers @{ Authorization = ("Basic {0}" -f $authorization) } -ContentType "application/json" -Body $json
