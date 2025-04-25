function Test-TerraformRequirement {
	<#
		.SYNOPSIS
		Test for Terraform's requirements
		.DESCRIPTION
		The function validates if all requirements for Terraform to run are fullfilled:
		- Is a terraform.exe process currently active/running?
		- Is the application path in the %path% variable?
		- Is terraform.exe located in the application path?
		- Is terraform.exe version supported? This is currently inactive as HashiCorp does not provide version info in the file yet.
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Test-TfRequirement")]
	param()
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Write-Host -Object "`nValidating Terraform requirements... " -ForegroundColor DarkGray -NoNewline
		Start-Sleep -Seconds 2
	}
	process {
		if (Get-Process | Where-Object {$_.ProcessName -eq "terraform.exe"}) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "Running Terraform application found; please stop all related terraform.exe processes...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		$TerraformPath = $env:Path -Split ';' | Where-Object { $_ -like "*Terraform*"}
		if (-not($TerraformPath)) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "Terraform path not found in path variable...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		if (-not(Test-Path -Path "$($TerraformPath)\terraform.exe")) {
			Write-Host -Object "Failed...: " -ForegroundColor Red -NoNewline
			Write-Host -Object "Terraform executable not found in path variable's folder $($TerraformPath)...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 2
			exit 1
		}
		# if (-not((Get-Item "$($TerraformPath)\terraform.exe").VersionInfo.FileVersion -gt "1.10")) {
		# 	Write-Host -Object "Failed...: " -ForegroundColor Red
		# 	Write-Host -Object "Terraform executable version not supported...`n" -ForegroundColor DarkGray
		#   Start-Sleep -Seconds 2
		# 	exit 1
		# }
		Write-Host -Object "Success... " -ForegroundColor Green
	}
	end {}
}