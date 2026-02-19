function Get-SPOPersonalSiteUrlList {

    <#
        .SYNOPSIS
        The function gets the personal site URLs of a SPO tenant.
        .DESCRIPTION
        The function gets the personal site URLs (OneDrive sites) of a SPO tenant. Optionally,
        the results can be put out to grid view or exported to csv file.
        .PARAMETER TenantName [String]
        The mandatory parameter -TenantlName specifies the tenant name to connect to. The 
        value must be the tenant component of the initial M365 domain name (e.g. the parameter
        is "company" for "company.onmicrosoft.com" initial domain)
        Alias: Tenant
        .PARAMETER GridView [Switch]
        The optional parameter -GridView must be enabled to output the results to grid view.
        .PARAMETER Export [Switch]
        The optional parameter -Export must be enabled to output the results to a csv file.
        .PARAMETER ExportFile [String]
        The optional parameter -ExportFile represents the file path and name for the csv file
        if parameter -Export is enabled.
        Defaults to: [Environment]::GetFolderPath("LocalApplicationData") + "\temp\SPOPersonalSiteUrlList.csv"
        .OUTPUTS
        System.Array
        .COMPONENT
        Microsoft.Sharepoint.Online.PowerShell
        .EXAMPLE
        Get-SPOPersonalSiteUrlList
        .EXAMPLE
        Get-SPOPersonalSiteUrlList company -GridView
        .EXAMPLE
        Export-SPOOneDriveSiteUrlList -SpoTenant company -Export
    #>

    [CmdletBinding(PositionalBinding=$false,DefaultParameterSetName='Get',HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Export-SPOPersonalSiteUrlList","Out-SPOPersonalSiteUrlList","Get-SPOOneDriveSiteUrlList","Export-SPOOneDriveSiteUrlList","Out-SPOOneDriveSiteUrlList")]

    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Get')]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Export')]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='GridView')]
        [Alias("Tenant")]
        [ValidateScript({if (-not($_.EndsWith(".onmicrosoft.com"))) {$true} else {throw "Invalid value: `"$_`"."}})]
        [String] $TenantName,
        [Parameter(Mandatory=$false, ParameterSetName="GridView")] [Switch] $GridView,
        [Parameter(Mandatory=$false, ParameterSetName="Export")] [Switch] $Export,
        [Parameter(Mandatory=$false, ParameterSetName='Export')]
        [String] $ExportFile = [Environment]::GetFolderPath("LocalApplicationData") + "\temp\SPOPersonalSiteUrlList.csv"
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
        Initialize-Module -SharePointOnline | Out-Null
        Connect-SPOService -Url "https://$TenantName-admin.sharepoint.com"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Get" {
                Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" | Select-Object Owner,Url,Status,SiteId,StorageQuota,StorageUsageCurrent,CreatedTime,LastContentModifiedDate | Format-Table
            }
            "GridView" {
                Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" | Select-Object Owner,Url,Status,SiteId,StorageQuota,StorageUsageCurrent,CreatedTime,LastContentModifiedDate | Out-GridView
            }
            "Export" {
                Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" | Select-Object Owner,Url,Status,SiteId,StorageQuota,StorageUsageCurrent,CreatedTime,LastContentModifiedDate | Export-Csv -Path $ExportFile -Delimiter ";" -Force
                Write-Information -MessageData "INFO: Results exported to $ExportFile" -InformationAction Continue
            }
        }
    }

    end {
        Disconnect-SPOService
        $ErrorActionPreference = $Preferences[0]
    }

}