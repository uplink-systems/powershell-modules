function Enable-MsCommerceSelfServicePurchase {

    <#
        .SYNOPSIS
        The function enables self-service purchase for Microsoft 365 products.
        .DESCRIPTION
        The function enables self-service purchase / trial capability for all supported
        M365 products.
        .COMPONENT
        MsCommerce
        .OUTPUTS
        System.Boolean
        .NOTES
        Connect-MSCommerce needs to authenticate with a global billing administrator!
        .EXAMPLE
        Enable-MsCommerceSelfServicePurchase
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Enable-SelfServicePurchase')]
    
    param()

    try {
        Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase | Where-Object { $_.PolicyValue -eq "Disabled"} | ForEach-Object { 
            Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $_.ProductID -Enabled $true
        }
        return $true
    }
    catch {return $false}

}