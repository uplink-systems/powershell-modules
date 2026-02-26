function Disable-MsCommerceSelfServicePurchase {

    <#
        .SYNOPSIS
        The function disables self-service purchase for Microsoft 365 products.
        .DESCRIPTION
        The function disables self-service purchase / trial capability for all supported
        M365 products.
        .COMPONENT
        MsCommerce
        .OUTPUTS
        System.Boolean
        .NOTES
        Connect-MSCommerce needs to authenticate with a global billing administrator!
        .EXAMPLE
        Disable-MsCommerceSelfServicePurchase
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Disable-SelfServicePurchase')]
    
    param()

    try {
        Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase -ErrorAction Stop | Where-Object { $_.PolicyValue -eq "Enabled"} | ForEach-Object { 
            Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $_.ProductID -Enabled $false -ErrorAction Stop
        }
        return $true
    }
    catch {return $false}

}