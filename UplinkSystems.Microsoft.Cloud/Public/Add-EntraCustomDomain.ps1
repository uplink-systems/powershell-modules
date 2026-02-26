function Add-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function adds a custom domain in Entra.
        .DESCRIPTION
        The function adds a custom domain (root or subdomain) in Microsoft Entra and
        returns the code for the verification TXT record. If the domain is already 
        present in  the tenant but unverified, the function also returns the code for the
        verification TXT record. The function returns no value if the domain is already
        present and verified or if the function stops with an error. The function only
        registers the domain but does not configure any domain services.
        .PARAMETER Domain [String]
        The mandatory parameter -Domain represents the FQDN of the domain to add to the
        tenant.
        .PARAMETER DefaultDomain [Switch]
        The optional parameter -DefaultDomain must only be added to the function call if
        the domain shall become the default domain for the tenant.
        .PARAMETER SubDomain [Switch]
        The optional parameter -SubDomain must only be added to the function call if the
        domain is a sub domain and not a root domain.
        .COMPONENT
        Microsoft.Graph
        .OUTPUTS
        System.String
        .NOTES
        A valid MgGraph PowerShell user session with valid scopes or a client id session
        with valid consents must be established for the function to work:
        - User.ReadWrite.All
        - Domain.ReadWrite.All
        .EXAMPLE
        Add-EntraCustomDomain -Domain company.com -DefaultDomain
        .EXAMPLE
        Add-CustomDomain groups.company.com -SubDomain
        .EXAMPLE
        New-EntraCustomDomain company.com
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.M365')]
    [Alias('Add-CustomDomain','New-EntraCustomDomain','New-CustomDomain')]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain,
        [Parameter(Mandatory=$false)] [Switch] $DefaultDomain,
        [Parameter(Mandatory=$false)] [Switch] $SubDomain
    )

    begin {
        if (-not(Get-MgContext)) {Write-Host -Object "Error: Not connected to MgGraph..." -ForegroundColor Red; return}
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }

    process {
        $DomainBodyParameter = @{
            Id                  = $Domain
            IsDefault           = $DefaultDomain
            IsRoot              = (-not($SubDomain))
        }
        try {
            $MgDomain = Get-MgDomain -DomainId $Domain -ErrorAction SilentlyContinue
            if (-not($MgDomain)) {
                New-MgDomain -BodyParameter $DomainBodyParameter -ErrorAction Stop
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
                return $DomainVerificationCode
            }
            elseif (-not($MgDomain.IsVerified)) {
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
                return $DomainVerificationCode
            }
            else {
                return
            }
        }
        catch {
            return
        }
    }

    end {
        $ErrorActionPreference = $Preferences[0]
    }

}
