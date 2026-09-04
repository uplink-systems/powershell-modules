function New-TerraformCloudOrganization {
    <#
        .SYNOPSIS
        Create a new organization in the Terraform Cloud service.
        .Description
        The function creates a new organization in the Terraform Cloud service. A token for
        authentication is required.
        .PARAMETER Name [string]
		The mandatory parameter $Name represents the display name of the Terraform cloud
        organization to create.
        .PARAMETER Email [string]
		The mandatory parameter $Email represents the administrator's email address of the
        person that will manage the organization.
        .PARAMETER Token [string]
		The mandatory parameter $Token represents the API token to use for authentication
        agains the Terraform cloud.
        .EXAMPLE
        New-TerraformCloudOrganization -Name $ENV:TF_CLOUD_ORGANIZATON -Email name@domain.com -Token $ENV:TF_CLOUD_TOKEN
        .EXAMPLE
        New-TerraformCloudOrganization $ENV:TF_CLOUD_ORGANIZATON name@domain.com $ENV:TF_CLOUD_TOKEN
    #>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('New-TfCloudOrganization')]
    param (
        [Parameter(Position=0,Mandatory=$true)] [string] $Name,
        [Parameter(Position=1,Mandatory=$true)] [string] $Email,
        [Parameter(Position=2,Mandatory=$true)] [string] $Token
    )
    $Uri = 'https://app.terraform.io/api/v2/organizations'
    $ContentType = 'application/vnd.api+json'
    $Body = @{
        data = @{
            type       = "organizations"
            attributes = @{
                name  = $Name
                email = $Email
            }
        }
    } | ConvertTo-Json
    Write-Host -Object "`nCreating new Terraform Cloud organization... " -ForegroundColor DarkGray -NoNewline
    try {
        Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -ContentType $ContentType -Token $($Token | ConvertTo-SecureString -AsPlainText -Force) -Authentication Bearer | Out-Null
        Write-Host -Object "Success...`n" -ForegroundColor Green
    }
    catch {
        Write-Host -Object "Failed: $($Error[0].Exception.Message)`n" -ForegroundColor Red
    }
}