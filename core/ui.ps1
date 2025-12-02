
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
			# If no translation, use filename without extension
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
	
	# Set cursor position to menu start
	[Console]::SetCursorPosition(0, $StartLine)
	
	for ($i = $StartIndex; $i -le $EndIndex; $i++) {
		$checkbox = if ($Selected[$i]) { "[X]" } else { "[ ]" }
		
		# Trim long names for nice display
		$displayText = $MenuItems[$i]
		if ($displayText.Length -gt 65) {
			$displayText = $displayText.Substring(0, 62) + "..."
		}
		
		# Pad the line to full width to clear previous content
		$line = if ($i -eq $CurrentSelection) {
			"| > $checkbox $displayText"
		} else {
			"|   $checkbox $displayText"
		}
		
		# Pad line to 82 characters and add ending |
		$paddedLine = $line.PadRight(83) + "|"
		if ($paddedLine.Length -gt 84) {
			$paddedLine = $paddedLine.Substring(0, 83) + "|"
		}
		
		if ($i -eq $CurrentSelection) {
			Write-Host $paddedLine -ForegroundColor Green -BackgroundColor DarkGray
		} else {
			$color = if ($Selected[$i]) { "Yellow" } else { "White" }
			Write-Host $paddedLine -ForegroundColor $color
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
	Write-Host "| [Up/Down] Navigate | [Space] Select  | [A] All  | [N] None  | [H] Help           |" -ForegroundColor Gray
	Write-Host "| [Left/Right] Page  | [Enter] Execute | [Q] Exit                                  |" -ForegroundColor Gray
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
		# Initialize selection state
		$selected = New-Object bool[] $MenuItems.Count
		if ($PreSelected.Count -gt 0) {
			for ($i = 0; $i -lt [Math]::Min($PreSelected.Count, $MenuItems.Count); $i++) {
				$selected[$i] = $PreSelected[$i]
			}
		}
		
		$currentSelection = 0
		$itemsPerPage = 20
		$totalItems = $MenuItems.Count
		$totalPages = [Math]::Ceiling($totalItems / $itemsPerPage)
		$currentPage = 0
		$previousSelection = -1
		$previousPage = -1
		
		# Clear screen once
		Clear-Host
		
		do {
			$startIndex = $currentPage * $itemsPerPage
			$endIndex = [Math]::Min($startIndex + $itemsPerPage - 1, $totalItems - 1)
			$selectedCount = ($selected | Where-Object { $_ }).Count
			
			# Only redraw if page changed or first time
			if ($currentPage -ne $previousPage) {
				Clear-Host
				Show-StaticElements -CurrentPage $currentPage -TotalPages $totalPages -SelectedCount $selectedCount -TotalItems $totalItems
				Show-MenuItems -MenuItems $MenuItems -Selected $selected -CurrentSelection $currentSelection -StartIndex $startIndex -EndIndex $endIndex -StartLine 5
				Show-Footer -SelectedCount $selectedCount -TotalItems $totalItems -FooterStartLine ($endIndex - $startIndex + 6)
				$previousPage = $currentPage
				$previousSelection = $currentSelection
			}
			# Only redraw menu items if selection changed within same page
			elseif ($currentSelection -ne $previousSelection) {
				Show-MenuItems -MenuItems $MenuItems -Selected $selected -CurrentSelection $currentSelection -StartIndex $startIndex -EndIndex $endIndex -StartLine 5
				# Update footer with new selection count
				$footerLine = $endIndex - $startIndex + 10
				[Console]::SetCursorPosition(0, $footerLine)
				if ($selectedCount -gt 0) {
					Write-Host "Selected files: $selectedCount of $totalItems" -ForegroundColor Green
				} else {
					Write-Host " " # Clear line
				}
				$previousSelection = $currentSelection
			}
			
			$ConsoleKey = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			
			switch ($ConsoleKey.VirtualKeyCode) {
				38 { # Up Arrow
					if ($currentSelection -gt 0) {
						$currentSelection--
						if ($currentSelection -lt $currentPage * $itemsPerPage) {
							$currentPage--
						}
					}
				}
				40 { # Down Arrow
					if ($currentSelection -lt $totalItems - 1) {
						$currentSelection++
						if ($currentSelection -ge ($currentPage + 1) * $itemsPerPage) {
							$currentPage++
						}
					}
				}
				37 { # Left Arrow
					if ($currentPage -gt 0) {
						$currentPage--
						$currentSelection = $currentPage * $itemsPerPage
					}
				}
				39 { # Right Arrow
					if ($currentPage -lt $totalPages - 1) {
						$currentPage++
						$currentSelection = $currentPage * $itemsPerPage
					}
				}
				32 { # Space
					$selected[$currentSelection] = -not $selected[$currentSelection]
					# Force menu redraw to update checkbox
					$previousSelection = -1
				}
				13 { # Enter
					$result = @()
					for ($i = 0; $i -lt $MenuItems.Count; $i++) {
						if ($selected[$i]) {
							$result += $i
						}
					}
					return $result
				}
				81 { # Q
					exit
				}
				65 { # A - Select All on current page
					for ($i = $startIndex; $i -le $endIndex; $i++) {
						$selected[$i] = $true
					}
					$previousSelection = -1 # Force redraw
				}
				78 { # N - Deselect all on current page
					for ($i = $startIndex; $i -le $endIndex; $i++) {
						$selected[$i] = $false
					}
					$previousSelection = -1 # Force redraw
				}
				72 { # H - Help
					Show-HelpPage
					# Force complete redraw after help
					$previousPage = -1
					$previousSelection = -1
				}
			}
			
			# Update current page based on selection
			$currentPage = [Math]::Floor($currentSelection / $itemsPerPage)
			
		} while ($true)
	}
	finally {
		# Restore cursor visibility
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
