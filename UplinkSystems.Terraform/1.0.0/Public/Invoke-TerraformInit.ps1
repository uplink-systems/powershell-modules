function Invoke-TerraformInit {
	<#
		.SYNOPSIS
		Invoke "terraform.exe init" command
		.DESCRIPTION
		The function initializes a Terraform project folder using "terraform init" command and options
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER Upgrade [bool]
		The optional parameter $Upgrade specifies if modules and provider plugins shall be upgraded during initialization.
		.EXAMPLE
		Invoke-TerraformInit -WorkingDir "C:\Terraform\Project"
		Invoke-TerraformInit -WorkingDir "Project" -Upgrade
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfInit")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[bool] $Upgrade = $false
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		if ($Upgrade) {
			Write-Host -Object "-> Initializing project and upgrading plugin versions...`n" -ForegroundColor DarkGray
			Start-Process -FilePath "terraform.exe" -ArgumentList "init -upgrade" -NoNewWindow -PassThru -Wait | Out-Null
		} else {
			Write-Host -Object "-> Initializing project...`n" -ForegroundColor DarkGray
			Start-Process -FilePath "terraform.exe" -ArgumentList "init" -NoNewWindow -PassThru -Wait | Out-Null
		}
		Start-Sleep -Seconds 2
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}