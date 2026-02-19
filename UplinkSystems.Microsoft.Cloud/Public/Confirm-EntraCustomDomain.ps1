function Confirm-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function verifies a new custom domain in Entra.
        .DESCRIPTION
        The function verifies a new custom domain in Entra using DNS TXT record verification.
        .PARAMETER Domain [String]
        The mandatory parameter -Domain represents the FQDN of the domain to verify.
        .NOTES
        The function requires the Microsoft Graph SDK PowerShell module to work as well as an 
        authenticated MgGraph session. The function validates required scopes and initiates a
        new MgGraph connection if current scopes are insufficient.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Graph
        .NOTES
        The function requires an authenticated MgGraph session with at least "User.ReadWrite.All"
        and "Domain.ReadWrite.All"scope.
        The function validates required scopes and initiates a new MgGraph connection if current
        scopes are insufficient.
        .EXAMPLE
        Confirm-EntraCustomDomain -Domain company.com
        .EXAMPLE
        Confirm-CustomDomain company.com
        .EXAMPLE
        (New-MgDomain -Domain company.com).id | Confirm-EntraCustomDomain
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Confirm-CustomDomain")]
    
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $MgGraphScopes = "User.ReadWrite.All","Domain.ReadWrite.All"
        if (-not(Confirm-MgGraphScopeInContextScopes -Scopes $MgGraphScopes)) {Connect-MgGraph -Scopes $MgGraphScopes -NoWelcome}
    }

    process {
        $MgDomain = Get-MgDomain -DomainId $Domain -ErrorAction SilentlyContinue
        if (-not($MgDomain)) {
            return $false
        }
        elseif ($MgDomain.Verified) {
            return $true
        }
        else {
            try {
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
                $DnsRecordValue = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction SilentlyContinue | Where-Object {$_.Strings -like "MS=*"}
                if ($DomainVerificationCode.Value -eq $DnsRecordValue.Strings) {
                    Confirm-MgDomain -DomainId $Domain -ErrorAction Stop
                    return $true
                }
                else {
                    return $false
                }
            }
            catch {
                return $false
            }
        }
    }

    end {
        $ErrorActionPreference = $Preferences[0]
    }

}