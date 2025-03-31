function Invoke-TerraformGet {
	<#
		.SYNOPSIS
		Invoke "terraform.exe get" command
		.DESCRIPTION
		The function to downloads/updates modules before planning/applying changes using "terraform.exe get" command.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER Update [bool]
		The optional parameter $Update specifies if modules shall only be downloaded if not existing or downloaded and
		updated even if the module already exists.
		Default to: $true
		.EXAMPLE
		Invoke-TerraformGet -WorkingDir "C:\Terraform\Project"
		Invoke-TerraformGet -WorkingDir "Project" -Update $false
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfGet")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[bool] $Update = $true
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		if ($Update) {
			Write-Host -Object "-> Checking for required modulels and installing/replacing/updating...`n" -ForegroundColor DarkGray
			$Global:TerraformGet = Start-Process -FilePath "terraform.exe" -ArgumentList "get -update" -NoNewWindow -PassThru -Wait
		} else {
			Write-Host -Object "-> Checking for required modules and installing...`n" -ForegroundColor DarkGray
			$Global:TerraformGet = Start-Process -FilePath "terraform.exe" -ArgumentList "get" -NoNewWindow -PassThru -Wait
		}
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}