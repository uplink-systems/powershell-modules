# configure terminal window size to match requirements for logo and message
$PsWindow = (Get-Host).UI.RawUI         # Get the PowerShell Host's UI.
$NewBufferSize = $PsWindow.BufferSize   # Get the UI's current Buffer Size.
$NewBufferSize.Width = 150              # Set the new buffer's width to 150 columns.
$NewBufferSize.Height = 100             # Set the new buffer's height to 100 lines.
$PsWindow.BufferSize = $NewBufferSize   # Set the new Buffer Size as active.
$NewWindowSize = $PsWindow.WindowSize   # Get the UI's current Window Size.
$NewWindowSize.Width = 150              # Set the new Window width to 150 columns.
$NewWindowSize.Height = 50              # Set the new Window height to 50 lines.
$PsWindow.WindowSize = $NewWindowSize   # Set the new Window Size as active.

# start importing module: create logo and output to console...
$ModuleImportLogo=@"

    ___   ___ _______ ___    ____ __  ___ ____ ___      ________ ___   ____ _______ _________ _______ ___  ____   ________
   /  /  /  /   __   /  /   /   /   |/   /   /   /     /  _____/   /  /   /  _____/__    ___/   ____/    |/    | /  _____/
  /  /  /  /   /_/  /  /   /   /    |   /       /     /____   /   /__/   /____      /   /  /   __/ /     |     |/____   
 /  /__/  /   _____/  /___/   /   |    /   |   |     _____/  /___    ___/____/  /  /   /  /   /___/   |    |   |____/  /
/________/___/    /______/___/___/|___/___/|___|    /_______/   /___/  /_______/  /___/  /_______/___/|___/|___|______/

"@
Write-Host -Object $ModuleImportLogo -ForegroundColor Cyan

# set variables for public and private function import...
$DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar
$ModuleName = (Get-Item -Path $PSCommandPath).Basename
$ModuleManifest = $PSScriptRoot + $DirectorySeparator + $ModuleName + '.psd1'
$CurrentManifest = Test-ModuleManifest -Path $ModuleManifest

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

# update the manifest's values for 'AliasesToExport' and 'FunctionsToExport'...
$PublicFunctionsAdded = $PublicFunctions | Where-Object {$_.BaseName -notin $CurrentManifest.ExportedFunctions.Keys}
$PublicFunctionsRemoved = $CurrentManifest.ExportedFunctions.Keys | Where-Object {$_ -notin $PublicFunctions.BaseName}
$PublicAliasesAdded = $PublicAliases | Where-Object {$_ -notin $CurrentManifest.ExportedAliases.Keys}
$PublicAliasesRemoved = $CurrentManifest.ExportedAliases.Keys | Where-Object {$_ -notin $PublicAliases}
if ($PublicFunctionsAdded -or $PublicFunctionsRemoved -or $PublicAliasesAdded -or $PublicAliasesRemoved) {
    try {
        $UpdateModuleManifestParams = @{}
        $UpdateModuleManifestParams.Add('Path', $ModuleManifest)
        $UpdateModuleManifestParams.Add('ErrorAction', 'Stop')
        if ($PublicAliases.Count -gt 0) { $UpdateModuleManifestParams.Add('AliasesToExport', $PublicAliases) }
        if ($PublicFunctions.Count -gt 0) { $UpdateModuleManifestParams.Add('FunctionsToExport', $PublicFunctions.BaseName) }
        Update-ModuleManifest @updateModuleManifestParams
    }
    catch {
        $_ | Write-Error
    }
}

# complete importing module: set window title and output info message to console...
$ModuleManifestHashTable = Import-PowerShellDataFile -Path $ModuleManifest
try {$host.UI.RawUI.WindowTitle="$ModuleName $($ModuleManifestHashTable.ModuleVersion)"}
catch {}
$ModuleImportMessage=@"
PowerShell module '$ModuleName' version $($ModuleManifestHashTable.ModuleVersion). Developed and maintained by $($ModuleManifestHashTable.Author).
This module is licensed under the following conditions: $($($($ModuleManifestHashTable.PrivateData).PSData).LicenseUri).
"@
# write composed logo and message to console...
Write-Host -Object $ModuleImportMessage -ForegroundColor DarkGray
Write-Host
