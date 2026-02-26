function Remove-CtimExchangeServerPSSession {

    <#
        .SYNOPSIS
        The function removes open remote sessions to on-premises Exchange Server
        .DESCRIPTION
        The function removes remote session to an on-premises Exchange Server and is
        used in Cross-Tenant migrations when processing the Cross-Tenant Identity 
        Mapping. It is needed in hybrid scenarios with Entra connect synced MailUser
        objects.
        .COMPONENT
        Microsoft.Exchange.Management.Shell
        .EXAMPLE
        Remove-CtimExchangeServerPSSession
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]

    param ()

    foreach ($ExchangeSession in $(Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"})) {
        Remove-PSSession -id $ExchangeSession.id
    }
    if (-not(Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"})) {return $true} else {return $false}

}