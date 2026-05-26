<#
.NOTES
    Author  : Segfault-Git
    GitHub  : https://github.com/Segfault-Git/Simple-Explorer-Menu
    Version : 0.0.0
#>

#requires -version 5.1

$semVersion = "0.0.0"
$semReleaseTag = ""

function menu {
    [CmdletBinding()]
    param(
        [string]$lang,
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
        [string]$dir = "$env:ProgramData\simple-explorer-menu",
        [switch]$gui
    )

    $username = "Segfault-Git"
    $repo = "Simple-Explorer-Menu"
    $zip_name = "SEM"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "SEM needs to be run as Administrator. Attempting to relaunch."
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        } elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

    if ($PSCommandPath) {
        $cmd = "& '$($PSCommandPath)' $($argList -join ' ')"
        if ($processCmd -eq "wt.exe") {
            Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$cmd`"" -Verb RunAs
        } else {
            Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$cmd`"" -Verb RunAs
        }
    } else {
        $semUrl = if ($script:semReleaseTag) {
            "https://github.com/$username/$repo/releases/download/$script:semReleaseTag/sem.ps1"
        } else {
            "https://github.com/$username/$repo/releases/latest/download/sem.ps1"
        }
        $tmpFile = Join-Path $env:TEMP "sem_elevate.ps1"
        "irm $semUrl | iex; menu $($argList -join ' ')" | Set-Content $tmpFile -Force
        if ($processCmd -eq "wt.exe") {
            Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -File `"$tmpFile`"" -Verb RunAs
        } else {
            Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$tmpFile`"" -Verb RunAs
        }
    }

    break
}

[string]$RegsPath = "$dir\regs"
[string]$LangPath = "$dir\lang"

if ($log) {
    $_log_path = $dir + ".log"
    Remove-Item -Path $_log_path -ErrorAction SilentlyContinue
    Start-Transcript -Path $_log_path
}

function Get-GitHubReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Repo,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ZipName
    )

    try {
        $releaseApiUrl = if ($semReleaseTag) {
            "https://api.github.com/repos/$Username/$Repo/releases/tags/$semReleaseTag"
        } else {
            "https://api.github.com/repos/$Username/$Repo/releases/latest"
        }
        $headers = @{ "User-Agent" = "PowerShellScript" }
        $latestRelease = Invoke-WebRequest -Uri $releaseApiUrl -Headers $headers -UseBasicParsing | ConvertFrom-Json
        $link = $latestRelease.assets.browser_download_url | Select-String -Pattern "$ZipName\.zip" | Select-Object -First 1
        if ($link) {
            $link = $link.ToString().Trim()
            Write-Host "Downloading $link" -ForegroundColor Green
            return $link
        } else {
            Write-Host "No matching asset found for $ZipName" -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "Error fetching release information. Check your network connection or repository." -ForegroundColor Red
        return
    }
}

function Download-ReleaseZip {
    param(
        [string]$ReleaseZipUrl,
        [string]$SavePath,
        [string]$FileName
    )

    if (-not (Test-Path $SavePath)) { New-Item -ItemType Directory -Path $SavePath -Force | Out-Null }
    $DownloadPath = Join-Path -Path $SavePath -ChildPath $FileName
    if (Test-Path $DownloadPath) { Remove-Item -Path $DownloadPath -Force }
    try {
        (New-Object Net.WebClient).DownloadFile("$ReleaseZipUrl", "$DownloadPath")
    } catch {
        Write-Host "$FileName is not downloaded. Skipping..." -ForegroundColor Red
        Write-Host "Please check your network connection or the URL [$ReleaseZipUrl]" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        pause
        exit
    }
}

function Install-SEMData {
    $scriptDir = if ($PSCommandPath) {
        Split-Path -Parent $PSCommandPath
    } elseif ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $null
    }

    if ($local) {
        if (-not $scriptDir -or -not (Test-Path (Join-Path $scriptDir 'regs'))) {
            Write-Host "-local requires sem.ps1 to be run from the project directory. Falling back to download." -ForegroundColor Yellow
            $local = $false
        } else {
            if (Test-Path $dir) {
                Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                Write-Host "Deleted existing $dir" -ForegroundColor Yellow
            }
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created $dir" -ForegroundColor Green

            Get-ChildItem -Path $scriptDir -Force | Where-Object {
                $_.Name -notmatch '^\.' -and $_.Name -ne 'sem.ps1'
            } | ForEach-Object {
                Write-Host "Copying $($_.Name) to $dir" -ForegroundColor Cyan
                Copy-Item -Path $_.FullName -Destination $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if (-not $local) {
        $releaseZipUrl = Get-GitHubReleaseAsset -Username $username -Repo $repo -ZipName $zip_name
        if (!($releaseZipUrl)) {
            Write-Host "Failed to fetch the release URL. Exiting..." -ForegroundColor Red
            pause
            exit
        }
        $fileName = $releaseZipUrl.Split('/')[-1]
        $zipPath = Join-Path -Path $dir -ChildPath $fileName
        Download-ReleaseZip -ReleaseZipUrl $releaseZipUrl -SavePath $dir -FileName $fileName
        if (Test-Path $zipPath) {
            Expand-Archive -Path $zipPath -DestinationPath $dir -Force -ErrorAction Stop
        } else {
            Write-Host "Archive not found: $zipPath" -ForegroundColor Red
            pause
            exit
        }
    }
}

if ($remove) {
    if (-not (Test-Path $dir)) {
        Write-Host "SEM directory not found: $dir" -ForegroundColor Red
        Write-Host "Nothing to remove." -ForegroundColor Yellow
        exit
    }
} else {
    Install-SEMData

    $criticalPaths = @(
        @{ Path = "$dir\regs"; Name = "Registry files" },
        @{ Path = "$dir\lang"; Name = "Language files" }
    )

    $missing = @()
    foreach ($item in $criticalPaths) {
        if (-not (Test-Path $item.Path)) {
            $missing += $item.Name
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Critical data missing:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host "Installation cannot continue." -ForegroundColor Red
        pause
        exit
    }

    $regFileCount = (Get-ChildItem -Path "$dir\regs" -Filter "*.reg" -ErrorAction SilentlyContinue).Count
    if ($regFileCount -eq 0) {
        Write-Host "No .reg files found in $dir\regs" -ForegroundColor Red
        pause
        exit
    }
}

if ($gui) {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms
    Write-Host "GUI mode is not yet implemented. Launching TUI..." -ForegroundColor Yellow
}

$sysFolders = @("System32", "SysWOW64")

function Timer {
    param(
        [switch]$start,
        [switch]$end
    )
    if ($start) {
        $global:timer = [Diagnostics.Stopwatch]::StartNew()
    }
    if ($end) {
        $global:timer.Stop()
        $timeRound = [Math]::Round(($global:timer.Elapsed.TotalSeconds), 2)
        $global:timer.Reset()
        Write-Host "`nTask completed in $timeRound`s" -ForegroundColor Cyan
    }
}

function Test-Admin {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Restart-ExplorerAsUser {
    $proc = Get-Process -Name explorer -ErrorAction SilentlyContinue
    $proc | Stop-Process -Force
    $proc | Wait-Process -Timeout 5

    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        cmd /c "start /b explorer.exe"
    }
}

function Set-OldExplorerMenu {
    param(
        [switch]$remove
    )

    $regPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
    $inprocPath = "$regPath\InprocServer32"

    try {
        if ($remove) {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "`nClassic context menu deactivated!" -ForegroundColor Yellow
        } else {
            New-Item -Path $inprocPath -Force | Out-Null
            Set-ItemProperty -Path $inprocPath -Name '(default)' -Value ''
            Write-Host "`nClassic context menu activated!" -ForegroundColor Green
        }
    } catch {
        Write-Host "Registry operation failed: $_" -ForegroundColor Red
        return
    }
}

function Read-IniFile {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath
    )

    $ini = @{}

    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Encoding UTF8
        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -and !$line.StartsWith('#') -and !$line.StartsWith(';') -and $line.Contains('=')) {
                $key, $value = $line -split '=', 2
                $key = $key.Trim()
                $value = $value.Trim().Trim('"')
                $ini[$key] = $value
            }
        }
    }

    return $ini
}

function Reset-Rights {
    param([Parameter(Mandatory = $true)]$target)
    $acl = Get-Acl $target
    $permission = "Users", "FullControl", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($permission)
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $target -AclObject $acl
}

function Copy-FilesWithAcl {
    param(
        [Parameter(Mandatory = $true)][string]$source,
        [Parameter(Mandatory = $true)][string]$target
    )

    try {
        & xcopy "$source" "$target*" /q /o /y > $null 2>&1
        switch ($LASTEXITCODE) {
            0 {
                Write-Verbose "Copying done"
            }
            1 {
                throw "No files were found to copy ($source to $target)"
            }
            2 {
                throw "Copy terminated by user (Ctrl+C)"
            }
            4 {
                throw "Initialization error - insufficient memory or invalid syntax"
            }
            5 {
                throw "Disk write error occurred"
            }
            default {
                throw "Exception occurred while trying to copy $source to $target. (Exit code: $LASTEXITCODE)"
            }
        }
    } catch {
        Write-Host "Critical error during copy operation: $($_.Exception.Message)" -ForegroundColor Red
        pause
        exit
    }
}

function Get-TakeOwn {
    param(
        [Parameter(Mandatory = $true)][string]$target,
        [switch]$exe
    )

    try {
        Write-Verbose "Takeown command executed for: $target"
        if (!(Test-Path $target)) {
            Write-Host "NOT EXIST $target"
            return
        }
        & takeown /f $target /A > $null 2>&1
        switch ($LASTEXITCODE) {
            0 {
                Write-Verbose "Ownership successfully taken"
                if ($exe) {
                    try {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $target -Value "RUNASADMIN"
                        Write-Verbose "Registry updated for: $target"
                    } catch {
                        Write-Host "`nFailed to set RUNASADMIN flag for: $target" -ForegroundColor Red
                    }
                }
            }
            1 {
                throw "Takeown error: Invalid parameters or syntax"
            }
            2 {
                throw "Takeown error: No files found matching the specified criteria"
            }
            4 {
                throw "Takeown error: Access denied (insufficient privileges)"
            }
            5 {
                throw "Takeown error: Processing error occurred"
            }
            default {
                throw "Takeown file $target failed (Exit code: $LASTEXITCODE)"
            }
        }
    } catch {
        Write-Host "Failed to set ownership for $target $($_.Exception.Message)" -ForegroundColor Red
        pause
        exit
    }
}

function Copy-Cmd {
    Write-Host "Copying console applications..."

    $locales = (Get-ChildItem -Path "$env:SystemRoot\System32" -Directory | Where-Object { $_.Name -match "^[a-z]{2}-[A-Z]{2}$" }).Name

    foreach ($folder in $sysFolders) {
        $console_paths = @(
            @{
                Source = "$env:SystemRoot\$folder\cmd.exe"
                Target = "$env:SystemRoot\$folder\cmda.exe"
            },
            @{
                Source = "$env:SystemRoot\$folder\WindowsPowerShell\v1.0\powershell.exe"
                Target = "$env:SystemRoot\$folder\WindowsPowerShell\v1.0\powershella.exe"
            }
        )
        foreach ($console_path in $console_paths) {
            if (Test-Path $($console_path.Source)) {
                Write-Verbose "Copying from: $($console_path.Source)"
                Write-Verbose "Copying to: $($console_path.Target)"
                Copy-FilesWithAcl -source "$($console_path.Source)" -target "$($console_path.Target)"
                Get-TakeOwn -target "$($console_path.Target)" -exe
            } else {
                Write-Host "`nCan't find  $($console_path.Source)" -ForegroundColor Red
            }
        }

        foreach ($locale in $locales) {
            $muiPath = "$env:SystemRoot\$folder\$locale\cmd.exe.mui"
            $targetmui = "$env:SystemRoot\$folder\$locale\cmda.exe.mui"
            if (Test-Path $muiPath) {
                Copy-FilesWithAcl -source "$muiPath" -target "$targetmui"
                Get-TakeOwn -target "$targetmui"
            }
        }
    }
}

function Remove-Cmd {
    Write-Host "Removing..." -ForegroundColor Red

    $locales = (Get-ChildItem -Path "$env:SystemRoot\System32" -Directory | Where-Object { $_.Name -match "^[a-z]{2}-[A-Z]{2}$" }).Name

    foreach ($folder in $sysFolders) {
        $console_paths = @(
            @{
                Source = "$env:SystemRoot\$folder\cmd.exe"
                Target = "$env:SystemRoot\$folder\cmda.exe"
            },
            @{
                Source = "$env:SystemRoot\$folder\WindowsPowerShell\v1.0\powershell.exe"
                Target = "$env:SystemRoot\$folder\WindowsPowerShell\v1.0\powershella.exe"
            }
        )
        foreach ($console_path in $console_paths) {
            if (Test-Path $($console_path.Target)) {
                Write-Host "Removing $($console_path.Target)" -ForegroundColor Gray
                Reset-Rights $($console_path.Target)
                Remove-Item -Path "$($console_path.Target)" -Force
            } else {
                Write-Host "`nCan't find  $($console_path.Target)" -ForegroundColor Red
            }
        }

        foreach ($locale in $locales) {
            $targetmui = "$env:SystemRoot\$folder\$locale\cmda.exe.mui"
            if (Test-Path $targetmui) {
                Write-Host "Removing $targetmui" -ForegroundColor Gray
                Reset-Rights $targetmui
                Remove-Item -Path $targetmui -Force
            }
        }
    }
}

function Add-Lang {
    $regFilesPath = "$dir\menu_$lang\"
    $dictionaryPath = "$dir\lang\$lang.ini"

    Write-Verbose "Reg files path: $regFilesPath"
    Write-Verbose "Translation INI path: $dictionaryPath"

    Write-Host "`nTranslating reg files to $lang..."
    if (-not (Test-Path -Path "$regFilesPath")) {
        New-Item -Path "$regFilesPath" -ItemType Directory | Out-Null
    }

    Copy-Item -Path "$dir\regs\*" "$regFilesPath" -Recurse -Force -ErrorAction Stop

    if (-not (Test-Path "$dictionaryPath")) {
        $dictionaryPath = "$dir\lang\en-US.ini"
        Write-Host "`nCant find the dictionary for $lang. Using en-US" -ForegroundColor Red
    }

    $dictionary = @{ }
    Get-Content $dictionaryPath -Encoding UTF8 -ErrorAction Stop | ForEach-Object {
        if ($_ -match '^lang_(\S+)="(.+)"') {
            $key = $matches[1]
            $value = $matches[2]
            $dictionary["lang_$key"] = $value
        }
    }

    Get-ChildItem $regFilesPath -Filter '*.reg' -Recurse -ErrorAction Stop | ForEach-Object {
        $filePath = $_.FullName
        $content = Get-Content $filePath
        foreach ($key in $dictionary.Keys) {
            $content = $content -replace "\b$key\b", $dictionary[$key]
        }
        Set-Content $filePath $content -Encoding Unicode
        Write-Verbose "$($_.Name)"
    }
    Write-Verbose "Translating done"
}

function Cleaning {
    if ($pause) {
        Write-Host "-----------------------------------------------------`nYou can now review the information and close the window at your convenience.`nThe script has already completed!" -ForegroundColor Green
        Write-Host "Press any key to close the window!" -ForegroundColor Cyan
        $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Start-Sleep 2; Remove-Item -Path `"$dir`" -Recurse -Force`"" -WindowStyle Hidden
    exit
}

function Invoke-RegFiles {
    param(
        [string[]]$FileNames,
        [int[]]$SelectedIndices
    )

    if ($SelectedIndices.Count -eq 0) {
        Write-Host "No files to execute" -ForegroundColor Red
        return
    }

    Write-Host "`nExecuting selected .reg files...`n"

    foreach ($index in $SelectedIndices) {
        $fileName = $FileNames[$index]
        $fullPath = Join-Path "$dir/menu_$lang" $fileName
        Write-Verbose "Processing file: $fileName"
        Write-Verbose "Preparing to execute: $fullPath"
        if (Test-Path $fullPath) {
            Write-Host "-> $fileName" -ForegroundColor Cyan
            try {
                reg import $fullPath >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Verbose "Successfully executed: $fileName"
                } else {
                    Write-Host "- Error executing: $fileName (code: $($LASTEXITCODE))" -ForegroundColor Red
                    Write-Host "- Full path: $fullPath" -ForegroundColor Red
                }
            } catch {
                Write-Host "- Exception executing $fileName`: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "- File not found: $fullPath" -ForegroundColor Red
        }
    }

    Write-Host "`nExecution completed!" -ForegroundColor Green
}

function Remove-RegFiles {
    $regFiles = Get-ChildItem -Path "$RegsPath" -Filter '*.reg' -Recurse -ErrorAction Stop

    if ($regFiles.Count -eq 0) {
        Write-Host "No files to remove" -ForegroundColor Red
        return
    }

    Write-Host "`nRemoving selected .reg files...`n"

    foreach ($file in $regFiles) {
        Write-Host "--------------------------------`nProcessing file: $($file.Name)"

        $lines = Get-Content -Path "$($file.FullName)"

        foreach ($line in $lines) {
            if (($line -match '^\[HKEY_.*\]') -and ($line -notlike '*\command]')) {
                $key = $line.Trim('"', '[', ']')
                Write-Verbose "- $key"
                if ($key -match '[\*\?]') {
                    reg query $key >$null 2>&1
                    $keyExists = ($LASTEXITCODE -eq 0)
                } else {
                    $keyExists = Test-Path "Registry::$key" -ErrorAction SilentlyContinue
                }

                if ($keyExists) {
                    reg delete $key /f >$null 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "Exception occurred while trying to remove key: $key" -ForegroundColor Red
                    }
                } else {
                    Write-Verbose "Key does not exist, skipping: $key"
                }
            }
        }
        Start-Sleep -Milliseconds 50
    }
    Write-Host "`nRemoval completed!" -ForegroundColor Green
}

function ExitCountdown {
    if (!($VerbosePreference -eq 'Continue')) {
        $countdown = 9

        Write-Host "`nScript will exit automatically after countdown reaches 0." -ForegroundColor Yellow
        Write-Host "To prevent this and review the logs, press any key before the countdown ends.`n" -ForegroundColor Yellow
        Write-Host "From this moment you can close any window - the script has finished executing!`n" -ForegroundColor Yellow

        while ($countdown -gt 0) {
            if ([Console]::KeyAvailable) {
                $ConsoleKey = [Console]::ReadKey($true)
                break
            }
            Write-Host "`r	$countdown seconds remaining... Press any key to stop" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            $countdown--
        }

        if ($countdown -eq 0) {
            exit
        } else {
            Write-Host "`n"
            pause
        }
    }
}

function Get-MenuItems {
    if (!(Test-Path $RegsPath)) {
        Write-Error -Message "Folder $RegsPath not found!"
        return @(), @()
    }

    $regFiles = Get-ChildItem -Path $RegsPath -Filter "*.reg" | Sort-Object Name

    if ($regFiles.Count -eq 0) {
        Write-Warning "No .reg files found in folder $RegsPath!"
        return @(), @()
    }

    $langFile = Join-Path $LangPath "$lang.ini"

    $translations = @{}
    if (Test-Path $langFile) {
        $translations = Read-IniFile -FilePath $langFile
    } else {
        Write-Error -Message "Localization file $langFile not found!"
        return
    }

    $menuItems = @()
    $fileNames = @()

    foreach ($file in $regFiles) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $fileNames += $file.Name

        if ($translations.ContainsKey($fileName)) {
            $menuItems += $translations[$fileName]
        } else {
            $menuItems += $fileName
        }
    }

    return $menuItems, $fileNames
}

function ShowDebugMenu {
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "                                Simple Explorer Menu                                    " -ForegroundColor Yellow
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "Language:              $lang" -ForegroundColor Gray
    Write-Host "Reg files folder:      $RegsPath" -ForegroundColor Gray
    Write-Host "Localization folder:   $LangPath" -ForegroundColor Gray
    Write-Host "Files found:           $($menuItems.Count)" -ForegroundColor Gray
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "                                Arguments                                               " -ForegroundColor Yellow
    Write-Host "========================================================================================" -ForegroundColor Cyan
    Write-Host "remove:                $remove" -ForegroundColor Gray
    Write-Host "pause:                 $pause" -ForegroundColor Gray
    Write-Host "old:                   $old" -ForegroundColor Gray
    Write-Host "log:                   $log" -ForegroundColor Gray
    Write-Host "dir:                   $dir" -ForegroundColor Gray
    Write-Host ""
}

function Show-HelpPage {
    Clear-Host
    Write-Host "+==================================================================================+" -ForegroundColor Cyan
    Write-Host "|                                  HELP PAGE                                       |" -ForegroundColor Cyan
    Write-Host "|==================================================================================|" -ForegroundColor Cyan
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "| [Up Arrow]     - Move cursor up to previous item                                 |" -ForegroundColor Green
    Write-Host "| [Down Arrow]   - Move cursor down to next item                                   |" -ForegroundColor Green
    Write-Host "| [Left Arrow]   - Go to previous page                                             |" -ForegroundColor Green
    Write-Host "| [Right Arrow]  - Go to next page                                                 |" -ForegroundColor Green
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "| [Space]        - Toggle selection of current item (select/deselect)              |" -ForegroundColor Green
    Write-Host "| [A]            - Select ALL items on current page                                |" -ForegroundColor Green
    Write-Host "| [N]            - Deselect all items on current page (None)                       |" -ForegroundColor Green
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "| [Enter]        - Confirm selection and proceed to execution                      |" -ForegroundColor Green
    Write-Host "| [Q]            - Quit program without executing any files                        |" -ForegroundColor Green
    Write-Host "| [H]            - Show this help page                                             |" -ForegroundColor Green
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "| [X] - Selected item (checkbox marked)                                            |" -ForegroundColor Green
    Write-Host "| [ ] - Unselected item (checkbox empty)                                           |" -ForegroundColor White
    Write-Host "| > - Current cursor position (highlighted item)                                   |" -ForegroundColor Green
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "| Selected items are shown in YELLOW color                                         |" -ForegroundColor Yellow
    Write-Host "| Current cursor position has GREEN text on DARK GRAY background                   |" -ForegroundColor Green -BackgroundColor DarkGray
    Write-Host "|                                                                                  |" -ForegroundColor White
    Write-Host "+==================================================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to return to the menu..." -ForegroundColor Gray
    $null = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-StaticElements {
    param(
        [int]$CurrentPage,
        [int]$TotalPages,
        [int]$SelectedCount,
        [int]$TotalItems
    )

    [Console]::SetCursorPosition(0, 0)

    Write-Host "+==================================================================================+" -ForegroundColor Cyan
    Write-Host "|                            Select .reg files to execute                          |" -ForegroundColor Cyan
    Write-Host "|==================================================================================|" -ForegroundColor Cyan

    if ($TotalPages -gt 1) {
        Write-Host "| Page $($CurrentPage + 1) of $TotalPages                                                                      |" -ForegroundColor Yellow
        Write-Host "|==================================================================================|" -ForegroundColor Cyan
    }
}

function Show-MenuItems {
    param(
        [string[]]$MenuItems,
        [bool[]]$Selected,
        [int]$CurrentSelection,
        [int]$StartIndex,
        [int]$EndIndex,
        [int]$StartLine
    )

    [Console]::SetCursorPosition(0, $StartLine)

    for ($i = $StartIndex; $i -le $EndIndex; $i++) {
        $checkbox = if ($Selected[$i]) { "[X]" } else { "[ ]" }

        $displayText = $MenuItems[$i]
        if ($displayText.Length -gt 65) {
            $displayText = $displayText.Substring(0, 62) + "..."
        }

        $line = if ($i -eq $CurrentSelection) {
            "| > $checkbox $displayText"
        } else {
            "|   $checkbox $displayText"
        }

        $paddedLine = $line.PadRight(83) + "|"
        if ($paddedLine.Length -gt 84) {
            $paddedLine = $paddedLine.Substring(0, 83) + "|"
        }

        if ($i -eq $CurrentSelection) {
            Write-Host $paddedLine -ForegroundColor Green -BackgroundColor DarkGray
        } else {
            $color = if ($Selected[$i]) { "Yellow" } else { "White" }
            Write-Host $paddedLine -ForegroundColor $color -BackgroundColor Black
        }
    }
}

function Show-Footer {
    param(
        [int]$SelectedCount,
        [int]$TotalItems,
        [int]$FooterStartLine
    )

    [Console]::SetCursorPosition(0, $FooterStartLine)

    Write-Host "|==================================================================================|" -ForegroundColor Cyan
    Write-Host "| [Up/Down]Nav [Space]Sel [A]All [N]None [L/R]Page [Enter]Ok [Q]Quit [H]Help    |" -ForegroundColor Gray
    Write-Host "+==================================================================================+" -ForegroundColor Cyan

    if ($SelectedCount -gt 0) {
        Write-Host "Selected files: $SelectedCount of $TotalItems" -ForegroundColor Green
    } else {
        Write-Host ""
    }
}

function Show-MultiSelectMenu {
    param(
        [string[]]$MenuItems,
        [string[]]$FileNames,
        [bool[]]$PreSelected = @()
    )

    [Console]::CursorVisible = $false

    try {
        $selected = New-Object bool[] $MenuItems.Count
        if ($PreSelected.Count -gt 0) {
            for ($i = 0; $i -lt [Math]::Min($PreSelected.Count, $MenuItems.Count); $i++) {
                $selected[$i] = $PreSelected[$i]
            }
        }

        $currentSelection = 0
        $itemsPerPage = 15
        $totalItems = $MenuItems.Count
        $totalPages = [Math]::Ceiling($totalItems / $itemsPerPage)
        $currentPage = 0
        $previousSelection = -1
        $previousPage = -1

        Clear-Host

        do {
            $startIndex = $currentPage * $itemsPerPage
            $endIndex = [Math]::Min($startIndex + $itemsPerPage - 1, $totalItems - 1)
            $selectedCount = ($selected | Where-Object { $_ }).Count

            if ($currentPage -ne $previousPage) {
                Clear-Host
                Show-StaticElements -CurrentPage $currentPage -TotalPages $totalPages -SelectedCount $selectedCount -TotalItems $totalItems
                Show-MenuItems -MenuItems $MenuItems -Selected $selected -CurrentSelection $currentSelection -StartIndex $startIndex -EndIndex $endIndex -StartLine 5
                Show-Footer -SelectedCount $selectedCount -TotalItems $totalItems -FooterStartLine ($endIndex - $startIndex + 6)
                $previousPage = $currentPage
                $previousSelection = $currentSelection
            }
            elseif ($currentSelection -ne $previousSelection) {
                Show-MenuItems -MenuItems $MenuItems -Selected $selected -CurrentSelection $currentSelection -StartIndex $startIndex -EndIndex $endIndex -StartLine 5
                $footerLine = $endIndex - $startIndex + 9
                [Console]::SetCursorPosition(0, $footerLine)
                if ($selectedCount -gt 0) {
                    Write-Host "Selected files: $selectedCount of $totalItems" -ForegroundColor Green
                } else {
                    Write-Host " "
                }
                $previousSelection = $currentSelection
            }

            $ConsoleKey = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($ConsoleKey.VirtualKeyCode) {
                38 {
                    if ($currentSelection -gt 0) {
                        $currentSelection--
                        if ($currentSelection -lt $currentPage * $itemsPerPage) {
                            $currentPage--
                        }
                    }
                }
                40 {
                    if ($currentSelection -lt $totalItems - 1) {
                        $currentSelection++
                        if ($currentSelection -ge ($currentPage + 1) * $itemsPerPage) {
                            $currentPage++
                        }
                    }
                }
                37 {
                    if ($currentPage -gt 0) {
                        $currentPage--
                        $currentSelection = $currentPage * $itemsPerPage
                    }
                }
                39 {
                    if ($currentPage -lt $totalPages - 1) {
                        $currentPage++
                        $currentSelection = $currentPage * $itemsPerPage
                    }
                }
                32 {
                    $selected[$currentSelection] = -not $selected[$currentSelection]
                    $previousSelection = -1
                }
                13 {
                    $result = @()
                    for ($i = 0; $i -lt $MenuItems.Count; $i++) {
                        if ($selected[$i]) {
                            $result += $i
                        }
                    }
                    return $result
                }
                81 {
                    exit
                }
                65 {
                    for ($i = $startIndex; $i -le $endIndex; $i++) {
                        $selected[$i] = $true
                    }
                    $previousSelection = -1
                }
                78 {
                    for ($i = $startIndex; $i -le $endIndex; $i++) {
                        $selected[$i] = $false
                    }
                    $previousSelection = -1
                }
                72 {
                    Show-HelpPage
                    $previousPage = -1
                    $previousSelection = -1
                }
            }

            $currentPage = [Math]::Floor($currentSelection / $itemsPerPage)

        } while ($true)
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

function Show-SelectionResults {
    param(
        [string[]]$MenuItems,
        [string[]]$FileNames,
        [int[]]$SelectedIndices
    )

    if ($SelectedIndices.Count -eq 0) {
        Write-Host "Nothing selected" -ForegroundColor Red
        return
    }

    Write-Host "`nSelected items:" -ForegroundColor Green
    Write-Host "========================================================================================" -ForegroundColor Cyan

    foreach ($index in $SelectedIndices) {
        Write-Host "* $($MenuItems[$index])" -ForegroundColor Yellow
        Write-Host "  File: $($FileNames[$index])" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "Total selected: $($SelectedIndices.Count) files" -ForegroundColor Green
}

function Start-RegManager {
    $menuItems, $fileNames = Get-MenuItems -RegsPath $RegsPath -LangPath $LangPath -Language $lang

    if ($menuItems.Count -eq 0) {
        Write-Error -Message "No files available to display"
        return
    }

    if ($VerbosePreference -eq 'Continue') {
        ShowDebugMenu
        Write-Host "Press any key to continue..." -ForegroundColor Gray
        $null = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    if ($all) {
        $selectedIndices = 0..($menuItems.Count - 1)
    } else {
        do {
            $selectedIndices = Show-MultiSelectMenu -MenuItems $menuItems -FileNames $fileNames

            if ($selectedIndices.Count -eq 0) {
                Write-Host "`nYou haven't chosen anything! To exit press Q" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
                Clear-Host
            }
        } while ($selectedIndices.Count -eq 0)
    }

    Clear-Host

    if (!($all)) {
        Show-SelectionResults -MenuItems $menuItems -FileNames $fileNames -SelectedIndices $selectedIndices

        Write-Host "Proceed with selected menu items? Press Enter to confirm." -ForegroundColor Yellow -NoNewline
        $confirmation = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($($confirmation.VirtualKeyCode) -ne '13') {
            Write-Host "`nOperation cancelled" -ForegroundColor Red
            return
        }
    }

    return @{
        FileNames = $fileNames
        SelectedIndices = $selectedIndices
    }
}

# === Main logic ===

$host.UI.RawUI.BackgroundColor = 'Black'
$host.UI.RawUI.ForegroundColor = 'White'
Clear-Host

if (-not $lang -or $lang -notmatch '^[a-z]{2}-[A-Z]{2}$') {
    $lang = (Get-UICulture).Name
}

if (-not $lang -or $lang -notmatch '^[a-z]{2}-[A-Z]{2}$') {
    $lang = "en-US"
}

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    Write-Host 'ONLY SUPPORTS AMD64 ARCHITECTURE'
    return
}

if ($remove) {
    Write-Host "Start reverting SEM changes..."
    Remove-Cmd
    Remove-RegFiles
    Set-OldExplorerMenu -remove
    Restart-ExplorerAsUser
    Write-Host "---------------------------------`nSimple Explorer Menu removed successfully`n---------------------------------" -ForegroundColor Green
} else {
    $result = Start-RegManager
    if ($result) {
        Timer -start
        Clear-Host
        Copy-Cmd
        Add-Lang
        Invoke-RegFiles -FileNames $result.FileNames -SelectedIndices $result.SelectedIndices
        if ($old) {
            Set-OldExplorerMenu
            Restart-ExplorerAsUser
        } else {
            Set-OldExplorerMenu -remove
        }
        Write-Host "`n---------------------------------`nSimple Explorer Menu installed successfully`n---------------------------------" -ForegroundColor Green
        Timer -end
    } else {
        Write-Host "Failed to start." -ForegroundColor Red
    }
}

if ($log) {
    Stop-Transcript
}

ExitCountdown

Cleaning

}
