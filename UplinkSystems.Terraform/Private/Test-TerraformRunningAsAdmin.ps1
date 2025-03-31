function Test-TerraformRunningAsAdmin {
	<#
		.SYNOPSIS
		Test if running as administrator
		.DESCRIPTION
		The function tests if powershell session/script/module is running with elevated Administrator
        permissions. It returns $true or $false as result values.
        .OUTPUTS
        System.Boolean
        .EXAMPLE
        $ErrorActionPreference = "Stop"
        if (-not (Test-TerraformRunningAsAdministrator)) {
            Write-Error "This script must be executed as Administrator!"
            exit 1
        }
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
    [Alias("Test-TfRunAsAdmin")]
    [OutputType([bool])]
    param()
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        [Security.Principal.WindowsPrincipal]$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}