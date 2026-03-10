function Unblock-TerraformStateFileAzureBackend {
	<#
		.SYNOPSIS
		Unblock locked state file with Azure Backend
		.DESCRIPTION
		The function unblocks a locked state file when using Terraform with an Azure blob storage as state file backend location.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter -WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER Tenant [String]
        The optional parameter -Tenant specifies the Id of the tenant containing the state file resources.
        Defaults to: 'tenant_id' value from working directory's terraform.tf file.
        .PARAMETER ClientId [String]
        The optional parameter -ClientId specifies the Client ID / App ID to use for connecting to Azure.
        Defaults to: 'client_id' value from working directory's terraform.tf file.
        .PARAMETER ClientSecret [String]
        The optional parameter -ClientSecret specifies the secret for the Client ID / App ID to use for connecting to Azure
        with a client secret.
        Defaults to: 'client_secret' value from working directory's terraform.tf file.
        .PARAMETER ClientCertificatePath [String]
        The optional parameter -ClientCertificatePath specifies the full path for the Client ID / App ID certifiate to use for
        connecting to Azure with a certificate.
        Defaults to: 'client_certificate_path' value from working directory's terraform.tf file.
        .PARAMETER ClientCertificatePassword [String]
        The optional parameter -ClientCertificatePassword specifies the password for the Client ID / App ID certificate to use
        for connecting to Azure with a certificate.
        Defaults to: 'client_certificate_password' value from working directory's terraform.tf file.
        .PARAMETER SubscriptionId [String]
        The optional parameter -SubscriptionId specifies the ID of the subscription containing the state file resources.
        Defaults to: 'subscription_id' value from working directory's terraform.tf file.
        .PARAMETER StorageAccountName [String]
        The optional parameter -StorageAccountName specifies the name of the storage account in the subscription.
        Defaults to: 'storage_account_name' value from working directory's terraform.tf file.
        .PARAMETER ContainerName [String]
        The optional parameter -ContainerName specifies the name of the blob container in the storage account.
        Defaults to: 'container_name' value from working directory's terraform.tf file.
        .PARAMETER Blob [String]
        The optional parameter -Blob specifies the full name and path to the state file to unlock.
        Defaults to: 'key' value from working directory's terraform.tf file.
        .COMPONENT
        Az
		.OUTPUTS
		System.IO.FileInfo
        .NOTES
        The function uses the Az PowerShell modules to unblock the state file which is not needed for the other functions of the
        module. Therefore, it checks if the required modules are available. If not, it installs the required components in current
        user scope.
        Only Azure AD authentication is supported to unblock the state file, whereas Access Token or SAS Token isn't. Therefore,
        the backend storage must accept Azure AD authentiction for this function to work. The function can get most parameters
        automatically if the specified value for -WorkingDirectory parameter contains a terraform.tf file containing a configured
        backend block with clientId/secret or clientId/certificate authentication settings. All parameters can be specified
        manually, too. If no value for -ClientId and -ClientSecret or -ClientCertificatePath and -ClientCertificatePassword can be 
        evaluated the function logs in interactively to Azure asking for credentials.
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Unblock-TfStateFileAzureBackend')]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage='Enter the Terraform working/project directory...')]
		[ValidateScript({if(-not($_ | Test-Path)) {throw 'Directory does not exist...'}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
        [Parameter(Mandatory=$false)] [String] $TenantId = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'tenant_id' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $ClientId = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'client_id' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $ClientSecret = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'client_secret' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $ClientCertificatePath = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'client_certificate_password' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $ClientCertificatePassword = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'client_certificate_password' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $SubscriptionId = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'subscription_id' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $StorageAccountName = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'storage_account_name' -SimpleMatch) -split '"',99)[1], 
        [Parameter(Mandatory=$false)] [String] $ContainerName = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'container_name' -SimpleMatch) -split '"',99)[1],
        [Parameter(Mandatory=$false)] [String] $Blob = ((Select-String -Path (Join-Path -Path $WorkingDir -ChildPath 'terraform.tf') -Pattern 'key' -SimpleMatch) -split '"',99)[1]
	)
	begin {
		[Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
        $RequiredModules = 'Az.Accounts','Az.Storage'
        foreach ($RequiredModule in $RequiredModules) {if (-not(Get-Module -Name $RequiredModule -ListAvailable)) {Install-Module -Name $RequiredModule -Scope CurrentUser -AllowClobber -AcceptLicense -Force};Import-Module -Name $RequiredModule -Scope Global}
        if ($ClientId -and $ClientSecret) {Connect-AzAccount -ServicePrincipal -Tenant $TenantId -SubscriptionId $SubscriptionId -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $(ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force))}
        elseif ($ClientId -and $ClientCertificatePath -and $ClientCertificatePassword) {Connect-AzAccount -ServicePrincipal -Tenant $TenantId -ApplicationId $ClientId -CertificatePath $ClientCertificatePath -CertificatePassword $(ConvertTo-SecureString -String $ClientCertificatePassword -AsPlainText -Force)}
        else {Connect-AzAccount -Tenant $TenantId -SubscriptionId $SubscriptionId}
	}
    process {
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
        $StorageBlob = Get-AzStorageBlob -Container $ContainerName -Blob $Blob -Context $StorageContext
        $StorageBlobLeaseStatus = $StorageBlob.ICloudBlob.Properties.LeaseStatus
        if ($StorageBlobLeaseStatus -eq 'Locked') {
            $StorageBlob.ICloudBlob.BreakLease()
        }
    }
	end {
        Disconnect-AzAccount
		Set-Location -Path $MyInvocation.PSScriptRoot
		$ErrorActionPreference = $Preferences[0]
	}
}
