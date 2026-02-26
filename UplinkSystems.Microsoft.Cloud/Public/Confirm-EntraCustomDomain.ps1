function Confirm-EntraCustomDomain {

    <#
        .SYNOPSIS
        The function verifies a new custom domain in Entra.
        .DESCRIPTION
        The function verifies a new custom domain in Entra using DNS TXT record verification.
        .PARAMETER Domain [String]
        The mandatory parameter -Domain represents the FQDN of the domain to verify.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Graph
        .NOTES
        A valid MgGraph PowerShell user session with valid scopes or a client id session
        with valid consents must be established for the function to work:
        - User.ReadWrite.All
        - Domain.ReadWrite.All
        .EXAMPLE
        Confirm-EntraCustomDomain -Domain company.com
        .EXAMPLE
        Confirm-CustomDomain company.com
        .EXAMPLE
        (New-MgDomain -Domain company.com).id | Confirm-EntraCustomDomain
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Confirm-CustomDomain')]
    
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain
    )

    begin {
        if (-not(Get-MgContext)) {Write-Host -Object "Error: Not connected to MgGraph..." -ForegroundColor Red; return}
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
                $DomainVerificationCode = Get-EntraCustomDomainDnsRecordSet -Domain $Domain -VerificationDnsRecordOnly -ErrorAction SilentlyContinue
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

}