function Get-TerraformApplicationCurrentPlatform {
	<#
		.SYNOPSIS
		Get the platform (OS) for the Terraform application
		.DESCRIPTION
		The function evaluates the currently used platform / operating system to
        use for Terraform application.
        .INPUTS
        None. You cannot pipe objects to Get-TerraformApplicationPlatform.
        .OUTPUTS
        System.String
        .EXAMPLE
        Get-TerraformApplicationCurrentPlatform
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Get-TfApplicationCurrentPlatform')]
    param ()
    if ($PSVersionTable.OS -like "*Windows*") {return ('windows_amd64')}
    elseif ($PSVersionTable.OS -like "Linux*") {return ('linux_amd64')}
    elseif ($PSVersionTable.OS -like "Darwin*") {return ('darwin_amd64')}
}