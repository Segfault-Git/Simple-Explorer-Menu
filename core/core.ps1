$sysFolders = @("System32", "SysWOW64")

function Timer {
	param(
		[switch]$start,
		[switch]$end
	)
	if ($start){
		$global:timer = [Diagnostics.Stopwatch]::StartNew()
	}
	if ($end){
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
	Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
	
	while (Get-Process -Name explorer -ErrorAction SilentlyContinue) {
		Start-Sleep -Milliseconds 100
	}
	
	cmd /c "start /b explorer.exe"
}

function Set-OldExplorerMenu {
	param (
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
		[PARAMETER(Mandatory = $true)][string]$FilePath
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
	param ([PARAMETER(Mandatory = $true)]$target)
	$acl = Get-Acl $target
	$permission = "Users", "FullControl", "Allow"
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($permission)
	$acl.AddAccessRule($accessRule)
	Set-Acl -Path $target -AclObject $acl
}

function Copy-FilesWithAcl {
	param (
		[PARAMETER(Mandatory = $true)][string]$source,
		[PARAMETER(Mandatory = $true)][string]$target
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
	param (
		[PARAMETER(Mandatory = $true)][string]$target,
		[switch]$exe
	)
	
	try {
		Write-Verbose "Takeown command executed for: $target" 
		if (!(Test-Path $target)){
			Write-Host "NOT EXIST $target"
			return
		}
		& takeown /f $target /A > $null 2>&1
		switch ($LASTEXITCODE) {
			0 {
				Write-Verbose "Ownership successfully taken"
				if ($exe){
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
	
	if (-not (Test-Path "$dictionaryPath")){
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
	if ($pause){
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
				# Execute .reg file
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
		# for slow systems
		Start-Sleep -Milliseconds 50
	}
	Write-Host "`nRemoval completed!" -ForegroundColor Green
}

function ExitCountdown {
	if (!($VerbosePreference -eq 'Continue')){
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

function Start-RegManager {
	# Get menu items list
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
		# Select all indices when $all is provided
		$selectedIndices = 0..($menuItems.Count - 1)
	} else {
		# Show selection menu with loop until something is selected
		do {
			$selectedIndices = Show-MultiSelectMenu -MenuItems $menuItems -FileNames $fileNames
			
			if ($selectedIndices.Count -eq 0) {
				Write-Host "`nYou haven't chosen anything! To exit press Q" -ForegroundColor Yellow
				Start-Sleep -Seconds 2
				Clear-Host
			}
		} while ($selectedIndices.Count -eq 0)
	}

	# Show selection results
	Clear-Host
	
	if (!($all)) {
		Show-SelectionResults -MenuItems $menuItems -FileNames $fileNames -SelectedIndices $selectedIndices
	
		# Execution confirmation
		Write-Host "Proceed with selected menu items? Press Enter to confirm." -ForegroundColor Yellow -NoNewline
		$confirmation = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		
		if ($($confirmation.VirtualKeyCode) -ne '13') { # Enter
			Write-Host "`nOperation cancelled" -ForegroundColor Red
			return
		}
	}
	
	return @{
		FileNames = $fileNames
		SelectedIndices = $selectedIndices
	}
}
