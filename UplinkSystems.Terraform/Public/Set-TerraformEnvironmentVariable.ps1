function Set-TerraformEnvironmentVariable {
	<#
		.SYNOPSIS
		Set Terraform-related enviromment variables
		.DESCRIPTION
		The function configures one or more Terraform-related user environment variables (e.g. provider variables).
		It is possible to set or unset each of the variables.
		.PARAMETER EnvironmentVariables [HashTable]
		The mandatory parameter $EnvironmentVariables specifies a hash table of variables to configure.
		To add variables configure a valid variable name and a valid value.
		To remove variables configure a valid variable name but a value '$null'.
		.PARAMETER System [Switch]]
		The optional switch parameter $System specifies if the environment variable shall be set as system variable
		instead of user variable.
		Default: $false
		.EXAMPLE
		$EnvironmentVariables = @{
			'TF_WORKSPACE' = 'default'
			'ARM_CLIENT_ID' = '12345678-0000-0000-0000-000000000000'
			'TF_LOG' = $null
		}
		Set-TerraformEnvironmentVariable -EnvironmentVariables $EnvironmentVariables -System
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Set-TfEnvironmentVariable")]
	param(
		[Parameter(Mandatory=$true)] [HashTable] $EnvironmentVariables,
		[Parameter(Mandatory=$false)] [Switch] $System = $false
	)
	begin {
        $ErrorActionPreference = 'SilentlyContinue'
		if (($System) -and (Test-TerraformRunningAsAdmin -ne $true)) {
			Write-Host -Object "`nSpecified to create 'System' variables but session is not running as Administrator..." -ForegroundColor DarkGray -NoNewline
			Write-Host -Object "Creating 'User' variables instead..." -ForegroundColor DarkGray
			$System = $false
		}
	}
	process {
		foreach ($EnvironmentVariable in $EnvironmentVariables.GetEnumerator()) {
			Write-Host -Object "Configuring environment variable: " -ForegroundColor DarkGray -NoNewline
			Write-Host -Object "$($EnvironmentVariable.Name)..." -ForegroundColor White
			if ($System) {
				[Environment]::SetEnvironmentVariable($($EnvironmentVariable.Name), $($EnvironmentVariable.Value), [System.EnvironmentVariableTarget]::Machine)
			} else {
				[Environment]::SetEnvironmentVariable($($EnvironmentVariable.Name), $($EnvironmentVariable.Value), [System.EnvironmentVariableTarget]::User)
			}
		}
	}
	end {}
}
