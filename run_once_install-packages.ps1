# run_once_install-packages.ps1
#
# chezmoi runs this during `chezmoi apply`, once per machine, and again
# whenever the contents of this file change. It is safe to re-run:
# anything already in place is skipped.

# ---------------------------------------------------------------------------
# 1. PowerShell profile loader
# ---------------------------------------------------------------------------
# The real profile is managed by chezmoi at ~\.config\powershell\profile.ps1.
# $PROFILE lives under Documents, which may or may not be redirected to
# OneDrive, so write a one-line loader wherever Documents is on this machine.

$loader = '. "$HOME\.config\powershell\profile.ps1"'
$docs   = [Environment]::GetFolderPath('MyDocuments')

# 'PowerShell' = PowerShell 7, 'WindowsPowerShell' = Windows PowerShell 5.1.
# Remove one if you only want the profile loaded in the other.
foreach ($edition in 'PowerShell', 'WindowsPowerShell') {
    $profilePath = Join-Path $docs "$edition\Microsoft.PowerShell_profile.ps1"

    if ((Test-Path $profilePath) -and
        (Select-String -Path $profilePath -SimpleMatch '.config\powershell\profile.ps1' -Quiet)) {
        Write-Host "[skip]    loader already in $profilePath"
        continue
    }

    # Appends if a profile already exists, so nothing on the machine is lost
    New-Item -ItemType Directory -Force (Split-Path $profilePath) | Out-Null
    Add-Content -Path $profilePath -Value $loader
    Write-Host "[profile] loader written to $profilePath"
}

# ---------------------------------------------------------------------------
# 2. Packages
# ---------------------------------------------------------------------------
# Edit this list to taste. Find IDs with: winget search <name>

$packages = @(
    'Microsoft.PowerShell'          # PowerShell 7
    'Microsoft.WindowsTerminal'
    'Starship.Starship'
    'DEVCOM.JetBrainsMonoNerdFont'  # Starship's icons need a Nerd Font; any one works
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then run 'chezmoi apply' again."
    exit 1
}

$failed = @()

foreach ($id in $packages) {
    # winget list exits non-zero when the package is not installed
    winget list --id $id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[skip]    $id is already installed"
        continue
    }

    Write-Host "[install] $id"
    winget install --id $id --exact --source winget --silent `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        $failed += $id
    }
}

if ($failed.Count -gt 0) {
    # A non-zero exit tells chezmoi the script failed, so it runs again on the next apply
    Write-Host "Failed to install: $($failed -join ', ')"
    exit 1
}

Write-Host "Done. Open a new terminal so PATH changes take effect."