function Invoke-TerraformCustom {
	<#
		.SYNOPSIS
		Invoke any "terraform.exe" command/options combination specified in an argument list
		.DESCRIPTION
		The function runs any "terraform.exe" command. To specify which command/options shall run the function either 
		provide the parameter $ArgumentList or enter the command/options while executing the function.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER ArgumentList [string]
		The optional parameter $ArgumentList represents one the command and options to process with Terraform. If not
		provided, the function will ask for the parameter as variable during process.
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfCustom")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[String] $ArgumentList = ""

	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		if ($ArgumentList -eq "") {
			Write-Host -Object "`nNo value for the script parameter 'ArgumentList' found." -ForegroundColor DarkGray
			Write-Host -Object "Please provide the arguments to execute with Terraform" -ForegroundColor DarkGray
			Write-Host -Object "(command/options only, without Terraform executable itself)." -ForegroundColor DarkGray
			Write-Host -Object "See examples:" -ForegroundColor DarkGray
			Write-Host -Object "force-unlock <Lock-ID>  -> remove lock from state file" -ForegroundColor DarkGray
			Write-Host -Object "import <Resource-ID>    -> import resource to state" -ForegroundColor DarkGray
			Write-Host -Object "init -upgrade           -> init project and upgrade plugins/provider/terraform.exe" -ForegroundColor DarkGray
			Write-Host -Object "state list              -> list all resources in state" -ForegroundColor DarkGray
			Write-Host -Object "validate                -> validate code" -ForegroundColor DarkGray
			Write-Host -Object "Enter command/options to execute with Terraform: " -NoNewline
			$ArgumentList = Read-Host
		}
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		Write-Host -Object "-> Running custom command: terrafrom.exe $($ArgumentList)...`n" -ForegroundColor DarkGray
		$Global:TerraformCustom = Start-Process -FilePath "terraform.exe" -ArgumentList $ArgumentList -NoNewWindow -PassThru -Wait
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}