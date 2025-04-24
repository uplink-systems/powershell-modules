function Invoke-TerraformApply {
	<#
		.SYNOPSIS
		Invoke "terraform.exe apply" command
		.DESCRIPTION
		The function applies changes of a Terraform project folder using "terraform apply" command and options.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER AutoApprove [bool]
		The optional parameter $AutoApprove specifies whether or not to automatically approve changes during apply.
		Default to: $false
		.PARAMETER Lock [bool]
		The optional parameter $Lock specifies whether or not the state file shall be locked while applying the changes.
        Defaults to: $true
		.PARAMETER Out [bool]
		The optional parameter $Out specifies whether or not to apply with or without out plan file.
        Defaults to: $false
        .PARAMETER OutFile [string]
        The optional parameter $OutFile specifies the name of the out file to apply. Only applying if $Out=$true.
        Defaults to: tfplan
		.INPUTS
		System.IO.FileInfo
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfApply")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[bool] $AutoApprove = $false,
		[Parameter(Mandatory=$false)]
		[bool] $Lock = $true,
		[Parameter(Mandatory=$false)]
		[bool] $Out = $false,
		[Parameter(Mandatory=$false)]
		[string] $OutFile = "tfplan"
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		if ($Out -and (Test-Path -Path $OutFile)) {
			Write-Host -Object "-> Applying changes using plan file...`n" -ForegroundColor DarkGray
			if ($AutoApprove) {
				Start-Process -FilePath "terraform.exe" -ArgumentList "apply $OutFile -lock=$($Lock.ToString()) -auto-approve" -NoNewWindow -PassThru -Wait | Out-Null
			} else {
				Start-Process -FilePath "terraform.exe" -ArgumentList "apply $OutFile -lock=$($Lock.ToString())" -NoNewWindow -PassThru -Wait | Out-Null
			}
		} else {
			Write-Host -Object "-> Applying changes...`n" -ForegroundColor DarkGray
			if ($AutoApprove) {
				Start-Process -FilePath "terraform.exe" -ArgumentList "apply -lock=$($Lock.ToString()) -auto-approve" -NoNewWindow -PassThru -Wait | Out-Null
			} else {
				Start-Process -FilePath "terraform.exe" -ArgumentList "apply -lock=$($Lock.ToString())" -NoNewWindow -PassThru -Wait | Out-Null
			}
		}
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}