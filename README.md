# WinKey-Deployer 🚀
**Automated Windows Activation & Naming for Bulk Retail Imaging**

Created by: **Farhath Manas** | [farhathmh@gmail.com](mailto:farhathmh@gmail.com)

---

## 🚀 The Motivation
As an IT Support professional, I frequently handle large-scale imaging and deployment of laptops and desktops. During this process, I encountered a significant technical bottleneck: **Hardware ID (HWID) Binding.**

### The Problem
When deploying a master image, the activation state of the source device is often "baked" into the clone. This creates a conflict when trying to apply new retail keys, as the system remains bound to the master device's identity. I found the standard **Sysprep** approach inefficient for our specific workflow because:
1. Sysprep resets the OOBE (Out-of-Box Experience), forcing time-consuming user profile re-creation.
2. Manually logging in to every machine just to run CMD/PowerShell activation codes is repetitive, boring, and slow.

### The Solution
I built **WinKey-Deployer** using my current knowledge and the requirements of the situation to bypass these hurdles. It allows technicians to strip previous HWID bindings and activate new retail keys instantly through a streamlined interface—without the need for Sysprep. I am open to suggestions, new ideas, or alternative technologies to make this process even more efficient.

## 🛠 Features
- **HWID Reset:** Strips previous hardware bindings to resolve persistent activation errors.
- **Smart Input:** Automatic hyphenation and a strict 25-character limit to eliminate typos.
- **Retail-Ready:** Optimized for high-speed retail key installation and online verification.
- **Post-Activation Naming:** Automated hostname changes (Random or Custom) to ensure network unique-identity (SID) compliance.
- **Zero-Halt Menu:** Optimized CIM/WMI queries for instant menu loading.

## 🖥️ Functional Overview
1. **Option 1: Install Key & Activate** - Uses `SoftwareLicensingService` via CIM to install the key.
   - Triggers an immediate online activation.
   - **Auto-Chain:** Leads directly to the Rename menu upon success.
2. **Option 2: Verify Status**
   - Performs a detailed check to confirm permanent activation status.
3. **Option 3: Rename Only**
   - Quick access to change hostnames using formats like `BCS-TECH-001`.
4. **Option 99: Previous Activation Cleanup** - The "Fix-it" button. Uninstalls current keys, clears registry cache, and performs a licensing `Rearm`.

---

## 🖥️ Terminal Output Simulation
This is the interactive interface users will see in the PowerShell console:

```text
================= Windows Management Tool =================
 Hostname:    DESKTOP-ABC1234
 OS Version:  Microsoft Windows 11 Pro
===========================================================
1. Install Product Key & Activate
   - Installs a new license and binds it to the Hardware ID (HWID).
   - Use this to bypass manual hardware ID checks and activate online.

2. Verify Activation Status
   - Performs a detailed check of the current licensing integrity.
   - Displays the license status and activation expiration info.

3. Rename Computer Hostname
   - Change the machine name after imaging or deployment.
   - Allows for random naming or specific company formats.


99. Previous Activation Cleanup
    - Clears previous Hardware ID bindings and licensing state.
    - Resolves persistent activation errors by resetting the software
      protection platform and removing cached product keys.

0. Exit
-----------------------------------------------------------
 Created by: Farhath Manas
 Contact:    farhathmh@gmail.com
-----------------------------------------------------------
Select an Option: _
```

---

## 📦 Compilation & Setup

### 1. Prepare PowerShell Environment
Windows restricts script execution by default. To run or compile this script, open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy Unrestricted -Force
```
### 2. Install the Compiler (ps2exe)
This tool requires the ps2exe module to convert the .ps1 script into a standalone .exe.
```powershell
Install-Module -Name ps2exe -Scope CurrentUser
```
### 2. Install the Compiler (ps2exe)
3. Building the Executable
Navigate to your project folder in PowerShell and run the build command.

Option A: Build with Admin Rights (Default/Recommended)
Since this tool modifies system registries and hostnames, it must run as Admin. This command builds the .exe with an embedded manifest that forces the Windows UAC prompt.
```powershell
Invoke-ps2exe .\src\WinKey-Deployer.ps1 .\WinKey-Deployer.exe -requireAdmin -title "WinKey-Deployer" -company "Farhath Manas" -description "Bulk Windows Activation Utility"
```

Option B: Build without Forced Admin
If you prefer to handle elevation manually via right-click:
```powershell
Invoke-ps2exe .\src\WinKey-Deployer.ps1 .\WinKey-Deployer.exe -title "WinKey-Deployer"
```

---
