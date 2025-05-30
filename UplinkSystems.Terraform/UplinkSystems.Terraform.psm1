# start importing module: create logo and output to console...
$ModuleImportLogo=@"
    ___   ___ ______ ___    ___ _  __ ___ __      ________ __   ___ _______ ________ ______ __  ___   ________
   /  /  /  /  __   /  /   /  /  |/  /  /  /     /  _____/  /  /  /  _____/__   ___/  ____/   |/   | /  _____/
  /  /  /  /  /_/  /  /   /  /   |  /     /     /____   /  /__/  /____      /  /  /  __/ /    |    |/____
 /  /__/  /  _____/  /___/  /  |   /  |  |     _____/  /__    __/____/  /  /  /  /  /___/  |    |  |____/  /
/________/__/    /______/__/__/|__/__/|__|    /_______/  /___/ /_______/  /__/  /______/__/|___/|__|______/

"@
Write-Host -Object $ModuleImportLogo -ForegroundColor Cyan

# set variables for public and private function import...
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar
$ModuleName = (Get-Item -Path $PSCommandPath).Basename
$ModuleManifest = $PSScriptRoot + $DirectorySeparator + $ModuleName + '.psd1'

# get public functions from .ps1 files in module's private subfolder...
$PrivateFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Private'
$PrivateFunctions = Get-ChildItem -Path $PrivateFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$PrivateFunctions | ForEach-Object { . $_.FullName }

# get public functions from .ps1 files in module's public subfolder...
$PublicFunctionsPath = $PSScriptRoot + $DirectorySeparator + 'Public'
$PublicFunctions = Get-ChildItem -Path $PublicFunctionsPath | Where-Object {$_.Extension -eq '.ps1'}
$PublicFunctions | ForEach-Object { . $_.FullName }
$PublicAliases = @()

# export all public functions and their aliases if available; the command has already been sourced in above...
$PublicFunctions | ForEach-Object {
    $PublicAlias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
    if ($PublicAlias) {
        $PublicAliases += $PublicAlias
        Export-ModuleMember -Function $_.BaseName -Alias $PublicAlias
    }
    else {
        Export-ModuleMember -Function $_.BaseName
    }
}

# complete importing module: set window title and output info message to console...
$ModuleManifestHashTable = Import-PowerShellDataFile -Path $ModuleManifest
try {$host.UI.RawUI.WindowTitle="$ModuleName $($ModuleManifestHashTable.ModuleVersion)"}
catch {Write-Error}
$ModuleImportMessage=@"
PowerShell module '$ModuleName' version $($ModuleManifestHashTable.ModuleVersion). Developed and maintained by $($ModuleManifestHashTable.Author).
This module is licensed under the following conditions: $($($($ModuleManifestHashTable.PrivateData).PSData).LicenseUri).
"@
# write composed logo and message to console...
Write-Host -Object $ModuleImportMessage -ForegroundColor DarkGray
Write-Host
