function Q { exit }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function home { Set-Location $HOME }
function temp { Set-Location "C:\temp" }
function docs { Set-Location "$HOME\Documents" }
function dl { Set-Location "$HOME\Downloads" }
function myip { Invoke-RestMethod -Uri "https://api.ipify.org" }
function reload { . $PROFILE }
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Import-Module -Name Terminal-Icons

#oh-my-posh init pwsh --config 'm365princess' | Invoke-Expression
clear
Invoke-Expression (&starship init powershell)
