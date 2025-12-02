#requires -version 5.1

function menu {
    [CmdletBinding()]
    param(
        [ValidatePattern('^[a-z]{2}-[A-Z]{2}$')]
        $lang,
        [Alias('r')]
        [switch]$remove,
        [Alias('p')]
        [switch]$pause,
        [Alias('o')]
        [switch]$old,
        [Alias('l')]
        [switch]$log,
        [Alias('a')]
        [switch]$all,
        [switch]$local,
        [Alias('d')]
        [string]$dir = "$env:ProgramData\simple-explorer-menu"
    )
    
    $username = "Segfault-Git"
    $repo = "Simple-Explorer-Menu"
    $zip_name = "SEM"
    
    function Get-GitHubReleaseAsset {
        param(
            [PARAMETER(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$username,
            [PARAMETER(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$repo,
            [PARAMETER(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$zip_name
        )
        
        try {
            $latestReleaseUrl = "https://api.github.com/repos/$username/$repo/releases/latest"
            $headers = @{ "User-Agent" = "PowerShellScript" }
            $latestRelease = Invoke-WebRequest -Uri $latestReleaseUrl -Headers $headers | ConvertFrom-Json
            $link = $latestRelease.assets.browser_download_url | Select-String -Pattern "$zip_name" | Select-Object -First 1
            if ($link) {
                $link = $link.ToString().Trim()
                Write-Host "Downloading $link" -ForegroundColor Green
                return $link
            }
            else {
                Write-Host "No matching asset found for $zip_name" -ForegroundColor Red
                return
            }
        } catch {
            Write-Host "Error fetching release information. Check your network connection or repository." -ForegroundColor Red
            return
        }
    }
    
    function Download {
        param (
            [string]$releaseZipUrl,
            [string]$savePath,
            [string]$fileName
        )
        
        if (-not (Test-Path $savePath)) { New-Item -ItemType Directory -Path $savePath -Force | Out-Null }
        try {
            $DownloadPath = Join-Path -Path $savePath -ChildPath $fileName
            (New-Object Net.WebClient).DownloadFile("$releaseZipUrl", "$DownloadPath")
        } catch {
            Write-Host "$fileName is not downloaded. Skipping..." -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please check your network connection or the URL." -ForegroundColor Red
            pause
            exit
        }
    }
    
    if (!($local)) {
        $releaseZipUrl = Get-GitHubReleaseAsset -username "$username" -repo "$repo" -zip_name "$zip_name"
        if (!($releaseZipUrl)) {
            Write-Host "Failed to fetch the release URL. Exiting..." -ForegroundColor Red
            pause
            exit
        }
        $fileName = $releaseZipUrl.Split('/')[-1]
        $savePath = Join-Path -Path $dir -ChildPath $fileName
        $zipPath = Join-Path -Path $dir -ChildPath "$zip_name.zip"
        Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName
        if (Test-Path $zipPath) {
            Expand-Archive -Path $zipPath -DestinationPath $dir -Force -ErrorAction Stop
        } else {
            Write-Host "Archive not found: $zipPath" -ForegroundColor Red
            pause
            exit
        }
    }
    
    $run = Join-Path -ChildPath '\setup.ps1' -Path $dir
    Write-Host "Script requires administrator privileges. Restarting..."
    $arguments = @()
    
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [switch] -and $_.Value) {
            $arguments += "-$($_.Key)"
        } elseif ($_.Value -notmatch '^\s*$') {
            $arguments += "-$($_.Key) $($_.Value)"
        }
    }
    
    if ($VerbosePreference -eq 'Continue') {
        write-host "Args: $arguments"
        write-host "What to run: $run"
        Start-Process powershell -ArgumentList "-Noexit -NoProfile -ExecutionPolicy Bypass -File `"$run`" $arguments" -Verb RunAs -Wait
    } else {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$run`" $arguments" -Verb RunAs -Wait
    }
    Write-Host "Script finished" -ForegroundColor Green
}
