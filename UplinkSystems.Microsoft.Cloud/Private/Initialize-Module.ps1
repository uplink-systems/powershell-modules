function Initialize-Module {

    <#
        .SYNOPSIS
        The function initializes a specified module to PowerShell sesion.
        .DESCRIPTION
        The function initializes the a specified module to the current PowerShell
        session.
        .PARAMETER SharePointOnline
        The SPO module does not natively support PS Core. Therefore the function
        checks the current session's major version and edition and imports the
        module in PS Desktop and in PS Core with required parameters to work in
        compatibility mode. It tries to install the module in current user scope
        if it's missing on the system and tries to remove already imported SPO
        modules prior to import it again to avoid conflicts.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Online.Sharepoint.Management
        .EXAMPLE
        Initialize-Module -SharePointOnline
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Initialize-SPO")]

    param(
        [Parameter(Mandatory=$false,ParameterSetName="SharePointOnline")] [Alias("SPO","MOSM")] [Switch] $SharePointOnline
    )

    switch ($PSCmdlet.ParameterSetName) {
        "SharePointOnline" {
            # check if SPO module is installed, try to install if missing...
            if (-not(Get-Module -Name "Microsoft.Online.SharePoint.PowerShell" -ListAvailable)) {
                try{
                    Install-Module -Name "Microsoft.Online.SharePoint.PowerShell" -Scope CurrentUser -AcceptLicense -AllowClobber -Force -ErrorAction Stop
                }
                catch {return $false}
            }
            # check if SPO module is already imported; try to remove if $true...
            if (Get-Module -Name "Microsoft.Online.SharePoint.PowerShell") {
                try {
                    Remove-Module -Name "Microsoft.Online.SharePoint.PowerShell" -Force -ErrorAction Stop | Out-Null
                }
                catch {return $false}
            }
            # import SPO module with parameters depending on PowerShell version/edition...
            try {
                if (($PSVersionTable.PSVersion.Major -le "5") -and ($PSEdition -eq "Desktop")) {
                    Import-Module -Name "Microsoft.Online.SharePoint.PowerShell" -Global -Force -ErrorAction Stop | Out-Null
                    return $true
                }
                elseif (($PSVersionTable.PSVersion.Major -gt "5") -and ($PSEdition -eq "Core")) {
                    Import-Module -Name "Microsoft.Online.SharePoint.PowerShell" -UseWindowsPowerShell -Global -Force -ErrorAction Stop | Out-Null
                    return $true
                }
                else {return $false}
            }
            catch {return $false}
        }
        default {
            Write-Error -Message "No valid module parameter specified..." -Category InvalidArgument
            return $false
        }
    }

}