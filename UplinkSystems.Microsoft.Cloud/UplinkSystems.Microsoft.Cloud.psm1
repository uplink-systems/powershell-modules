# start importing module: create logo and output to console...
$ModuleImportLogo=@"

    ___   ___ _______ ___    ____ __  ___ ____ ___      ________ ___   ____ _______ _________ _______ ___  ____   ________
   /  /  /  /   __   /  /   /   /   |/   /   /   /     /  _____/   /  /   /  _____/__    ___/   ____/    |/    | /  _____/
  /  /  /  /   /_/  /  /   /   /    |   /       /     /____   /   /__/   /____      /   /  /   __/ /     |     |/____
 /  /__/  /   _____/  /___/   /   |    /   |   |     _____/  /___    ___/____/  /  /   /  /   /___/   |    |   |____/  /
/________/___/    /______/___/___/|___/___/|___|    /_______/   /___/  /_______/  /___/  /_______/___/|___/|___|______/

"@
Write-Host -Object $ModuleImportLogo -ForegroundColor Blue

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
try {$Host.UI.RawUI.WindowTitle="$ModuleName $($ModuleManifestHashTable.ModuleVersion)"}
catch {}
$ModuleImportMessage=@"
PowerShell module '$ModuleName' version $($ModuleManifestHashTable.ModuleVersion). Developed and maintained by $($ModuleManifestHashTable.Author).
This module is licensed under the following conditions: $($($($ModuleManifestHashTable.PrivateData).PSData).LicenseUri).`n
"@
# write composed message to console...
Write-Host -Object $ModuleImportMessage -ForegroundColor DarkGray