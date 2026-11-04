function Q { exit }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function home { Set-Location $HOME }
function temp { Set-Location "C:\temp" }
function docs { Set-Location "$HOME\Documents" }
function dl { Set-Location "$HOME\Downloads" }
function myip { Invoke-RestMethod -Uri "https://api.ipify.org" }
function reload { . $PROFILE }

function ll { Get-ChildItem -Force @args }

function touch {
    foreach ($path in $args) {
        if (Test-Path $path) {
            (Get-Item $path).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $path | Out-Null
        }
    }
}

function which {
    $command = Get-Command $args[0] -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { return }
    # Programs have a path in .Source; functions and aliases have their body or target in .Definition
    if ($command.CommandType -eq 'Application') { $command.Source } else { $command.Definition }
}

Set-Alias cz chezmoi

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Import-Module -Name Terminal-Icons

# Skipped in a terminal opened before winget put Starship on PATH
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
