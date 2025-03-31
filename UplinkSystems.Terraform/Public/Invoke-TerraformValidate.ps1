function Invoke-TerraformValidate {
	<#
		.SYNOPSIS
		Invoke "terraform.exe validate" command
		.DESCRIPTION
		The function to validates Terraform code.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.EXAMPLE
		Invoke-TerraformValidate -WorkingDir "C:\Terraform\Project"
		Invoke-TerraformValidate -WorkingDir "Project"
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfValidate")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		Write-Host -Object "-> Validating code...`n" -ForegroundColor DarkGray
		$Global:TerraformValidate = Start-Process -FilePath "terraform.exe" -ArgumentList "validate" -NoNewWindow -PassThru -Wait
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}