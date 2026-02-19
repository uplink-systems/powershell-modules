
function Remove-SPOPersonalSite {

    <#
        .SYNOPSIS
        The function removes a SPO personal site.
        .DESCRIPTION
        The function removes a SPO personal site (OneDrive site) of a specified user either
        as soft delete or as hard delete. This can be usefull e.g. during Cross-Tenant 
        migrations where a SPO personal site already exists in the target tenant for an
        unknown reason.
        .PARAMETER UserPrincipalName [String]
        The mandatory parameter -UserPrincipalName specifies the owner of a SPO personal site
        to delete.
        Alias: UPN
        .PARAMETER TenantName [String]
        The mandatory parameter -TenantlName specifies the tenant name to connect to. The 
        value must be the tenant component of the initial M365 domain name (e.g. the parameter
        is "company" for "company.onmicrosoft.com" initial domain)
        Alias: Tenant
        .PARAMETER SoftDelete [Switch]
        The optional parameter -SoftDelete enables to only soft-delete the SPO personal site.
        Otherwise the SPO personal site will be hard-deleted with the option to restore.
        .PARAMETER Interactive [Switch]
        The optional parameter -Interactive enables interaction while executing the function.
        The option can be used  the SPO personal site is not empty. With $Interactive enabled
        the removal of the site can be enforced by a user input. Otherwise the function will
        skip the removal automatically and treat the result as failed.
        .PARAMETER Silent [Switch]
        The optional parameter -Silent suppresses all console messages except required messages
        in interactive mode. Error messages are not affected by the parameter and are never
        suppressed.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Sharepoint.Online.Powershell
        .NOTES
        The function returns $true if the SPO personal site removal was successfull or if no
        SPO personal site exists. In any other case the function returns $false.
        .EXAMPLE
        Remove-SPOPersonalSite -UserPrincipalName "john.doe@company.com"
        .EXAMPLE
        Remove-SPOPersonalSite "john.doe@company.com" -SoftDelete -Interactive
        .EXAMPLE
        Get-MgUser -Filter "startswith(UserPrincipalName,'john')" | Remove-SPOPersonalSite
    #>

    [CmdletBinding(PositionalBinding=$false,DefaultParameterSetName='Get',HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Delete-SPOPersonalSite")]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [Alias("UPN")]
        [String] $UserPrincipalName,
        [Parameter(Mandatory=$true)]
        [Alias("Tenant")]
        [ValidateScript({if (-not($_.EndsWith(".onmicrosoft.com"))) {$true} else {throw "Invalid value: `"$_`"."}})]
        [String] $TenantName,
        [Parameter(Mandatory=$true)]
        [Alias("Owner")]
        [String] $AdminUpn,
        [Parameter(Mandatory=$false)]
        [Switch] $SoftDelete,
        [Parameter(Mandatory=$false)]
        [Switch] $Interactive,
        [Parameter(Mandatory=$false)]
        [Switch] $Silent
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        if ($Silent) {$InformationPreference = 'SilentlyContinue'} else {$InformationPreference = 'Continue'}
        Initialize-Module -SharePointOnline | Out-Null
        Connect-SPOService -Url "https://$TenantName-admin.sharepoint.com"
    }

    process {
        # get SPO personal site details and use result to check if connected; exit if not...
        Write-Host
        try {
            $SpoPersonalSite = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" -ErrorAction Stop | Where-Object {$_.Owner -eq "$UserPrincipalName"}
        }
        catch {
            Write-Host -Object "ERROR: not connected to SharePoint Online... exit..." -ForegroundColor Red
            return $false
        }
        # check if user has a SPO personal site, skip if no, proceed if yes...
        if (-not($SpoPersonalSite)) {
            Write-Information -MessageData "INFO: no SPO personal site found for account $UserPrincipalName... exit..."
            return $true
        }
        else {
            Write-Information -MessageData "INFO: SPO personal site found for account $UserPrincipalName... removing..."
            # remove site, but only if no storage in use; delete site finally, if -SoftDelete switch not enabled...
            if ($SpoPersonalSite.StorageUsageCurrent -eq 0) {
                Start-Sleep -Seconds 1
                try {
                    Set-SPOSite -Identity $SpoPersonalSite.Url -LockState Unlock -ErrorAction Stop
                    Set-SPOSite -Identity $SpoPersonalSite.Url -Owner $AdminUpn -ErrorAction Stop
                    Remove-SPOSite -Identity $SpoPersonalSite.Url -Confirm:$false -ErrorAction Stop
                    if (-not($SoftDelete)) {
                        Remove-SPODeletedSite -Identity $SpoPersonalSite.Url -Confirm:$false -ErrorAction Stop
                    }
                    Write-Information -MessageData "SUCCESS: SPO personal site removed..."
                    return $true
                }
                catch {
                    Write-Host -Object "ERROR: failed to remove SPO personal site..." -ForegroundColor Red
                    return $false
                }
            }
            elseif ($Interactive) {
                Write-Information -MessageData "WARNING: SPO personal site is not empty ($($SpoPersonalSite.StorageUsageCurrent) MB in use...)" -InformationAction Continue
                $RemoveNonEmptySite = Read-Host -Prompt "Remove SPO personal site anyway? [Y/N]: "
                switch ($RemoveNonEmptySite) {
                    "Y" {
                        # remove site, even if storage in use; delete site finally, if -SoftDelete switch not enabled...
                        Start-Sleep -Seconds 1
                        try {
                            Set-SPOSite -Identity $SpoPersonalSite.Url -LockState Unlock -ErrorAction Stop
                            Set-SPOSite -Identity $SpoPersonalSite.Url -Owner $AdminUpn -ErrorAction Stop
                            Remove-SPOSite -Identity $SpoPersonalSite.Url -Confirm:$false -ErrorAction Stop
                            if (-not($SoftDelete)) {
                                Remove-SPODeletedSite -Identity $SpoPersonalSite.Url -Confirm:$false -ErrorAction Stop
                            }
                            Write-Information -MessageData "SUCCESS: SPO personal site removed..."
                            return $true
                        }
                        catch {
                            Write-Host -Object "ERROR: failed to remove SPO personal site..." -ForegroundColor Red
                            return $false
                        }
                    }
                    default {
                        # skip removing site...
                        Write-Information -MessageData "INFO: skipped removing non-empty SPO personal site..."
                        Start-Sleep -Seconds 1
                        return $false
                    }
                }
            }
            else {
                # skip removing site...
                Write-Host -Object "ERROR: SPO personal site is not empty ($($SpoPersonalSite.StorageUsageCurrent) MB in use)... exit..." -ForegroundColor Red
                return $false
            }
        }
    }

    end {
        Disconnect-SPOService
        $ErrorActionPreference = $Preferences[0]
        $InformationPreference = $Preferences[1]
    }

}