# WSL Tweaks Script with Auto-Elevation, Log Output, and WSL Shutdown

# Relaunch as admin if needed
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Relaunching as Administrator..."
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- WSL Checks ---
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

if ($wslFeature.State -ne "Enabled") {
    Write-Host ""
    Write-Host "WSL is not installed or enabled."
    Write-Host "Enable it with:"
    Write-Host "   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

if ($vmFeature.State -ne "Enabled") {
    Write-Host ""
    Write-Host "WSL 2 (VirtualMachinePlatform) is not enabled."
    Write-Host "Enable it with:"
    Write-Host "   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
}

# --- Write WSL Config ---
$wslPath = "$env:USERPROFILE\.wslconfig"

@"
[wsl2]
memory=4GB
processors=4
swap=0
localhostForwarding=true
"@ | Out-File -Encoding ASCII -FilePath $wslPath

Write-Host ""
Write-Host ".wslconfig created at $wslPath"
Write-Host "Shutting down WSL to apply changes..."

# --- Shutdown WSL ---
wsl --shutdown

Write-Host "`n✅ All done! WSL was shut down successfully."
Read-Host -Prompt "Press Enter to close this window"
