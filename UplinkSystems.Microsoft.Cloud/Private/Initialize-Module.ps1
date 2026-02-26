function Initialize-Module {

    <#
        .SYNOPSIS
        The function initializes a specified module to PowerShell sesion.
        .DESCRIPTION
        The function initializes the a specified module to the current PowerShell
        session.
        .PARAMETER ExchangeOnline
        tbd...
        .PARAMETER SharePointOnline
        The SPO module does not natively support PS Core. Therefore the function
        checks the current session's major version and edition and imports the
        module in PS Desktop and in PS Core with required parameters to work in
        compatibility mode. It tries to install the module in current user scope
        if it's missing on the system and tries to remove already imported SPO
        modules prior to import it again to avoid conflicts.
        .PARAMETER PSStyle
        The PSStyle module is used in versions prior 7.2 to emulate the $PSStyle
        variable in older versions where the variable is not natively available.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        ExchangeOnlineManagement
        Microsoft.Online.Sharepoint.Management
        PSStyle
        .EXAMPLE
        Initialize-Module -ExchangeOnline
        .EXAMPLE
        Initialize-Module -SharePointOnline
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Initialize-EXO','Initialize-SPO','Initialize-PSStyle')]

    param(
        [Parameter(Mandatory=$false,ParameterSetName='ExchangeOnline')] [Alias('EXO','EOM')] [Switch] $ExchangeOnline,
        [Parameter(Mandatory=$false,ParameterSetName='SharePointOnline')] [Alias('SPO','MOSM')] [Switch] $SharePointOnline,
        [Parameter(Mandatory=$false,ParameterSetName='PSStyle')] [Switch] $PSStyle
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ExchangeOnline' {
            Write-Error -Message "Feature not implemented yet..." -Category NotImplemented
            return $false
        }
        'SharePointOnline' {
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
        'PSStyle' {
            # check if PSStyle module is needed at all...
            if ($PSVersionTable.PSVersion -ge "7.2") {
                return $true
            }
            # check if PSStyle module is installed, try to install if missing...
            if (-not(Get-Module -Name "PSStyle" -ListAvailable)) {
                try{
                    Install-Module -Name "PSStyle" -Scope CurrentUser -AcceptLicense -AllowClobber -Force -ErrorAction Stop
                }
                catch {return $false}
            }
            # check if PSStyle module is already imported; try to import if $false...
            if (Get-Module -Name "PSStyle") {
                try {
                    Import-Module -Name "PSStyle" -Global -Force -ErrorAction Stop | Out-Null
                    return $true
                }
                catch {return $false}
            }
        }
        default {
            Write-Error -Message "No valid module parameter specified..." -Category InvalidArgument
            return $false
        }
    }

}