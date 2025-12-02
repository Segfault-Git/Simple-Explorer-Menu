# 🎯 Simple-Explorer-Menu - Advanced Windows Explorer Context Menu 🚀

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue" alt="PowerShell Version"/>
  <img src="https://img.shields.io/badge/Platform-Windows-brightgreen" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

Simple-Explorer-Menu (SEM) is a comprehensive PowerShell utility designed to customize and enhance the Windows Explorer context menu with powerful administrative, system management, and file operation tools. No installation required - just clean PowerShell magic with Windows registry integration.

The tool provides an intuitive GUI-based system for selecting and installing various context menu extensions, supporting multiple languages and preserving or reverting to the classic Explorer menu as needed.

## 📋 Table of Contents

- [✨ Features](#-features)
- [💡 Quick Start](#-quick-start)
- [🔧 Installation & Setup](#-installation--setup)
- [📝 Usage & Parameters](#-usage--parameters)
- [🎯 Available Modules](#-available-modules)
- [🔍 Troubleshooting](#-troubleshooting)
- [⚙️ Technical Details](#️-technical-details)
- [📄 License](#-license)

## ✨ Features

### 🛠️ Core Capabilities

- **GUI-Based Installation**: Interactive menu system for selecting context menu extensions
- **Multi-Language Support**: Support for English (en-US) and Russian (ru-RU) with extensible architecture
- **Registry Management**: Safe registry modification with one-click removal of all changes
- **Administrative Integration**: Automatic elevation to administrator privileges when needed
- **Explorer Menu Customization**: Option to replace or preserve the classic Windows Explorer menu
- **Modular Architecture**: 28+ registry modules for different functionality categories
- **Logging Support**: Optional comprehensive logging for troubleshooting
- **Safe Removal**: Complete reversion of all changes without system residue

### 📂 Context Menu Categories

#### Desktop Enhancements
- **Administration** - System administration utilities and shortcuts
- **Control Panel** - Quick access to Control Panel features
- **Data Cleaning** - Disk cleanup and maintenance tools
- **Personalization** - Desktop customization options
- **Shutdown** - Power management and shutdown utilities
- **Standard Apps** - Quick application launchers
- **System Info** - System information and diagnostics
- **System Tasks** - Common system task shortcuts
- **CD/DVD Tray** - Optical drive management

#### File & Folder Operations
- **Change Attributes** - Modify file/folder attributes
- **Check Drive** - Disk checking and verification
- **Copy to Clipboard** - Enhanced clipboard operations
- **Copy to Folder** - Quick copy operations
- **Delete** - Enhanced deletion options
- **Firewall** - Windows Firewall management
- **Hash Sum** - File integrity verification
- **Iconizer** - Icon management and customization
- **Library** - Library management
- **Move Up** - Quick folder navigation
- **NTFS Links** - NTFS link creation and management
- **Recycle Bin Cleaning** - Recycle bin management
- **Run as TI** - TrustedInstaller execution
- **Run in Command Prompt** - CMD context menu
- **Run in PowerShell** - PowerShell context menu
- **Run MSI as Admin** - MSI package execution
- **Security** - Advanced security options
- **Show/Hide Files** - File visibility toggle

## 💡 Quick Start

>[!NOTE]
> Direct link for security-conscious users:
<https://raw.githubusercontent.com/Segfault-Git/Simple-Explorer-Menu/main/download.ps1>

### Basic Installation

1. Open PowerShell as Administrator
   - Right-click on the Windows start menu and select PowerShell, or press `Win + S` and type PowerShell

2. Run the installation script:

```powershell
irm https://sem.scripts.wiki | iex; menu
```

This will:
- Download the latest release from GitHub
- Automatically extract the necessary files
- Launch the GUI menu selector in administrator mode

## 🔧 Installation & Setup

### System Requirements

- **Windows PowerShell** 5.1 or **PowerShell Core** 6.0+
- **Windows 10/11** (AMD64 architecture only)
- **Administrator privileges** (required for registry modifications)
- **.NET Framework** for system operations

### Parameter Reference

The `menu` function accepts the following parameters:

| Parameter | Alias | Type | Description | Example |
|-----------|-------|------|-------------|---------|
| `-lang` | | string | Language code (format: `xx-YY`) | `-lang 'ru-RU'` |
| `-remove` | `-r` | switch | Remove all modifications | |
| `-pause` | `-p` | switch | Pause script at end | |
| `-old` | `-o` | switch | Restore classic Explorer menu | |
| `-log` | `-l` | switch | Enable logging in $env:ProgramData | |
| `-all` | `-a` | switch | Auto-select all modules | |

## 📝 Usage & Parameters

### Standard Installation

```powershell
# Interactive GUI-based installation
irm https://sem.scripts.wiki | iex; menu
```

### Custom Language

```powershell
# Install with Russian language
irm https://sem.scripts.wiki | iex; menu -lang 'ru-RU'

# Install with English language
irm https://sem.scripts.wiki | iex; menu -lang 'en-US'
```

### Advanced Usage

```powershell
# Install all modules without interactive selection
irm https://sem.scripts.wiki | iex; menu -all

# Enable logging for troubleshooting
irm https://sem.scripts.wiki | iex; menu -log

# Preserve the classic Explorer menu
irm https://sem.scripts.wiki | iex; menu -old

# Use custom unpacking directory
irm https://sem.scripts.wiki | iex; menu -dir 'D:\CustomPath'
```

### Removal & Uninstallation

```powershell
# Remove all SEM modifications and restore original context menu
irm https://sem.scripts.wiki | iex; menu -remove

# Remove with pause (useful for checking output)
irm https://sem.scripts.wiki | iex; menu -remove -pause
```

## 🎯 Available Modules

### Desktop Shortcuts

The project includes 28+ registry modules organized into two main categories:

**Desktop Context Menu** (9 modules)
- Desktop_Administration.reg
- Desktop_ControlPanel.reg
- Desktop_DataClean.reg
- Desktop_Personalization.reg
- Desktop_Shutdown.reg
- Desktop_StandardApps.reg
- Desktop_SystemInfo.reg
- Desktop_SystemTasks.reg
- Desktop_TrayOfCDrom.reg

**File/Folder Context Menu** (19+ modules)
- Menu_*.reg files for various operations and utilities

### Selecting Modules

During installation, the GUI will present all available modules. You can:
- Select specific modules for installation
- Use `-all` flag to install everything at once
- Customize your selection in the interactive menu

## 🔍 Troubleshooting

### Network Connection Errors

```powershell
# Use local installation if you've previously downloaded the files
irm "full_path/download.ps1" | iex; menu -local
```

### Language Not Detected Correctly

```powershell
# Explicitly specify language
irm https://sem.scripts.wiki | iex; menu -lang 'en-US'
```

### Partial Installation / Need to Remove

```powershell
# Completely remove all SEM changes
irm https://sem.scripts.wiki | iex; menu -remove
```

### Enable Logging for Debugging

```powershell
# Install with logging enabled to troubleshoot issues
irm https://sem.scripts.wiki | iex; menu -log -pause

# Check the generated .log file in the C:\ProgramData directory
```

## ⚙️ Technical Details

### Installation Structure

```
C:\ProgramData\simple-explorer-menu\
├── core/
│   ├── core.ps1         # Core functionality
│   └── ui.ps1           # GUI and UI components
├── lang/
│   ├── en-US.ini        # English localization
│   └── ru-RU.ini        # Russian localization
├── regs/
│   ├── Desktop_*.reg    # Desktop context menu modules
│   └── Menu_*.reg       # File/folder context menu modules
├── setup.ps1            # Main setup script
└── download.ps1         # Download and bootstrap script
```

### Architecture

- **Bootstrap**: `download.ps1` handles GitHub release fetching and downloads
- **Setup**: `setup.ps1` manages registry operations and system changes
- **Core**: `core.ps1` contains main logic and utility functions
- **UI**: `ui.ps1` handles the interactive menu system
- **Localization**: INI files support multiple languages

### Registry Management

All modifications are registry-based, stored in:
- `HKEY_CLASSES_ROOT\*\shell` - File context menus
- `HKEY_CLASSES_ROOT\Folder\shell` - Folder context menus
- `HKEY_CLASSES_ROOT\DesktopBackground\shell` - Desktop context menus

### Safe Removal

The `irm https://sem.scripts.wiki | iex; menu -remove` command:
1. Deletes all added registry entries
2. Reverts to original Explorer menu state
3. Restarts Windows Explorer to apply changes
4. Leaves no traces in the system

## 📄 License

This project is provided as-is for educational and personal use. Please ensure compliance with Windows licensing and third-party software policies when using context menu integrations.

## 🤝 Contributing

We welcome contributions, bug reports, and feature requests! Feel free to:
- Submit issues for bugs or feature requests
- Fork and create pull requests with improvements
- Suggest new context menu modules
- Help with localization to additional languages

---

**Made with ❤️ by Segfault**