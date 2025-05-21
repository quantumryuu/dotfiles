#Functions
Function Ex { 
    Exit 
}

Function Get-Ips {
    $Publicip = (Curl Icanhazip.Com).Content
    $Localip = (Get-Netipaddress | Where-Object { $_.Addressstate -Eq "Preferred" -And $_.Validlifetime -Lt "24:00:00" }).Ipaddress
    Write-Host "Public Ip: $Publicip `Rlocal Ip: $Localip"
}

Function Reload {
    . $Profile
}

Function Update-Dotfiles {
    $Dotfile = (Curl Https://Raw.Githubusercontent.Com/Kristocopani/Dotfiles/Main/Windows%20terminal/Install.Ps1).Content
    If ((Get-Content $Profile) -Ne $Dotfile) {
        Write-Host "Same"
    }
}

Function .. {
    Set-Location ..
}
Function ... {
    Set-Location ../..
}
Function .... {
    Set-Location ../../..
}
Function ..... {
    Set-Location ../../../..
}
Function ...... {
    Set-Location ../../../../..
}

Function Scripts {
    Set-Location ~/Projects
}

Function Temp {
    Set-Location C:\Temp
}

# Aliases
Set-Alias -Name Q -Value Ex
Set-Alias -Name C -Value "Clear"
Set-Alias -Name Ip -Value "Get-Ips"
Set-Alias -Name Dotfiles -Value Update-Dotfiles
Set-Alias -Name tmep -Value Temp


#Run Functions
Import-Module -Name Psreadline
Set-Psreadlineoption -Historynoduplicates
Set-Psreadlinekeyhandler -Key Tab -Function Menucomplete
Set-Psreadlineoption -Predictionsource History
#Set-Psreadlinekeyhandler -Key Uparrow -Function Historysearchbackward
#Set-Psreadlinekeyhandler -Key Downarrow -Function Historysearchforward
Clear


Import-Module -Name PSReadline
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource History
#Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
#Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
clear
Invoke-Expression (&starship init powershell)
