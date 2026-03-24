function Get-TerraformApplicationActiveVersion {
	<#
		.SYNOPSIS
		Get active version of installed Terraform executables
		.DESCRIPTION
		The function gets the currently active version of the locally installed Terraform
        executables and returns the version as string.
        .OUTPUTS
        System.IO.String
        .EXAMPLE
        Get-TerraformApplicationActiveVersion
        .EXAMPLE
        To process the result for version comparison use [Version] prefix, e.g.:
        $AsVersion = [Version]$(Get-TerraformApplicationActiveVersion)
	#>
	[CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Get-TfApplicationActiveVersion')]
    Param()
    begin {
        [Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        try {
            $ActiveVersion = (Invoke-Expression "terraform --version" -ErrorAction Stop | Where-Object { $_ -match 'Terraform v\d{1,}\.\d{1,}\.\d{1,}' } | Select-String -Pattern "([\d]+.[\d]+.[\d]+-[\w]+[\d]+|[\d]+.[\d]+.[\d]+)").Matches.Value
            return $ActiveVersion
        } catch {
            $ActiveVersion = $null
            return $ActiveVersion
        }
    }
    end {
        $ErrorActionPreference = $Preferences[0]
    }
}
