function Convert-SPOUpnToPersonalSiteName {

    <#
        .SYNOPSIS
        The function converts an UPN to a SPO personal site name.
        .DESCRIPTION
        The little helper function converts an UPN to a SPO personal site name by
        replacing special characters with underscores.
        .PARAMETER UserPrincipalName [String]
        The mandatory string $UserPrincipalName represents the UPN to convert to
        SPO personal site name.
        .OUTPUTS
        System.String
        .NOTES
        .EXAMPLE
        Convert-SPOUpnToPersonalSiteName -UserPrincipalName "john.doe@company.com"
        .EXAMPLE
        Convert-SPOUpnToPersonalSiteName "john.doe@company.com"
        .EXAMPLE
        Get-MgUser -Filter "startswith(UserPrincipalName,'john')" | Convert-SPOUpnToPersonalSiteName
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Confirm-CustomDomain')]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [Alias('UPN')] [String] $UserPrincipalName
    )

    $SpoPersonalSiteName = $UserPrincipalName -replace '[.@-]','_'
    return $SpoPersonalSiteName

}