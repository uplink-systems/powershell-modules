function Invoke-TerraformStatePull {
	<#
		.SYNOPSIS
		Invoke "terraform.exe state pull" command
		.DESCRIPTION
		The function creates a backup of Terraform state using "terraform state pull" command and options.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter -WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
        .PARAMETER BackupFile [string]
        The optional parameter -BackupFile specifies the name of backup file to pull the current state file to. Can be a file
		name only (saves to -WorkingDir) or a full path and file name.
        Defaults to: (Join-Path -Path $WorkingDir -ChildPath "Backup-$(Get-Date -Format "yyyyMMdd-HHmm").tfstate")
		.INPUTS
		System.IO.FileInfo
		String
        .EXAMPLE
        Invoke-TerraformStatePull -WorkingDir "C:\Terraform\ProjectName" -BackupFile "Backup-TerraformState.tfstate"
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Invoke-TfStatePull')]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage='Enter the Terraform working/project directory...')]
		[ValidateScript({if(-not($_ | Test-Path)) {throw 'Directory does not exist...'}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[String] $BackupFile = (Join-Path -Path $WorkingDir -ChildPath "Backup-$(Get-Date -Format 'yyyyMMdd-HHmm').tfstate")
	)
	begin {
		[Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		Start-Process -FilePath "terraform.exe" -ArgumentList "state pull" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $BackupFile | Out-Null
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
		$ErrorActionPreference = $Preferences[0]
	}
}