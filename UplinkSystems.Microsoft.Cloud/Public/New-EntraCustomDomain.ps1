function New-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function adds a new custom domain in Entra.
        .DESCRIPTION
        The function adds a new custom domain (root or subdomain) in Microsoft Entra and
        returns the code for the verification TXT record. If the domain is already present
        in  the tenant but unverified, the function also returns the code for the verification
        TXT record. The function returns $null if the domain is already present and verified
        or if the function stops with an error.
        The function does NOT enable domain services (use Enable-EntraCustomDomainService
        function instead).
        .PARAMETER Domain [String]
        The mandatory string $Domain represents the FQDN of the domain to add to the tenant.
        .PARAMETER DefaultDomain [Switch]
        The optional switch $DefaultDomain must only be added to the function call if the
        domain shall become the default domain for the tenant.
        .PARAMETER SubDomain [Switch]
        The optional switch $SubDomain must only be added to the function call if the domain
        is a sub domain and not a root domain.
        .OUTPUTS
        System.String
        .NOTES
        The function requires the Microsoft Graph SDK PowerShell module to work as well as an 
        authenticated MgGraph session. The function validates required scopes and initiates a
        new MgGraph connection if current scopes are insufficient.
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
        [Parameter(Mandatory=$true, Position=0)] [String] $Domain,
        [Parameter(Mandatory=$false)] [Switch] $DefaultDomain,
        [Parameter(Mandatory=$false)] [Switch] $SubDomain
    )

    begin {
        $MgGraphScopes = "User.ReadWrite.All","Domain.ReadWrite.All"
        if (-not(Confirm-MgGraphScopeInContextScopes -Scopes $MgGraphScopes)) {Connect-MgGraph -Scopes $MgGraphScopes -NoWelcome}
    }

    process {
        $DomainBodyParameter = @{
            Id        = $Domain
            IsDefault = $DefaultDomain
            IsRoot    = $SubDomain
        }
        try {
            $MgDomain = Get-MgDomain -DomainId $Domain -ErrorAction SilentlyContinue
            if (-not($MgDomain)) {
                New-MgDomain -BodyParameter $DomainBodyParameter -ErrorAction Stop
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
            }
            elseif (-not($MgDomain.IsVerified)) {
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
            }
            else {
                $DomainVerificationCode = $null
            }
        }
        catch {
            $DomainVerificationCode = $null
        }
    }

    end {
        return {$DomainVerificationCode}
    }

}
