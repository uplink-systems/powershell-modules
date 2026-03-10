function Invoke-TerraformStatePush {
	<#
		.SYNOPSIS
		Invoke "terraform.exe state push" command
		.DESCRIPTION
		The function restores a backup of Terraform state using "terraform state push" command and options.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter -WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
        .PARAMETER BackupFile [string]
        The optional parameter -BackupFile specifies the name of backup file to push the current state file from. Can be a file
		name only (loads from -WorkingDir) or a full path and file name.
        Defaults to: (Join-Path -Path $WorkingDir -ChildPath "Backup-$(Get-Date -Format "yyyyMMdd-HHmm").tfstate")
		.INPUTS
		System.IO.FileInfo
		String
        .EXAMPLE
        Invoke-TerraformStatePush -WorkingDir "C:\Terraform\ProjectName" -BackupFile "Backup-TerraformState.tfstate"
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Invoke-TfStatePush')]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage='Enter the Terraform working/project directory...')]
		[ValidateScript({if(-not($_ | Test-Path)) {throw 'Directory does not exist...'}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[String] $BackupFile = $null,
		[Parameter(Mandatory=$false)]
		[Switch] $Silent
	)
	begin {
		[Array]$Preferences = $ErrorActionPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue';$InformationPreference = 'Continue'
		Set-Location -Path $WorkingDir
		if ($null -eq $BackupFile) {$BackupFile = Get-ChildItem -Path (Join-Path -Path $WorkingDir -ChildPath Backup*.tfstate) | Sort-Object LastWriteTime -Descending | Select-Object -First 1}
	}
	process {
		Write-Host -Object "`n$($WorkingDir)" -ForegroundColor White
		if (-not($Silent)) {
			Write-Host -Object "`nCAUTION!" -ForegroundColor Red
			Write-Host -Object "The Terraform state file will be overwritten with content from $BackupFile." -ForegroundColor Red
			Write-Host -Object "This action is irreversible and cannot be undone. Do you want to proceed anyway?" -ForegroundColor Red
			do {Write-Host -Object "[Y] Yes, continue operation  [N] No, stop operation: " -ForegroundColor Red -NoNewline;$ConfirmStatePush = Read-Host} until ($ConfirmStatePush -eq "Y" -or $ConfirmStatePush -eq "N")
			if (-not($Confirm -eq "Y")) {return}
		}
		Start-Process -FilePath "terraform.exe" -ArgumentList "state push -force $BackupFile" -NoNewWindow -PassThru -Wait | Out-Null
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
		$ErrorActionPreference = $Preferences[0];$InformationPreference = $Preferences[1]
	}
}