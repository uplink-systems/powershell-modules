function New-CrossTenantMigrationTenantPreparation {

    <#
        .SYNOPSIS
        The function creates a new cross tenant mailbox migration configuration.
        .DESCRIPTION
        The function processes all preparation tasks for a M365 cross tenant migration
        with primary focus on Exchange Online.
        These tasks include:
        - creating a new app registration (optionally) in the target tenant following
          Microsoft's guidelines for Exchange Online
        - creating a new client secret for the target tenant app registration
        - creating a source tenant admin consent URL for the target tenant app
          registration (currently the consent must be done manually)
        - creating a migration endpoint in the target tenant
        - creating an organization relationship in the target tenant
        - creating scoping groups in the source tenant
        - creating an organization relationship in the source tenant
        .PARAMETER SourceTenantInitialDomain [String]
        The mandatory parameter -SourceTenantInitialDomain specifies the initial domain
        (.onmicrosoft.com domain) of the tenant to migrate from (source).
        Alias: Source
        .PARAMETER TargetTenantInitialDomain [String]
        The mandatory parameter -TargetTenantInitialDomain specifies the initial domain
        (.onmicrosoft.com domain) of the tenant to migrate to (target).
        Alias: Target
        .PARAMETER AppRegistrationDisplayName [String]
        The optional parameter -AppRegistrationDisplayName specifies the display name of
        the app registration to create or to use if exists.
        Alias: AppDisplayName
        Defaults to: CrossTenantMigration
        .PARAMETER AppRegistrationIncludeSharePointApiPermission [Switch]
        The optional parameter -AppRegistrationIncludeSharePointApiPermission forces the
        function to add API permissions to the new app registration needed for migration
        of SharePoint Online and/or OneDrive for Business.
        Alias: AppIncludesSharePoint
        Defaults to: $false
        .PARAMETER AppRegistrationClientSecretName [String]
        The optional parameter -AppRegistrationClientSecretName specifies the display name
        of the client secret to create.
        Alias: AppSecretName
        Defaults to: $AppRegistrationDisplayName-Secret
        .PARAMETER AppRegistrationClientSecretValidMonths [Int32]
        The optional parameter -AppRegistrationClientSecretValidMonths specifies the 
        validity period of the new client secret in months. Valid values: 3,6,12,18,24
        Alias: AppSecretValidMonths
        Defaults to: 12
        .PARAMETER AppRegistrationUseExisting [Switch]
        The optional parameter -AppRegistrationUseExisting forces the function to use an
        existing app registration (selected by -AppRegistrationName parameter) instead of
        creating a new one.
        Defaults to: $false
        .PARAMETER MigrationEndpointName [String]
        The optional parameter -MigrationEndpointName specifies the display name of the
        migration endpoint in the target tenant.
        Alias: MigrationEndpoint
        Defaults to: EP-$AppRegistrationDisplayName
        .PARAMETER SourceOrganizationRelationshipName [String]
        The optional parameter -SourceOrganizationRelationshipName specifies the display
        name of the organization relationship in the source tenant.
        Alias: SourceOrgRelationship
        Defaults to: ORG-$TargetTenantInitialDomain
        .PARAMETER TargetOrganizationRelationshipName [String]
        The optional parameter -TargetOrganizationRelationshipName specifies the display
        name of the organization relationship in the target tenant.
        Alias: TargetOrgRelationship
        Defaults to: ORG-$SourceTenantInitialDomain
        .PARAMETER MailboxMoveScopeGroups [Array]
        The optional parameter -MailboxMoveScopeGroups specifies the name of one or more
        mail-enabled security groups that shall be processed by the migration. According 
        to Microsoft's docu, New-OrganizationRelationship supports multiple scope groups
        (that's why the parameter should be of type 'array'). Nevertheless, multiple scope 
        groups as array lead to error (example if 3 values provided):
            ** The given count of areas (3) exceeds the allowed limit of 1 **
        Therefore, only a single value should be provided until this issue is fixed by
        Microsoft. Otherwise the array will be cropped and only the first value is
        processed.
        Alias: ScopeGroups
        Defaults to: SG-$AppRegistrationDisplayName
        .PARAMETER Silent [Switch]
        The optional paramter -Silent forces the function to suppress all informational
        output except error messages.
        Defaults to: $false
        .OUTPUTS
        System.Object
        .COMPONENT
        Microsoft.Graph
        ExchangeOnlineManagement
        .EXAMPLE
        New-CrossTenantMigrationTenantPreparation `
        -SourceTenantInitialDomain 'sourcecompany.onmicrosoft.com' `
        -TargetTenantInitialDomain 'targetcompany.onmicrosoft.com' `
        -AppRegistrationDisplayName 'CrossTenantMigration' `
        -AppRegistrationClientSecretName 'TargetCompany-SourceCompany-Secret' `
        -AppRegistrationClientSecretValidMonths 24 `
        -MigrationEndpointName 'EP-SourceCompany-EXO' `
        -SourceOrganizationRelationshipName 'ORG-TargetCompany' `
        -TargetOrganizationRelationshipName 'ORG-SourceCompany' `
        -MailboxMoveScopeGroups 'SG-CrossTenantMigration-Scope-01','SG-CrossTenantMigration-Scope-02'
        .EXAMPLE
        New-CrossTenantMigrationTenantPreparation `
        -SourceTenantInitialDomain 'sourcecompany.onmicrosoft.com' `
        -TargetTenantInitialDomain 'targetcompany.onmicrosoft.com' `
        -AppRegistrationDisplayName 'CrossTenantMigration' `
        -AppRegistrationUseExisting `
        -AppRegistrationClientSecretName 'TargetCompany-SourceCompany-Secret' `
        -AppRegistrationClientSecretValidMonths 24 `
        -MigrationEndpointName 'EP-SourceCompany-EXO' `
        -SourceOrganizationRelationshipName 'ORG-TargetCompany' `
        -TargetOrganizationRelationshipName 'ORG-SourceCompany' `
        -MailboxMoveScopeGroups 'SG-CrossTenantMigration-Scope-01'
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('New-CTMTenantPreparation')]

    param (
        [Parameter(Mandatory=$true)] [Alias('Source')]
        [ValidateScript({if ($_.EndsWith('.onmicrosoft.com')) {$true} else {throw "Domain $_ is invalid: not an initial tenant domain"}})]
        [String] $SourceTenantInitialDomain,
        [Parameter(Mandatory=$true)] [Alias('Target')]
        [ValidateScript({if ($_.EndsWith('.onmicrosoft.com')) {$true} else {throw "Domain $_ is invalid: not an initial tenant domain"}})]
        [String] $TargetTenantInitialDomain,
        [Parameter(Mandatory=$false)] [Alias('AppName')]
        [String] $AppRegistrationDisplayName = "CrossTenantMigration",
        [Parameter(Mandatory=$false)] [Alias('AppIncludeSharePoint')]
        [Switch] $AppRegistrationIncludeSharePointApiPermission,
        [Parameter(Mandatory=$false)] [Alias('AppSecretName')]
        [String] $AppRegistrationClientSecretName = "$AppRegistrationDisplayName-Secret",
        [Parameter(Mandatory=$true)] [Alias('AppSecretValidMonths')]
        [ValidateSet(3,6,12,18,24)]
        [Int32] $AppRegistrationClientSecretValidMonths = 12,
        [Parameter(Mandatory=$false)] [Alias('UseExistingApp')]
        [Switch] $AppRegistrationUseExisting,
        [Parameter(Mandatory=$false)] [Alias('MigrationEndpoint')]
        [String] $MigrationEndpointName = "EP-$AppRegistrationDisplayName",
        [Parameter(Mandatory=$false)] [Alias('SourceOrgRelationship')]
        [String] $SourceOrganizationRelationshipName = "ORG-$TargetTenantInitialDomain",
        [Parameter(Mandatory=$false)] [Alias('TargetOrgRelationship')]
        [String] $TargetOrganizationRelationshipName = "ORG-$SourceTenantInitialDomain",
        [Parameter(Mandatory=$false)] [Alias('ScopeGroups')]
        [Array] $MailboxMoveScopeGroups = "SG-$AppRegistrationDisplayName",
        [Switch] $Silent
    )

    # prepare variables
    $Global:SourceTenantId = (Get-EntraTenantId -Domain $SourceTenantInitialDomain)
    $Global:TargetTenantId = (Get-EntraTenantId -Domain $TargetTenantInitialDomain)

    # crop scope groups array to only one value
    if ($MailboxMoveScopeGroups.Count -gt 1) {[Array]$MailboxMoveScopeGroups = $MailboxMoveScopeGroups[0]}

    # disconnect existing sessions
    if (Get-MgContext) {Disconnect-MgGraph | Out-Null}
    if (Get-OrganizationConfig | Select-Object Identity) {Disconnect-ExchangeOnline -Confirm:$false}

    # connect MgGraph session to target tenant
    Connect-MgGraph -Scope 'Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All','DelegatedPermissionGrant.ReadWrite.All','Directory.ReadWrite.All','Domain.Read.All','User.Read.All' -NoWelcome
    # get existing app registration or create a new one if select
    if (-not($AppRegistrationUseExisting)) {
        $Global:MgApplication = New-CrossTenantMigrationAppRegistration -DisplayName $AppRegistrationDisplayName -IncludeSharePoint $AppRegistrationIncludeSharePointApiPermission -Silent $Silent
    }
    else {
        $Global:MgApplication = Get-MgApplication -Filter "DisplayName eq '$AppRegistrationDisplayName'"
    }
    # create a new client secret for the app registration
    $Global:MgApplicationSecret = Add-EntraApplicationCredential -ApplicationName $AppRegistrationDisplayName -SecretName $AppRegistrationClientSecretName -ValidMonths $AppRegistrationClientSecretValidMonths
    Write-Host -Object "`nApplication secret: " -NoNewline; Write-Host -Object "$($MgApplicationSecret.SecretText)`n" -ForegroundColor Yellow
    # disconnect MgGraph session from target tenant
    Disconnect-MgGraph | Out-Null

    # admin consent to the target tenant's app registration in the source tenant
    $AppRegistrationConsentUrl = "https://login.microsoftonline.com/$SourceTenantInitialDomain/adminconsent?client_id=$($MgApplication.AppId)&redirect_uri=https://office.com"
    $AppRegistrationConsentUrl | Set-Clipboard
    Write-Host -Object "Please admin consent to the target tenant app registration in source tenant with the following URL:"
    Write-Host -Object "$AppRegistrationConsentUrl" -ForegroundColor Yellow
    Write-Host -Object "The URL has been copied to clipboard. Paste (or copy the URL above manually) it in a browser and accept with source tenant admin credentials."
    Read-Host -Prompt "Admin consent finished [Y/N]?"

    # connect to target tenant Exchange Online organization
    Connect-ExchangeOnline -Organization $TargetTenantInitialDomain -ShowBanner:$false
    # enable customization if tenant is dehydrated
    $TargetOrganizationConfig = Get-OrganizationConfig | Select-Object isdehydrated
    if ($TargetOrganizationConfig.isdehydrated -eq $true) {Enable-OrganizationCustomization}
    # create migration endpoint
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $MgApplication.AppId, (ConvertTo-SecureString -String $MgApplicationSecret.SecretText -AsPlainText -Force)
    New-MigrationEndpoint -Name $MigrationEndpointName -ApplicationId $MgApplication.AppId -ExchangeRemoteMove:$true -RemoteServer outlook.office.com -RemoteTenant $SourceTenantInitialDomain -Credentials $Credentials
    # update existing organization relationship or create a new one if none exists
    $TargetOrganizationRelationshipExists = Get-OrganizationRelationship | Where-Object {$_.DomainNames -like $SourceTenantId}
    if ($null -ne $TargetOrganizationRelationshipExists) {
        Set-OrganizationRelationship -Name $TargetOrganizationRelationshipExists.Name -Enabled:$true -MailboxMoveEnabled:$true -MailboxMoveCapability Inbound
    }
    if ($null -eq $OrganizationRelationshipExists) {
        New-OrganizationRelationship -Name $TargetOrganizationRelationshipName -Enabled:$true -MailboxMoveEnabled:$true -MailboxMoveCapability Inbound -DomainNames $SourceTenantId
    }
    # disconnect from target tenant Exchange Online organization
    Disconnect-ExchangeOnline -Confirm:$false

    # connect to source tenant Exchange Online organization
    Connect-ExchangeOnline -Organization $SourceTenantInitialDomain -ShowBanner:$false
    # enable customization if tenant is dehydrated
    $SourceOrganizationConfig = Get-OrganizationConfig | Select-Object isdehydrated
    if ($SourceOrganizationConfig.isdehydrated -eq $true) {Enable-OrganizationCustomization}
    # create scope group(s)
    foreach ($MailboxMoveScopeGroup in $MailboxMoveScopeGroups) {
        if (-not(New-DistributionGroup -Type Security -Name $MailboxMoveScopeGroup)) {
            Write-Information -MessageData "Scope group $MailboxMoveScopeGroup already exists... Skipping creation..." -InformationAction Continue
        }
    }
    # update existing organization relationship or create a new one if none exists
    $SourceOrganizationRelationshipExists = Get-OrganizationRelationship | Where-Object {$_.DomainNames -like $TargetTenantId}
    if ($null -ne $SourceOrganizationRelationshipExists) {
        Set-OrganizationRelationship -Name $SourceOrganizationRelationshipExists.Name -Enabled:$true -MailboxMoveEnabled:$true -MailboxMoveCapability RemoteOutbound -OAuthApplicationId $MgApplication.AppId -MailboxMovePublishedScopes $MailboxMoveScopeGroups
    }
    if ($null -eq $SourceOrganizationRelationshipExists) {
        New-OrganizationRelationship -Name $SourceOrganizationRelationshipName -Enabled:$true -MailboxMoveEnabled:$true -MailboxMoveCapability RemoteOutbound -DomainNames $TargetTenantId -OAuthApplicationId $MgApplication.AppId -MailboxMovePublishedScopes $MailboxMoveScopeGroups
    }
    # disconnect from source tenant Exchange Online organization
    Disconnect-ExchangeOnline -Confirm:$false

}
