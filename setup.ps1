#requires -version 5.1

[CmdletBinding()]

param(
    [ValidatePattern('^[a-z]{2}-[A-Z]{2}$')]
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
    [string]$dir = "$env:ProgramData\simple-explorer-menu"
)

###
$host.UI.RawUI.BackgroundColor='Black';
$host.UI.RawUI.ForegroundColor='White';
Clear-Host;
###

[string]$RegsPath = "$dir\regs"
[string]$LangPath = "$dir\lang"

if ($log){
    $_log_path = $dir + ".log"
    Remove-Item -Path $_log_path -ErrorAction SilentlyContinue
    Start-Transcript -Path $_log_path
}

. "$dir\core\ui.ps1"
. "$dir\core\core.ps1"

if (-not (Test-Admin)) {
    Write-Error -Message "Script cant get required administrator privileges! Exiting..."
    pause
    exit
}

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
    if ($result){
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

if ($log){
    Stop-Transcript
}

ExitCountdown

Cleaning
