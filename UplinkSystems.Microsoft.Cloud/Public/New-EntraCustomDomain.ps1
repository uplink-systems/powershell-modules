function New-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function adds a new custom domain in Entra.
        .DESCRIPTION
        The function adds a new custom domain (root or subdomain) in Microsoft Entra and
        returns the code for the verification TXT record. If the domain is already present
        in  the tenant but unverified, the function also returns the code for the verification
        TXT record. The function returns no value if the domain is already present and verified
        or if the function stops with an error. The function only registers the domain but
        does not configure any domain services.
        .PARAMETER Domain [String]
        The mandatory parameter -Domain represents the FQDN of the domain to add to the tenant.
        .PARAMETER DefaultDomain [Switch]
        The optional parameter -DefaultDomain must only be added to the function call if the
        domain shall become the default domain for the tenant.
        .PARAMETER SubDomain [Switch]
        The optional parameter -SubDomain must only be added to the function call if the domain
        is a sub domain and not a root domain.
        .COMPONENT
        Microsoft.Graph
        .OUTPUTS
        System.String
        .NOTES
        The function requires an authenticated MgGraph session with at least "User.ReadWrite.All"
        and "Domain.ReadWrite.All"scope.
        The function validates required scopes and initiates a new MgGraph connection if current
        scopes are insufficient.
        .EXAMPLE
        New-EntraCustomDomain -Domain company.com -DefaultDomain
        .EXAMPLE
        New-EntraCustomDomain groups.company.com -SubDomain
        .EXAMPLE
        New-CustomDomain company.com
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.M365")]
    [Alias("New-CustomDomain")]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain,
        [Parameter(Mandatory=$false)] [Switch] $DefaultDomain,
        [Parameter(Mandatory=$false)] [Switch] $SubDomain
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $MgGraphScopes = "User.ReadWrite.All","Domain.ReadWrite.All"
        if (-not(Confirm-MgGraphScopeInContextScopes -Scopes $MgGraphScopes)) {Connect-MgGraph -Scopes $MgGraphScopes -NoWelcome}
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
