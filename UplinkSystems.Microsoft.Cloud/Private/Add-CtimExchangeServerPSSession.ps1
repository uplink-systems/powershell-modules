function Add-CtimExchangeServerPSSession {

    <#
        .SYNOPSIS
        The function adds a remote session to an on-premises Exchange Server.
        .DESCRIPTION
        The function adds a remote session to an on-premises Exchange Server and is
        used in Cross-Tenant migrations when processing the Cross-Tenant Identity 
        Mapping. It is needed in hybrid scenarios with Entra connect synced MailUser
        objects.
        .PARAMETER ExchangeServer [String]
        The mandatory parameter -ExchangeServer specifies the Exchange Server to remotely
        connect a PSSession to.
        Alias: $Server
        .PARAMETER Credential [System.Management.Automation.PSCredential]
        The optional parameter -Credential specifies the credentials to authenticate with
        against the Exchange Server. If a credential is not provided the function ask for
        user input. Please not: Username = sAMAccountName (not "Domain\", no UPN).
        Defaults to: $(Get-Credential)
        .COMPONENT
        Microsoft.Exchange.Management.Shell
        .EXAMPLE
        Add-CtimExchangeServerPSSession -ExchangeServer "mail.domain.com"
        .EXAMPLE
        Add-CtimExchangeServerPSSession "mail.domain.com"
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    
    param (
        [Parameter(Mandatory=$true,Position=0)] [Alias('Server')] [String] $ExchangeServer,
        [Parameter(Mandatory=$false)] [System.Management.Automation.PSCredential] $Credential = $(Get-Credential)
    )

    if (Test-Connection -TargetName $ExchangeServer -Ping -IPv4 -Count 1 -Quiet) {
        Import-PSSession -Session (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/PowerShell/ -Authentication Kerberos -Credential $Credential) -DisableNameChecking
    }
    if (Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}) {return $true} else {return $false}

}