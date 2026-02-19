function New-SPOCrossTenantPartnerRelationship {

    <#
        .SYNOPSIS
        The function creates a partnership for a Cross-Tenant SharePoint Online and/or
        OneDrive migration.
        .DESCRIPTION
        The function creates a partnership for a Cross-Tenant SharePoint Online and/or
        OneDrive migration.
        .PARAMETER SourceTenantInitialDomain [String]
        The mandatory parameter -SourceTenantInitialDomain configures the name of the
        migration source tenant. The value must be the fully-qualified initial domain
        name (e.g. "company1.onmicrosoft.com")
        Alias: Source
        .PARAMETER TargetTenantInitialDomain [String]
        The mandatory parameter -TargetTenantInitialDomain configures the name of the
        migration target tenant. The value must be the fully-qualified initial domain
        name (e.g. "company2.onmicrosoft.com")
        Alias: Tenant
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.SharePoint.Online.PowerShell
        .NOTES
        The function currently only supports interactive web login to work. Therefore, it is
        necessary to login/logoff multiple time to switch between tenants. Certificate 
        based authentication is currently not supported but planned for future updates.
        .EXAMPLE
        New-SPOCrossTenantPartnerRelationship -SourceTenantName "company1" -TargetTenantName "company2"
        .EXAMPLE
        New-SPOCrossTenantPartnerRelationship "company1" "company2"
        .EXAMPLE
        New-SPOCTPartner -Source "company1" -Target "company2"
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("New-SPOCTPartner")]

    param(     
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("Source")]
        [ValidateScript({if ($_.EndsWith(".onmicrosoft.com")) {$true} else {throw "Invalid value: `"$_`"."}})]
        [String] $SourceTenantInitialDomain,
        [Parameter(Mandatory=$true, Position=1)]
        [Alias("Target")]
        [ValidateScript({if ($_.EndsWith(".onmicrosoft.com")) {$true} else {throw "Invalid value: `"$_`"."}})]
        [String] $TargetTenantInitialDomain
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $InformationPreference = 'Continue'
        $Global:SourceTenantName = $SourceTenantInitialDomain.replace('.onmicrosoft.com','')
        $Global:TargetTenantName = $TargetTenantInitialDomain.replace('.onmicrosoft.com','')
        Initialize-Module -SharePointOnline | Out-Null
    }

    process{
        $Global:SourceTenantAdminUrl = "https://$SourceTenantName-admin.sharepoint.com"
        $Global:TargetTenantAdminUrl = "https://$TargetTenantName-admin.sharepoint.com"
        $Global:SourceTenantHostUrl = "https://$SourceTenantName-my.sharepoint.com"
        $Global:TargetTenantHostUrl = "https://$TargetTenantName-my.sharepoint.com"
        Write-Information -MessageData "Setting tenant relationship in Source tenant... Connecting..."
        Connect-SPOService -Url $SourceTenantAdminUrl
        Set-SPOCrossTenantRelationship -Scenario MnA -PartnerRole Target -PartnerCrossTenantHostUrl $TargetTenantHostUrl | Out-Null
        Disconnect-SPOService
        Write-Information -MessageData "Setting tenant relationship in Target tenant... Connecting..."
        Connect-SPOService -Url $TargetTenantAdminUrl
        Set-SPOCrossTenantRelationship -Scenario MnA -PartnerRole Source -PartnerCrossTenantHostUrl $SourceTenantHostUrl | Out-Null
        Disconnect-SPOService
        Write-Information -MessageData "Verifying tenant relationship in Source tenant... Connecting..."
        Connect-SPOService -Url $SourceTenantAdminUrl
        $VerifySourceTenantCount = 0
        do {
            $SourceTenantRelationshipTest = Test-SPOCrossTenantRelationship -Scenario MnA -PartnerRole Target -PartnerCrossTenantHostUrl $TargetTenantHostUrl
            if ($SourceTenantRelationshipTest.value -eq "GoodToProceed") { break }
            $VerifySourceTenantCount = $VerifySourceTenantCount + 1
            Start-Sleep -Seconds 5
        } until ($VerifySourceTenantCount -eq 6)
        Disconnect-SPOService
        Write-Information -MessageData "Verifying tenant relationship in Target tenant... Connecting..."
        Connect-SPOService -Url $TargetTenantAdminUrl
        $VerifyTargetTenantCount = 0
        do {
            $TargetTenantRelationshipTest = Test-SPOCrossTenantRelationship -Scenario MnA -PartnerRole Source -PartnerCrossTenantHostUrl $SourceTenantHostUrl
            if ($TargetTenantRelationshipTest.value -eq "GoodToProceed") { break }
            $VerifyTargetTenantCount = $VerifyTargetTenantCount + 1
            Start-Sleep -Seconds 5
        } until ($VerifyTargetTenantCount -eq 6)
        Disconnect-SPOService
        # output result
        if (($SourceTenantRelationshipTest.value -eq "GoodToProceed") -and ($TargetTenantRelationshipTest.value -eq "GoodToProceed")) {
            Write-Information -MessageData "Tenant relationship configuration successfully set up."
            return $true
        }
        elseif (($SourceTenantRelationshipTest.value -eq "GoodToProceed") -or ($TargetTenantRelationshipTest.value -ne "GoodToProceed")) {
            Write-Error -Message "ERROR: Tenant relationship configuration failed in either source or target tenant." -Category InvalidResult
            return $false
        }
        elseif (($SourceTenantRelationshipTest.value -ne "GoodToProceed") -and ($TargetTenantRelationshipTest.value -ne "GoodToProceed")) {
            Write-Error -Message "ERROR: Tenant relationship configuration failed in source and target tenant." -Category InvalidResult
            return $false
        }
        else {
            Write-Error -Message "ERROR: Tenant relationship configuration failed with unkonwn error." -Category NotSpecified
            return $false
        }
    }

    end {
        $ErrorActionPreference = $Preferences[0]
        $InformationPreference = $Preferences[1]
    }

}