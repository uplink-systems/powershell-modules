Function Get-TerraformVersionInstalled {
	<#
		.SYNOPSIS
		Get version of installed Terraform executable
		.DESCRIPTION
		The function gets the version of the locally installed Terraform executable and returns
        the version as string.
        .OUTPUTS
        System.IO.String
        .EXAMPLE
        Get-TerraformVersionInstalled
        .EXAMPLE
        To process the result for version comparison use [Version] prefix, e.g.:
        $AsVersion = [Version]$(Get-TerraformVersionInstalled)
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfVersionInstalled")]
    Param()
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        try {
            $VersionInstalled   = (Invoke-Expression "terraform --version" -ErrorAction Stop | Where-Object { $_ -match 'Terraform v\d{1,}\.\d{1,}\.\d{1,}' } | Select-String -Pattern "([\d]+.[\d]+.[\d]+-[\w]+[\d]+|[\d]+.[\d]+.[\d]+)").Matches.Value
            return $VersionInstalled
        } catch {
            $VersionInstalled   = $null
            return $VersionInstalled
        }
    }
}
