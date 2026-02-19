function Get-EntraTenantId {

    <#
        .SYNOPSIS
        Evaluates the domain name's matching M365 tenant Id.
        .DESCRIPTION
        The function evaluates the domain name's matching M365 tenant Id.
        Any tenant's owned domain is allowed to query including the onmicrosoft.com
        default domain
        .PARAMETER Domain [String]
        The mandatory parameter -Domain represents the domain name to query the Id for.
        .OUTPUTS
        System.String
        .EXAMPLE
        Get-EntraTenantId -Domain company.onmicrosoft.com
        .EXAMPLE
        Get-EntraTenantId company.com
        .EXAMPLE
        "company.com","business.org" | Get-EntraTenantId
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Get-TenantId")]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }

    process {
        try {
            $Tenant = Invoke-RestMethod -UseBasicParsing -Uri "https://odc.officeapps.live.com/odc/v2.1/federationprovider?domain=$Domain" -ErrorAction Stop
            return $Tenant.tenantId
        }
        catch { 
            return
        }
    }

    end {
        $ErrorActionPreference = $Preferences[0]
    }

}
