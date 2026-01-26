function Disable-MsCommerceSelfServicePurchase {
    <#
        .SYNOPSIS
            The function disables self-service purchase for Microsoft 365 products.
        .DESCRIPTION
            The function disables self-service purchase / trial capability for all supported
            M365 products.
        .NOTES
            The function requires the MsCommerce PowerShell module.
            Connect-MSCommerce needs to authenticate with a global billing administrator!
        .EXAMPLE
            Disable-MsCommerceSelfServicePurchase
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Disable-SelfServicePurchase")]
    
    param()

    Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase | Where-Object { $_.PolicyValue -eq "Enabled"} | ForEach-Object { 
        Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $_.ProductID -Enabled $false
    }

}


