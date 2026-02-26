function New-CrossTenantMigrationAppRegistration {

    <#
        .SYNOPSIS
        The function creates an App registration for Cross Tenant Migrations.
        .DESCRIPTION
        The function creates an App registration for Cross Tenant Migrations. EXO
        migrations are the primary goal of the app registration and always enabled.
        The parameters and API permissions are configured to match the Microsoft
        Learning description:
        https://learn.microsoft.com/en-us/microsoft-365/enterprise/cross-tenant-mailbox-migration
        Optionally, delegated API permission for Sharepoint can be added to allow
        the removal of existing target tenant (personal) sites in SharePoint Online
        and OneDrive for Business migration scenarios.
        .PARAMETER DisplayName [String]
        The optional parameter -DisplayName specifies the name of the app registration
        and the service principal.
        Defaults to: "CrossTenantMigration"
        .PARAMETER IncludeSharePoint [Switch]
        The optional parameter -IncludeSharePoint adds API permissions for Sharepoint
        Online and OneDrive for Business site migration scenarios.
        Alias: IncludeOneDrive
        .OUTPUTS
        System.Array
        .COMPONENT
        Microsoft.Graph
        .NOTES
        A valid MgGraph PowerShell user session with valid scopes or a client id session
        with valid consents must be established for the function to work:
        - Application.ReadWrite.All
        - AppRoleAssignment.ReadWrite.All
        - DelegatedPermissionGrant.ReadWrite.All
        - Domain.Read.All
        - User.Read.All
        .EXAMPLE
        New-CrossTenantMigrationAppRegistration -DisplayName "CrossTenantMigration-App"
        .EXAMPLE
        New-CrossTenantMigrationAppRegistration -DisplayName "CTM"
        .EXAMPLE
        New-CrossTenantMigrationAppRegistration -IncludeSharePoint -Silent
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('New-CTMAppRegistration')]

    param (
        [Parameter(Mandatory=$false)] [String] $Global:DisplayName = 'CrossTenantMigration',
        [Parameter(Mandatory=$false)] [Alias('IncludeOneDrive')] [Switch] $IncludeSharePoint,
        [Parameter(Mandatory=$false)] [Alias('S')] [Switch] $Silent
    )

    begin {
        if (-not(Get-MgContext)) {Write-Host -Object "Error: Not connected to MgGraph..." -ForegroundColor Red; return}
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        if ($Silent) {$InformationPreference = 'SilentlyContinue'} else {$InformationPreference = 'Continue'}
    }

    process {
        try {
            # create app registration
            $Global:MgApplication = Get-MgApplication -Filter "DisplayName eq '$DisplayName'" -ErrorAction SilentlyContinue
            if (-not ($MgApplication)) {
                Write-Information -MessageData "Creating new registration for app $DisplayName..." -InformationAction Continue
                $RequiredResourceAccess = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
                $ApiPermission = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
                $ApiPermission.ResourceAppId = "00000003-0000-0000-c000-000000000000"                              # Microsoft Graph
                $ApiPermission.ResourceAccess+=@{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }    # Delegatred permission: User.Read
                $RequiredResourceAccess.Add($ApiPermission)
                $ApiPermission = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
                $ApiPermission.ResourceAppId = "00000002-0000-0ff1-ce00-000000000000"                              # Office 365 Exchange Online
                $ApiPermission.ResourceAccess+=@{ Id = "f7264778-fba9-422d-8e9e-2675a2c4b513"; Type = "Role" }     # Application permission: Mailbox.Migration
                $RequiredResourceAccess.Add($ApiPermission)
                if ($IncludeSharepoint) {
                    $ApiPermission = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
                    $ApiPermission.ResourceAppId = "00000003-0000-0ff1-ce00-000000000000"                              # Office 365 SharePoint Online
                    $ApiPermission.ResourceAccess+=@{ Id = "56680e0d-d2a3-4ae1-80d8-3c4f2100e3d0"; Type = "Scope" }    # Delegated permission: AllSites.FullControl
                    $RequiredResourceAccess.Add($ApiPermission)
                }
                $SignInAudience = "AzureADMultipleOrgs"
                $Web = @{RedirectUris = @("https://office365.com")}
                $Global:MgApplication = New-MgApplication -DisplayName $DisplayName -RequiredResourceAccess $RequiredResourceAccess -SignInAudience $SignInAudience -Web $Web
                Write-Information -MessageData "App registration created... AppId: $($MgApplication.AppId)..."
            }
            else {
                Write-Information -MessageData "Registration for app $DisplayName already exists..."
            }
            # create service principal / enterprise app
            $Global:MgServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($MgApplication.AppId)'" -ErrorAction SilentlyContinue
            if (-not ($MgServicePrincipal)) {
                Write-Information -MessageData "Creating new service principal for app $DisplayName..."
                $Global:MgServicePrincipal = New-MgServicePrincipal -AppId $MgApplication.AppId  -Description $MgApplication.DisplayName -ServicePrincipalType "Application"
                Write-Information -MessageData "Service principal created... AppId: $($MgApplication.AppId)..."
            }
            else {
                Write-Information -MessageData "Service principal for app $DisplayName already exists..."
            }
            # admin consent delegated permission: Microsoft Graph -> User.Read
            New-MgOauth2PermissionGrant -ClientId $MgServicePrincipal.Id -ConsentType "AllPrincipals" -ResourceId $((Get-MgServicePrincipal -Filter "displayName eq 'Microsoft Graph'").id) -Scope "User.Read" | Out-Null
            # admin consent application permission: Office 365 Exchange -> Mailbox.Migration
            New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $MgServicePrincipal.Id -PrincipalId $MgServicePrincipal.Id -ResourceId $((Get-MgServicePrincipal -Filter "displayName eq 'Office 365 Exchange Online'").id) -AppRoleId "f7264778-fba9-422d-8e9e-2675a2c4b513" | Out-Null
            if ($IncludeSharepoint) {
                # admin consent delegated permission: Office 365 SharePoint Online -> AllSites.FullControl
                New-MgOauth2PermissionGrant -ClientId $MgServicePrincipal.Id -ConsentType "AllPrincipals" -ResourceId $((Get-MgServicePrincipal -Filter "displayName eq 'Office 365 SharePoint Online'").id) -Scope "AllSites.FullControl" | Out-Null
            }
            return $Global:MgApplication
        }
        catch {
            Write-Error -Message "Failed creating app $DisplayName..."
            return
        }
    }

    end {
        $InformationPreference = $Preferences[1]
    }

}