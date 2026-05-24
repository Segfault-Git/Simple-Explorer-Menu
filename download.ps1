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
            $latestRelease = Invoke-WebRequest -Uri $latestReleaseUrl -Headers $headers -UseBasicParsing | ConvertFrom-Json
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
        $DownloadPath = Join-Path -Path $savePath -ChildPath $fileName
        if (Test-Path $DownloadPath) { Remove-Item -Path $DownloadPath -Force }
        try {
            (New-Object Net.WebClient).DownloadFile("$releaseZipUrl", "$DownloadPath")
        } catch {
            Write-Host "$fileName is not downloaded. Skipping..." -ForegroundColor Red
            Write-Host "Please check your network connection or the URL [$releaseZipUrl]" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            pause
            exit
        }
    }
    
    $scriptDir = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PWD
    }

    if ($local) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted existing $dir" -ForegroundColor Yellow
        }
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created $dir" -ForegroundColor Green

        Get-ChildItem -Path $scriptDir -Force | Where-Object {
            $_.Name -notmatch '^\.' -and $_.Name -ne 'download.ps1'
        } | ForEach-Object {
            Write-Host "Copying $($_.Name) to $dir" -ForegroundColor Cyan
            Copy-Item -Path $_.FullName -Destination $dir -Recurse -Force
        }
    } else {
        $releaseZipUrl = Get-GitHubReleaseAsset -username "$username" -repo "$repo" -zip_name "$zip_name"
        if (!($releaseZipUrl)) {
            Write-Host "Failed to fetch the release URL. Exiting..." -ForegroundColor Red
            pause
            exit
        }
        $fileName = $releaseZipUrl.Split('/')[-1]
        $zipPath = Join-Path -Path $dir -ChildPath $fileName
        Download -releaseZipUrl $releaseZipUrl -savePath $dir -fileName $fileName
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
