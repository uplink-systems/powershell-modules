function Update-OneDriveClientOrganizationUserRegistryKey {

    <#
        .SYNOPSIS
        The function replaces all registry keys/names/values containing a wrong OneDrive
        organization name.
        .DESCRIPTION
        The function looks for all registry keys, registry names (entries) and registry 
        values that still contain the old (source) organization name and replaces it with
        the name of the new (target) organization. As the function's purpose is to replacy
        strings it can only process objects of type REG_SZ and skips all others silently. 
        .PARAMETER SourceOrganizationName [String]
        The mandatory parameter -SourceOrganizationName represents the organization name
        of the source tenant.
        Alias: Source
        .PARAMETER TargetOrganizationName [String]
        The mandatory parameter -TargetOrganizationName represents the organization name
        of the target tenant.
        Alias: Target
        .PARAMETER Scope [String]
        The optional parameter -Scope can be used to specify if the function shall process
        the registry for all users (HKU:) instead of the the currently logged on user only
        (HKCU:). Admin permissions are required to process all users.
        Defaults to: CurrentUser
        .PARAMETER DryRun [Switch]
        The optional parameter -DryRun can be used to run the replacement in dry-run mode
        (simulation) only. No registry keys, names or values are changed in this mode.
        Only output is generated containing the infos what would have changed.
        .PARAMETER Silent [Switch]
        The optional parameter -Silent can be used to reduce the level of outputs to the
        console to get only summary output.
        .OUTPUTS
        System.String
        .NOTES
        The function should be run AFTER the change of the organization took place and AFTER
        the OneDrive client was disconnected from the source organization and connected to
        the target organization. Its purpose is to only clean up orphaned registry settings
        and should not be used to do the switch over itself! This could break the OneDrive
        connection. Be careful!
        .EXAMPLE
        Update-OneDriveClientOrganizationUserRegistryKey -SourceOrganizationName "Company 1 Corp." -TargetOrganizationName "Company 2 Inc."
        .EXAMPLE
        Update-OneDriveClientOrganizationUserRegistryKey "Company 1 Corp." "Company 2 Inc." -DryRun -Scope AllUsers
        .EXAMPLE
        Update-OneDriveClientOrgUserRegKey -Source "Company 1 Corp." -Target "Company 2 Inc." -Silent
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Update-OneDriveClientOrgUserRegKey")]

    param(
        [Parameter(Mandatory=$true,Position=0)] [Alias("Source")] [String] $SourceOrganizationName,
        [Parameter(Mandatory=$true,Position=1)] [Alias("Target")] [String] $TargetOrganizationName,
        [Parameter(Mandatory=$false)] [ValidateSet("CurrentUser","AllUsers")] [String] $Scope = "CurrentUser",
        [Parameter(Mandatory=$false)] [Switch] $DryRun,
        [Parameter(Mandatory=$false)] [Switch] $Silent
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        Write-Host
        if ($Silent) {$InformationPreference = SilentlyContinue} else {$InformationPreference = Continue}
        switch ($Scope) {
            "CurrentUser" {
                $RegItems = Get-ChildItem -ErrorAction SilentlyContinue -Path  "HKCU:\" -Recurse | Select-Object Name,Property,PSPath
            }
            "AllUsers" {
                if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544') {
                    $RegItems = Get-ChildItem -ErrorAction SilentlyContinue -Path  "HKU:\" -Recurse | Select-Object Name,Property,PSPath
                }
                else {
                    Write-Information -MessageData "INFO: insufficient permissions to execute for all users..." -InformationAction Continue
                    $RegItems = $null
                }
            }
        }
    }

    process {
        Write-Information -MessageData "`n================================================================"
        Write-Information -MessageData "Processing registry values... please wait..."
        Write-Infomration -MessageData "================================================================"
        Start-Sleep -Seconds 2
        $UpdatedValues = 0
        $RegItems | ForEach-Object {
            try { Get-ItemProperty -Path $_.PSPath } 
            catch { } } | ForEach-Object {
            $HKCURegPath = $_.PSPath
            $_.PSObject.Properties | ForEach-Object {
                if ($_.Value -like "*OneDrive - "+$SourceOrganizationName+"*") {
                    Write-Informaton -MessageData "Registry Key: `t`t $HKCURegPath"
                    Write-Informaton -MessageData "Registry Name: `t`t $($_.Name)"
                    Write-Informaton -MessageData "Registry value (old): `t $($_.Value)"
                    $SourceTenantValue = $_.Value
                    $TargetTenantValue = $SourceTenantValue -replace "$SourceOrganizationName", "$TargetOrganizationName"
                    Write-Informaton -MessageData "Registry value (new): `t $TargetTenantValue"
                    try {
                        if ($DryRun) {
                            Set-ItemProperty -Path $HKCURegPath -Name $_.Name -Value $TargetTenantValue -WhatIf
                        }
                        else {
                            Set-ItemProperty -Path $HKCURegPath -Name $_.Name -Value $TargetTenantValue
                        }
                        $UpdatedValues = $UpdatedValues + 1
                    }
                    catch {
                        Write-Host -Object "Error: $($Error[0].Exception.Message)" -ForegroundColor Red
                    }
                    Write-Information -MessageData "================================================================"
                }
            }
        }
        Write-Information -MessageData "`n================================================================"
        Write-Information -MessageData "Processing registry names/entries... please wait..."
        Write-Information -MessageData "================================================================"
        Start-Sleep -Seconds 2
        $UpdatedNames = 0 
        $RegItems | ForEach-Object {
            try { Get-ItemProperty -Path $_.PSPath } 
            catch { } } | ForEach-Object {
            $HKCURegPath = $_.PSPath
            $_.PSObject.Properties | ForEach-Object {
                if ($_.Name -like "*OneDrive - "+$SourceOrganizationName+"*") {
                    Write-Information -MessageData "Registry Key: `t`t $HKCURegPath"
                    Write-Information -MessageData "Registry Name (old): `t $($_.Name)"
                    $SourceTenantName = $_.Name
                    $TargetTenantName = $SourceTenantName -replace "$SourceOrganizationName", "$TargetOrganizationName"
                    Write-Information -MessageData "Registry name (new): `t $TargetTenantName"
                    try {
                        if ($DryRun) {
                            Rename-ItemProperty -Path $HKCURegPath -Name $SourceTenantName -NewName $TargetTenantName -WhatIf
                        }
                        else {
                            Rename-ItemProperty -Path $HKCURegPath -Name $SourceTenantName -NewName $TargetTenantName
                        }
                        $UpdatedNames = $UpdatedNames + 1
                    }
                    catch {
                        Write-Host -Object "Error: $($Error[0].Exception.Message)" -ForegroundColor Red
                    }
                    Write-Information -MessageData "================================================================"
                }
            }
        }
        Write-Information -MessageData "`n================================================================"
        Write-Information -MessageData "Processing registry keys... please wait..."
        Write-Information -MessageData "================================================================"
        Start-Sleep -Seconds 2
        $UpdatedKeys = 0
        $RegItems | ForEach-Object {
            try { Get-ItemProperty -Path $_.PSPath } 
            catch { } } | ForEach-Object {
            $HKCURegPath = $_.PSPath
            $_.PSObject.Properties | ForEach-Object {
                if ($HKCURegPath -like "*OneDrive - "+$SourceOrganizationName+"*") {
                    Write-Information -MessageData "Registry Key (old): `t $HKCURegPath"
                    $SourceTenantKey = $HKCURegPath
                    $TargetTenantKey = $SourceTenantKey -replace "$SourceOrganizationName", "$TargetOrganizationName"
                    Write-Information -MessageData "Registry key (new): `t $TargetTenantKey"
                    try {
                        if ($DryRun) {
                            Rename-Item -Path $SourceTenantKey -NewName $TargetTenantKey -WhatIf
                        }
                        else {
                            Rename-Item -Path $SourceTenantKey -NewName $TargetTenantKey
                        }
                        $UpdatedKeys = $UpdatedKeys + 1
                    }
                    catch {
                        Write-Host -Object "Error: $($Error[0].Exception.Message)" -ForegroundColor Red
                    }
                    Write-Information -MessageData "================================================================"
                }
            }
        }
    }

    end {
        Write-Information -MessageData "`n================================================================" -InformationAction Continue
        if ($DryRun) {
            Write-Information -MessageData "OneDrive registry organization replacement finished (dry-run only):" -ForegroundColor Gray
            Write-Information -MessageData "-> updated registry keys: `t" -ForegroundColor DarkGray -NoNewline; Write-Host -Object "$UpdatedKeys" -ForegroundColor White
            Write-Information -MessageData "-> updated registry names: `t" -ForegroundColor DarkGray -NoNewline; Write-Host -Object "$UpdatedNames" -ForegroundColor White
            Write-Information -MessageData "-> updated registry values: `t" -ForegroundColor DarkGray -NoNewline;Write-Host -Object "$UpdatedValues" -ForegroundColor White
            Write-Information -MessageData "================================================================`n" -ForegroundColor White
        }
        else {
            Write-Information -MessageData "OneDrive registry organization replacement finished:" -ForegroundColor Gray
            Write-Information -MessageData "-> updated registry keys: `t" -ForegroundColor DarkGray -NoNewline; Write-Host -Object "$UpdatedKeys" -ForegroundColor White
            Write-Information -MessageData "-> updated registry names: `t" -ForegroundColor DarkGray -NoNewline; Write-Host -Object "$UpdatedNames" -ForegroundColor White
            Write-Information -MessageData "-> updated registry values: `t" -ForegroundColor DarkGray -NoNewline;Write-Host -Object "$UpdatedValues" -ForegroundColor White
            Write-Information -MessageData "================================================================`n" -ForegroundColor White
        }
        $ErrorActionPreference = $Preferences[0]
        $InformationPreference = $Preferences[1]
        return $Error.Count
    }

}