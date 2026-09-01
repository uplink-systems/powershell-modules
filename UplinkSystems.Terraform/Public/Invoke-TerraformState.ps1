function Invoke-TerraformState {
	<#
		.SYNOPSIS
		Invoke "terraform.exe state" commands
		.DESCRIPTION
		The function manages Terraform states using "terraform state" commands and options. The
		function does not yet support -var and -var-file parameter of terraform executable.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module)
		to execute the command in. Either a full path must be provided or a subfolder as relative
		path of $PSScriptRoot.
		.PARAMETER Backup [switch]
		The optional parameter $Backup specifies "terraform state pull" command shall be executed.
		This command creates a backup file of the current state.
        .PARAMETER BackupFile [string]
        The optional parameter $BackupFile specifies the name of the backup file to pull the current
		state file to. Can be a file name only (saves to $WorkingDir) or a full path and file name.
        Defaults to: (Join-Path -Path $WorkingDir -ChildPath "Backup-$(Get-Date -Format "yyyyMMdd-HHmm").tfstate")
		.PARAMETER Move [switch]
		The optional parameter $Move specifies "terraform state mv" command shall be executed.
		.PARAMETER Remove [switch]
		The optional parameter $Remove specifies "terraform state rm" command shall be executed.
		.PARAMETER Restore [switch]
		The optional parameter $Restore specifies "terraform state push" command shall be executed.
		This command restores the state from a backup file.
        .PARAMETER RestoreFile [string]
        The optional parameter -RestoreFile specifies the name of the restore file to push the current
		state file from. Can be a file name only (loads from -WorkingDir) or a full path and file name.
        Defaults to: (Get-ChildItem -Path (Join-Path -Path $WorkingDir -ChildPath Backup*.tfstate) | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
		.PARAMETER Show [switch]
		The optional parameter $Show specifies "terraform state show" command shall be executed.
		.PARAMETER Resource [string]
		The mandaotry parameter $Resource specifies which resource shall be processed.
		.PARAMETER ResourceTarget [string]
		The mandaotry parameter $ResourceTarget specifies to which new resource shall be moved.
		.PARAMETER DryRun [switch]
		The optional parameter $DryRun specifies "terraform state mv" or "terraform state rm" 
		commands shall be executed in simulation mode only.
		.PARAMETER Silent [switch]
		The optional parameter $Silent specifies "terraform state push" commands shall be executed
		in silent mode (executing without warning and confirmation to overwrite current state).
		.EXAMPLE
		Invoke-TerraformState -WorkingDir "C:\Terraform\Project"
		Invoke-TerraformState ".\Project" -Show -Resource 'packet_device.worker'
		Invoke-TerraformState -WorkingDir ".\Project" -Move -Resource 'packet_device.worker' -ResourceTarget 'packet_device.server'
		Invoke-TerraformState "C:\Terraform\Project" -Remove -Resource 'packet_device.worker' -DryRun
		Invoke-TerraformState ".\Project" -Backup -BackupFile "C:\Backup\TFState.tfstate"
		Invoke-TerraformState -WorkingDir ".\Project" -Restore -Silent
	#>
	[CmdletBinding(DefaultParameterSetName='List',HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Invoke-TfState')]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage='Enter the Terraform working/project directory...')]
		[ValidateScript({if(-not($_ | Test-Path)) {throw 'Directory does not exist...'}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false,ParameterSetName='Backup')]
		[switch] $Backup,
		[Parameter(Mandatory=$false,ParameterSetName='Backup')]
		[String] $BackupFile = (Join-Path -Path $WorkingDir -ChildPath "Backup-$(Get-Date -Format 'yyyyMMdd-HHmm').tfstate"),
		[Parameter(Mandatory=$false,ParameterSetName='Move')]
		[switch] $Move,
		[Parameter(Mandatory=$false,ParameterSetName='Remove')]
		[switch] $Remove,
		[Parameter(Mandatory=$false,ParameterSetName='Restore')]
		[switch] $Restore,
		[Parameter(Mandatory=$false,ParameterSetName='Restore')]
		[String] $RestoreFile = (Get-ChildItem -Path (Join-Path -Path $WorkingDir -ChildPath Backup*.tfstate) | Sort-Object LastWriteTime -Descending | Select-Object -First 1), # $null,
		[Parameter(Mandatory=$false,ParameterSetName='Show')]
		[switch] $Show,
		[Parameter(Mandatory=$false,ParameterSetName='List')]
		[Parameter(Mandatory=$true,ParameterSetName='Move')]
		[Parameter(Mandatory=$true,ParameterSetName='Remove')]
		[Parameter(Mandatory=$true,ParameterSetName='Show')]
		[string] $Resource,
		[Parameter(Mandatory=$true,ParameterSetName='Move')]
		[string] $ResourceTarget,
		[Parameter(Mandatory=$false,ParameterSetName='Move')]
		[Parameter(Mandatory=$false,ParameterSetName='Remove')]
		[switch] $DryRun,
		[Parameter(Mandatory=$false,ParameterSetName='Restore')]
		[switch] $Silent
	)
	begin {
		[Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue'
	}
	process {
		switch ($PSCmdLet.ParameterSetName) {
			'Backup' {
				Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state pull" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $BackupFile | Out-Null
			}
			'List' {
				if ($null -eq $Resource) {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state list" -NoNewWindow -PassThru -Wait | Out-Null
				}
				else {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state list $Resource" -NoNewWindow -PassThru -Wait | Out-Null
				}
			}
			'Move' {
				if ($DryRun.IsPresent) {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state mv $Resource $ResourceTarget -dry-run" -NoNewWindow -PassThru -Wait | Out-Null
				}
				else {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state mv $Resource $ResourceTarget" -NoNewWindow -PassThru -Wait | Out-Null
				}
			}
			'Remove' {
				if ($DryRun.IsPresent) {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state rm $Resource -dry-run" -NoNewWindow -PassThru -Wait | Out-Null
				}
				else {
					Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state rm $Resource" -NoNewWindow -PassThru -Wait | Out-Null
				}
			}
			'Restore' {
				if (-not($Silent.IsPresent)) {
					Write-Host -Object "`nCAUTION!" -ForegroundColor Red
					Write-Host -Object "The Terraform state file will be overwritten with content from $RestoreFile." -ForegroundColor Red
					Write-Host -Object "This action is irreversible and cannot be undone. Do you want to proceed anyway?" -ForegroundColor Red
					do {Write-Host -Object "[Y] Yes, continue operation  [N] No, stop operation: " -ForegroundColor Red -NoNewline;$ConfirmStatePush = Read-Host} until ($ConfirmStatePush -eq "Y" -or $ConfirmStatePush -eq "N")
					if (-not($Confirm -eq "Y")) {return}
				}
				Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state push -force $RestoreFile" -NoNewWindow -PassThru -Wait | Out-Null
			}
			'Show' {
				Start-Process -FilePath "terraform.exe" -WorkingDirectory $WorkingDir -ArgumentList "state show $Resource" -NoNewWindow -PassThru -Wait | Out-Null
			}
			default {}
		}
		Start-Sleep -Seconds 2
	}
	end {
		$ErrorActionPreference = $Preferences[0]
	}
}