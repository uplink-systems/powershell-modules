function Confirm-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function verifies a new custom domain in Entra.
        .DESCRIPTION
        The function verifies a new custom domain in Entra using DNS TXT record verification.
        .PARAMETER Domain [String]
        The mandatory string $Domain represents the FQDN of the domain to verify.
        .NOTES
        The function requires the Microsoft Graph SDK PowerShell module to work as well as an 
        authenticated MgGraph session. The function validates required scopes and initiates a
        new MgGraph connection if current scopes are insufficient.
        .OUTPUTS
        System.Boolean
        .EXAMPLE
        Confirm-EntraCustomDomain -Domain company.com
        .EXAMPLE
        Confirm-CustomDomain company.com
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Confirm-CustomDomain")]

    param(
        [Parameter(Mandatory=$true, Position=0)] [String] $Domain
    )

    begin {
        $MgGraphScopes = "User.ReadWrite.All","Domain.ReadWrite.All"
        if (-not(Confirm-MgGraphScopeInContextScopes -Scopes $MgGraphScopes)) {Connect-MgGraph -Scopes $MgGraphScopes -NoWelcome}
    }

    process {
        $MgDomain = Get-MgDomain -DomainId $Domain -ErrorAction SilentlyContinue
        if (-not($MgDomain)) {
            $DomainIsVerified = $false
        }
        elseif ($MgDomain.Verified) {
            $DomainIsVerified = $true
        }
        else {
            try {
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly
                $DnsRecordValue = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction SilentlyContinue | Where-Object {$_.Strings -like "MS=*"}
                if ($DomainVerificationCode.Value -eq $DnsRecordValue.Strings) {
                    Confirm-MgDomain -DomainId $Domain -ErrorAction Stop
                    $DomainIsVerified = $true
                }
                else {
                    $DomainIsVerified = $false
                }
            }
            catch {
                $DomainIsVerified = $false
            }
        }
    }

    end {
        return {$DomainIsVerified}
    }

}


