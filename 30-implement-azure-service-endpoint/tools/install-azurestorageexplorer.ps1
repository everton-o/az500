<#
    Author: Everton Oliveira
    Description: Install Chocolatey and Azure Storage Explorer
#>


# install chocolatey if not exists
if(-not((Get-Command choco -ErrorAction SilentlyContinue))){
    Write-Output "Seems Chocolatey is not installed, installing now.."
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else{
    Write-Output "Chocolatey is already installed"
}


# install azure storage explorer
choco install microsoftazurestorageexplorer -y

