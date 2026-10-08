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
# Edit this list to taste: package ID = the winget source it comes from.
# Apps live in 'winget', fonts in 'winget-font'. Find IDs with: winget search <name>

$packages = [ordered]@{
    'Microsoft.PowerShell'      = 'winget'        # PowerShell 7
    'Microsoft.WindowsTerminal' = 'winget'
    'Starship.Starship'         = 'winget'
    'ryanoasis.CaskaydiaCove'   = 'winget-font'   # Starship's icons need a Nerd Font; any one works
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then run 'chezmoi apply' again."
    exit 1
}

$failed = @()

foreach ($id in $packages.Keys) {
    $source = $packages[$id]

    # winget list exits non-zero when the package is not installed
    winget list --id $id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[skip]    $id is already installed"
        continue
    }

    Write-Host "[install] $id (from $source)"
    winget install --id $id --exact --source $source --silent `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        $failed += $id
    }
}

# ---------------------------------------------------------------------------
# 3. PowerShell modules
# ---------------------------------------------------------------------------
# Windows PowerShell 5.1 and PowerShell 7 keep their modules in separate
# folders, so the block below is run once in each of them.

$moduleScript = @'
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# Edit this list to taste: name = minimum version ('0.0' means any version)
$modules = [ordered]@{
    'Terminal-Icons' = '0.0'
    'PSReadLine'     = '2.2.0'   # Set-PSReadLineOption -PredictionSource etc. need 2.2+
}

if ($PSVersionTable.PSEdition -ne 'Core') {
    # Windows PowerShell 5.1 needs TLS 1.2 and the NuGet provider before Install-Module works
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $nuget = Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -ge [version]'2.8.5.201' }
    if (-not $nuget) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    }
}

foreach ($name in $modules.Keys) {
    $minimum = [version]$modules[$name]
    $have = Get-Module -ListAvailable -Name $name | Where-Object { $_.Version -ge $minimum }
    if ($have) {
        Write-Host "[skip]    $name is already installed"
        continue
    }

    Write-Host "[install] $name"
    Install-Module -Name $name -Scope CurrentUser -Force -SkipPublisherCheck
}
'@

# PATH is not refreshed yet if winget installed PowerShell 7 a moment ago,
# so fall back to its default install location
$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCommand) {
    $pwshPath = $pwshCommand.Source
} else {
    $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
}

$shells = [ordered]@{
    'Windows PowerShell 5.1' = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    'PowerShell 7'           = $pwshPath
}

$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($moduleScript))

foreach ($shell in $shells.Keys) {
    $exe = $shells[$shell]
    if (-not (Test-Path $exe)) {
        Write-Host "[skip]    $shell not found, so no modules installed for it"
        continue
    }

    Write-Host "Modules for ${shell}:"
    # -NoProfile matters: the profile imports these modules, which fails until they exist
    & $exe -NoProfile -NonInteractive -OutputFormat Text -EncodedCommand $encoded
    if ($LASTEXITCODE -ne 0) {
        $failed += "modules for $shell"
    }
}

# ---------------------------------------------------------------------------

if ($failed.Count -gt 0) {
    # A non-zero exit tells chezmoi the script failed, so it runs again on the next apply
    Write-Host "Failed to install: $($failed -join ', ')"
    exit 1
}

Write-Host "Done. Open a new terminal so PATH changes take effect."