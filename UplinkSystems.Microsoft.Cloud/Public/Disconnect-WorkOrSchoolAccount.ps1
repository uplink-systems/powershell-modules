function Disconnect-WorkOrSchoolAccount {

        <#
        .SYNOPSIS
        The function disconnects the current user or all users from the Work or School
        Account.
        .DESCRIPTION
        The function disconnects the current user or all users from the Work or School
        Account.
        .PARAMETER AllUsers [Switch]
        The optional parameter -AllUsers enables to discconect all users that have been
        logged on at the local machine.
        .OUTPUTS
        System.Boolean
        .NOTES
        The function must be run as administrator if parameter -AllUsers is enabled. The
        function will return $false if requirement is not met. The system needs to be
        rebooted after the function is executed.
        .EXAMPLE
        Disconnect-WorkOrSchoolAccount
        .EXAMPLE
        Disconnect-WorkOrSchoolAccount -AllUsers
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]

    param(
        [Parameter(Mandatory=$false)] [Switch] $AllUsers
    )

    if ($AllUsers) {
        if (-not([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
            throw "PermissionDenied: Administrator permission required to execute with -AllUsers parameter."
        }
        Get-ItemProperty -Path "$ENV:SYSTEMDRIVE\Users\*\AppData\Local\Packages" | ForEach-Object {
            Remove-Item -Path "$_\Microsoft.AAD.BrokerPlugin*" -Recurse -Force | Out-Null
        }
        return $true
    }
    else {
        Remove-Item -Path "$ENV:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin*" -Recurse -Force | Out-Null
        return $true
    }

}