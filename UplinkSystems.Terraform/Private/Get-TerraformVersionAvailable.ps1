function Get-TerraformVersionAvailable {
	<#
		.SYNOPSIS
		Get version numbers of available Terraform releases
		.DESCRIPTION
		The function gets version numbers of available Terraform releases from HashiCorp's GitHub
        repository. Either the version tagged as 'latest release' or all tagged versions are queried.
        .PARAMETER All [Switch]
        The optional parameter $All specifies to all detected version numbers.
        .OUTPUTS
        System.IO.String
        .EXAMPLE
        Get-TerraformVersionAvailable
        .EXAMPLE
        Get-TerraformVersionAvailable -All
        .EXAMPLE
        To process the result for version comparison use [Version] prefix (only working without -All
        switch because -All switch returns an array of values and also includes alpha/beta releases),
        e.g.:
        $AsVersion = [Version]$(Get-TerraformVersionAvailable)
	#>
    
    [CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Get-TfVersionAvailable")]
    param (
        [Parameter()] [switch] $All
    )
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        switch ($All) {
            $false { $RestMethodUri = 'https://api.github.com/repos/hashicorp/terraform/releases/latest' }
            $true  { $RestMethodUri = 'https://api.github.com/repos/hashicorp/terraform/releases' }
        }
        try {
            $VersionAvailable = ((Invoke-RestMethod -Method GET -Uri $RestMethodUri -ErrorAction Stop).tag_name).SubString(1)
            return $VersionAvailable
        }
        catch {
            $VersionAvailable = $null
            return $VersionAvailable
        }
    }
}


