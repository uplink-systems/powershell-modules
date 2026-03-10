function Stop-TerraformProcess {
	<#
		.SYNOPSIS
		Stop terraform processes.
		.DESCRIPTION
		The function stops all running terraform.exe processes.
		.PARAMETER TimedOut [Switch]]
		The optional parameter -TimedOut forces to stop timed out processes running longer
        than 30 minutes only.
		Default: $false
		.EXAMPLE
		Stop-TerraformProcess
        .EXAMPLE
        Stope-TerraformProcess -TimedOut
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Stop-TfProcess')]
	param(
		[Parameter(Mandatory=$false)]
		[Switch] $TimedOut
	)
	begin {
		[Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue'
	}
	process {
		switch ($TimedOut) {
			$true {Get-Process -Name terraform* | Where-Object {$_.TotalProcessorTime.TotalMinutes -gt 30} | Stop-Process -Force | Out-Null}
			default {Get-Process -Name terraform* | Stop-Process -Force | Out-Null}
		}
	}
	end {
		$ErrorActionPreference = $Preferences[0]
	}
}