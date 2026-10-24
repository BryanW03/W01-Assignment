# Starts the API, sends GET / POST / PUT / DELETE and saves the real
# requests, responses and status codes in evidence.txt
# Needs: .NET 8 SDK.  Run from this folder in PowerShell:  .\run-evidence.ps1
# If PowerShell blocks it, run first:  Set-ExecutionPolicy -Scope Process Bypass

$url = "http://localhost:5100"
$out = Join-Path $PSScriptRoot "evidence.txt"
Set-Content -Path $out -Value ""

# start the API in the background
$api = Start-Process -FilePath "dotnet" `
    -ArgumentList "run", "--urls", $url `
    -WorkingDirectory (Join-Path $PSScriptRoot "PizzaApi") `
    -PassThru -WindowStyle Hidden

# wait until the API answers (max ~90 sec)
$ready = $false
for ($i = 0; $i -lt 90; $i++) {
    try {
        Invoke-WebRequest -Uri "$url/pizza" -UseBasicParsing | Out-Null
        $ready = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    Write-Host "The API did not start. Try 'dotnet run' inside the PizzaApi folder to see the error."
    Stop-Process -Id $api.Id -Force -ErrorAction SilentlyContinue
    exit 1
}

function Send-Call {
    param($Title, $Method, $Path, $Body)

    $line = "=================================================="
    Add-Content $out $line
    Add-Content $out $Title
    Add-Content $out "REQUEST : $Method $url$Path"
    if ($Body) { Add-Content $out "BODY    : $Body" }
    Add-Content $out "--------------------------------------------------"

    try {
        $params = @{ Uri = "$url$Path"; Method = $Method; UseBasicParsing = $true }
        if ($Body) { $params.Body = $Body; $params.ContentType = "application/json" }
        $r = Invoke-WebRequest @params
        Add-Content $out "STATUS  : $($r.StatusCode) $($r.StatusDescription)"
        if ($r.Headers["Location"]) { Add-Content $out "LOCATION: $($r.Headers['Location'])" }
        Add-Content $out "RESPONSE: $($r.Content)"
    } catch {
        $code = [int]$_.Exception.Response.StatusCode
        Add-Content $out "STATUS  : $code $($_.Exception.Response.StatusCode)"
    }
    Add-Content $out ""
}

Send-Call "1) GET all pizzas (seed data + my extra pizza)" "GET" "/pizza"
Send-Call "2) GET one pizza by id" "GET" "/pizza/3"
Send-Call "3) POST a new pizza" "POST" "/pizza" '{"name":"Hawaiian","isGlutenFree":false}'
Send-Call "4) PUT update pizza 2" "PUT" "/pizza/2" '{"id":2,"name":"Veggie Deluxe","isGlutenFree":true}'
Send-Call "5) DELETE pizza 1" "DELETE" "/pizza/1"
Send-Call "6) GET all pizzas after the changes" "GET" "/pizza"

# stop the API (dotnet run starts a child process, so stop both)
Get-CimInstance Win32_Process |
    Where-Object { $_.ParentProcessId -eq $api.Id } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Stop-Process -Id $api.Id -Force -ErrorAction SilentlyContinue

Write-Host "Done. Open evidence.txt and copy it into NOTES.md"
