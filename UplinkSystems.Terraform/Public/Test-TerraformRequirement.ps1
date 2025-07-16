function Test-TerraformRequirement {
	<#
		.SYNOPSIS
		Test for Terraform's requirements
		.DESCRIPTION
		The function validates if all requirements for Terraform to run are fullfilled:
		- Is a terraform.exe process currently active/running?
		- Is the application path in the %PATH% environment variable?
		- Is terraform.exe located in the application path?
		- Is terraform.exe version supported by the module?
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Test-TfRequirement")]
	param(
		[Parameter(Mandatory=$false)] [string] $MinTerraformVersion = "1.12.0"
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Write-Host -Object "`nValidating Terraform requirements... " -ForegroundColor DarkGray -NoNewline
		Start-Sleep -Seconds 2
	}
	process {
		if (Get-Process | Where-Object {$_.ProcessName -eq "terraform.exe"}) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "Running Terraform application found; please stop all active terraform.exe processes...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		$TerraformPath = $env:PATH -Split ';' | Where-Object {$_ -like "*Terraform*"}
		if (-not($TerraformPath)) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "No Terraform path found in PATH environment variable...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		if (-not(Test-Path -Path $(Join-Path -Path $TerraformPath -ChildPath "terraform.exe"))) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "No Terraform executable found in PATH environment variable's folder $($TerraformPath)...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		if (-not([Version]($(Get-TerraformVersionInstalled)[1]) -ge [Version]$MinTerraformVersion)) {
			Write-Host -Object "Failed...: " -ForegroundColor Red
			Write-Host -Object "Minimum Terraform executable version ($MinTerraformVersion) not installed...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		Write-Host -Object "Success... " -ForegroundColor Green
	}
	end {}
}

