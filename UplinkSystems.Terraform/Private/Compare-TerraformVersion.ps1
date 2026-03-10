function Compare-TerraformVersion {
	<#
		.SYNOPSIS
		This function compares installed and online available Terraform versions
		.DESCRIPTION
		The function compares the currently installed Terraform version with the latest version
        available online. Returns $true if a newer version is found online and $false if the
        installed version is up-to-date. It also returns $true if Terraform is not installed.
        .OUTPUTS
        System.IO.Boolean
        .EXAMPLE
        Compare-TerraformVersion
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Compare-TfVersion')]
    param ()
    begin {
        [Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        if ([Version]$(Get-TerraformVersionInstalled) -lt [Version]$(Get-TerraformVersionAvailable)) {
            $ErrorActionPreference = $Preferences[0]
            return $true
        }
        else {   
            return $false
        }
    }
    end {
        $ErrorActionPreference = $Preferences[0]
    }
}