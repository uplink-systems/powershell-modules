function Get-TerraformApplicationDefaultRootPath {
	<#
		.SYNOPSIS
		Get a default Terraform application versions root path
		.DESCRIPTION
		The function gets a default Terraform application versions root path depending
        on the current platform / operating system.
        A folder '.terraform' in the users profile (Windows) or home (Linux, MacOS) is
        used as default value.
        .OUTPUTS
        System.String
        .EXAMPLE
        Get-TerraformApplicationDefaultRootPath
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Get-TfApplicationDefaultRootPath')]
    param ()
    if ($PSVersionTable.OS -like "*Windows*") {return (Join-Path -Path $ENV:USERPROFILE -ChildPath '.terraform')}
    elseif ($PSVersionTable.OS -like "Linux*") {return (Join-Path -Path $HOME -ChildPath '.terraform')}
    elseif ($PSVersionTable.OS -like "Darwin*") {return (Join-Path -Path $HOME -ChildPath '.terraform')}
}