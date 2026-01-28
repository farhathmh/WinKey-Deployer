# --- Admin Elevation Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "===========================================================" -ForegroundColor Red
    Write-Host " ERROR: ADMINISTRATIVE PRIVILEGES REQUIRED" -ForegroundColor Red
    Write-Host "===========================================================" -ForegroundColor Red
    Write-Host "This tool modifies system licensing and hostname settings."
    Write-Host "Please right-click the file and select 'Run as Administrator'."
    Write-Host "`nPress any key to exit..."
    $null = [System.Console]::ReadKey($true)
    Exit
}

function Get-SystemInfo {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        return @{ Version = $os.Caption }
    } catch { return @{ Version = "Unknown" } }
}

function Show-Menu {
    Clear-Host
    $info = Get-SystemInfo
    $currentName = $env:COMPUTERNAME
    
    Write-Host "================= Windows Management Tool =================" -ForegroundColor Cyan
    Write-Host " Hostname:    $currentName" -ForegroundColor Yellow
    Write-Host " OS Version:  $($info.Version)" -ForegroundColor White
    Write-Host "===========================================================" -ForegroundColor Cyan
    
    Write-Host "1. Install Product Key & Activate" -ForegroundColor White
    Write-Host "   - Installs a new license and binds it to the Hardware ID (HWID)."
    Write-Host "   - Use this to bypass manual hardware ID checks and activate online."
    
    Write-Host "`n2. Verify Activation Status" -ForegroundColor White
    Write-Host "   - Performs a detailed check of the current licensing integrity."
    Write-Host "   - Displays the license status and activation expiration info."
    
    Write-Host "`n3. Rename Computer Hostname" -ForegroundColor White
    Write-Host "   - Change the machine name after imaging or deployment."
    Write-Host "   - Allows for random naming or specific company formats."
    
    Write-Host "`n`n" # 2 Line Gap
    
    Write-Host -NoNewline "99. "
    Write-Host "Previous Activation Cleanup" -ForegroundColor Red
    Write-Host "    - Clears previous Hardware ID bindings and licensing state."
    Write-Host "    - Resolves persistent activation errors by resetting the software"
    Write-Host "      protection platform and removing cached product keys."
    
    Write-Host "`n0. Exit"
    Write-Host "-----------------------------------------------------------"
    Write-Host " Created by: Farhath Manas" -ForegroundColor Gray
    Write-Host " Contact:    farhathmh@gmail.com" -ForegroundColor Gray
    Write-Host "-----------------------------------------------------------"
}

function Get-MaskedKey {
    $key = ""
    Write-Host "`nEnter 25-Character Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)" -ForegroundColor Gray
    Write-Host "Product Key: " -NoNewline -ForegroundColor Cyan
    
    while ($true) {
        $char = [System.Console]::ReadKey($true)
        
        # Handle Backspace
        if ($char.Key -eq 'Backspace' -and $key.Length -gt 0) {
            if ($key.EndsWith("-")) {
                $key = $key.Substring(0, $key.Length - 2)
                Write-Host "`b`b  `b`b" -NoNewline
            } else {
                $key = $key.Substring(0, $key.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
        }
        # Handle Enter - Only allow if key is exactly 25 chars (ignoring hyphens)
        elseif ($char.Key -eq 'Enter') {
            if ($key.Replace("-", "").Length -eq 25) { break }
            else { 
                Write-Host "`n[!] Error: Key must be exactly 25 characters." -ForegroundColor Red
                Write-Host "Product Key: $key" -NoNewline -ForegroundColor Cyan
            }
        }
        # Input Logic - Hard limit at 25 alphanumeric characters
        elseif ([char]::IsLetterOrDigit($char.KeyChar)) {
            $rawLength = $key.Replace("-", "").Length
            if ($rawLength -lt 25) {
                $key += $char.KeyChar.ToString().ToUpper()
                Write-Host $char.KeyChar.ToString().ToUpper() -NoNewline
                
                # Auto-hyphenate logic
                $newRawLength = $key.Replace("-", "").Length
                if ($newRawLength % 5 -eq 0 -and $newRawLength -lt 25) {
                    $key += "-"
                    Write-Host "-" -NoNewline
                }
            }
        }
    }
    Write-Host "`n[OK] Key captured. Processing..." -ForegroundColor Green
    return $key
}

function Invoke-Activation {
    $finalKey = Get-MaskedKey
    Write-Host "[!] Contacting Microsoft Licensing Servers..." -ForegroundColor Yellow
    
    try {
        $service = Get-CimInstance -ClassName SoftwareLicensingService
        Invoke-CimMethod -InputObject $service -MethodName InstallProductKey -Arguments @{ProductKey = $finalKey} -ErrorAction Stop
        Invoke-CimMethod -InputObject $service -MethodName RefreshLicenseStatus | Out-Null
        
        $windowsProduct = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.ApplicationID -eq "55c28237-2095-460f-991a-7e5043a9686c" }
        Invoke-CimMethod -InputObject $windowsProduct -MethodName Activate -ErrorAction Stop
        
        Write-Host "[+] Activation Successful!" -ForegroundColor Green
        Pause
        Invoke-RenameLogic
    }
    catch {
        Write-Host "`n[!] Activation Unsuccessful." -ForegroundColor Red
        Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor White
        Pause
    }
}

function Invoke-RenameLogic {
    Write-Host "`n--- Computer Rename Menu ---" -ForegroundColor Cyan
    Write-Host "Current Hostname: $($env:COMPUTERNAME)"
    Write-Host "1. Random Name (DESKTOP-XXXXXXX)"
    Write-Host "2. Custom Format (Example: BCS-TECH-001)"
    Write-Host "3. Keep Current Name"
    $choice = Read-Host "Select an option"
    
    $newName = ""
    if ($choice -eq '2') {
        $newName = Read-Host "Enter the new machine name"
    } elseif ($choice -eq '3') {
        return
    } else {
        $random = -join ((48..57) + (65..90) | Get-Random -Count 7 | ForEach-Object {[char]$_})
        $newName = "DESKTOP-$random"
    }

    if ($newName) {
        try {
            Rename-Computer -NewName $newName -Force -ErrorAction Stop
            Write-Host "Renamed to $newName." -ForegroundColor Green
            $reboot = Read-Host "Restart now? (Y/N)"
            if ($reboot -eq 'Y') { Restart-Computer }
        } catch {
            Write-Host "Rename failed: $($_.Exception.Message)" -ForegroundColor Red
            Pause
        }
    }
}

function Invoke-Cleanup {
    Write-Host "`n[!] Resetting Windows Activation State & HWID Bindings..." -ForegroundColor Red
    try {
        $Service = Get-CimInstance -ClassName SoftwareLicensingService
        Invoke-CimMethod -InputObject $Service -MethodName UninstallProductKey
        Invoke-CimMethod -InputObject $Service -MethodName ClearProductKeyFromRegistry
        Invoke-CimMethod -InputObject $Service -MethodName Rearm
        Write-Host "`n[+] Cleanup complete. Licensing state reset." -ForegroundColor Green
        Write-Host "Please reboot before re-activation." -ForegroundColor Yellow
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pause
}

# --- Main Loop ---
do {
    Show-Menu
    $choice = Read-Host "Select an Option"
    switch ($choice) {
        '1' { Invoke-Activation }
        '2' { 
            Write-Host "`n--- Detailed Status ---" -ForegroundColor Cyan
            cscript //nologo c:\windows\system32\slmgr.vbs /dli
            Pause 
        }
        '3' { Invoke-RenameLogic }
        '99' { Invoke-Cleanup }
    }
} while ($choice -ne '0')
