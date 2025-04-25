function Invoke-TerraformDestroy {
	<#
		.SYNOPSIS
		Invoke "terraform.exe plan -destroy" or "terraform apply -destroy" commands
		.DESCRIPTION
		The function destroys resources of a Terraform project folder using "terraform plan -destroy" command
		or "terraform apply -destroy" command. The command depends on $Mode parameter value. In addition,
        using -OutFileGraph parameter, the function creates a tfgraph file for VS Code Terraform Graph extention.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER AutoApprove [bool]
		The optional parameter $AutoApprove specifies whether or not to automatically approve changes during apply (used only
		if $Mode equals "apply")
		Default to: $false
		.PARAMETER Lock [bool]
		The optional parameter $Lock specifies whether or not the state file shall be locked while during plan/apply.
        Defaults to: $false
		.PARAMETER Mode [string]
		The optional parameter $Mode specifies if the function runs in plan-/dry-run- or apply-mode.
		Default to: plan
		.PARAMETER Out [bool]
		The optional parameter $Out specifies whether or not to plan/apply with or without out plan file.
        Defaults to: $false
        .PARAMETER OutFile [string]
        The optional parameter $OutFile specifies the name of the file to output the plan to. Only applying if $Out=$true.
        Defaults to: tfplan
        .PARAMETER OutFileGraph [bool]
        The optional parameter $OutFileGraph specifies if the plan file shall be exported as additional .tfgraph file for the
		Visual Studio Code Terraform Graph extension (https://marketplace.visualstudio.com/items?itemName=saramorillon.terraform-graph).
        Defaults to: $true
		.PARAMETER Refresh [bool]
		The optional parameter $Refresh specifies whether or not to plan in refresh mode only.
        Defaults to: $false
		.EXAMPLE
		Invoke-TerraformDestroy -WorkingDir "C:\Terraform\Project"
		Invoke-TerraformDestroy -WorkingDir "Project" -Mode "apply" -AutoApprove $true
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfDestroy")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[bool] $AutoApprove = $false,
		[Parameter(Mandatory=$false)]
		[bool] $Lock = $true,
		[Parameter(Mandatory=$false)]
		[ValidateSet("apply","plan")]
		[string] $Mode = "plan",
		[Parameter(Mandatory=$false)]
		[bool] $Out = $false,
		[Parameter(Mandatory=$false)]
		[string] $OutFile = "tfplan",
		[Parameter(Mandatory=$false)]
		[bool] $OutFileGraph = $true,
		[Parameter(Mandatory=$false)]
		[bool] $Refresh = $true
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		Set-Location -Path $WorkingDir
	}
	process {
		if ($Lock) {$LockOption = "-lock=true"} else {$LockOption = "-lock=false"}
		if ($Refresh) {$RefreshOption = "-refresh=true"} else {$RefreshOption = "-refresh=false"}
		Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
		switch ($Mode) {
			"plan" {
				if ($Out) {
					Write-Host -Object "-> Destroying deployment in plan mode (dry-run) using plan file... `n" -ForegroundColor DarkGray
					Start-Process -FilePath "terraform.exe" -ArgumentList "plan -destroy $LockOption $RefreshOption -out=$OutFile" -NoNewWindow -PassThru -Wait | Out-Null
					Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
					if ($OutFileGraph) {
						Write-Host -Object "-> Creating visualization file from plan... " -ForegroundColor DarkGray -NoNewLine
						Start-Process -FilePath "terraform.exe" -ArgumentList "show -json $OutFile" -NoNewWindow -PassThru -Wait -RedirectStandardOutput ".\$OutFile.tfgraph" | Out-Null
					}
				} else {
					Write-Host -Object "-> Destroying deployment in plan mode (dry-run)...`n" -ForegroundColor DarkGray
					Start-Process -FilePath "terraform.exe" -ArgumentList "plan -destroy $LockOption $RefreshOption" -NoNewWindow -PassThru -Wait | Out-Null
				}
			}
			"apply" {
				if ($Out -and (Test-Path -Path $OutFile)) {
					Write-Host -Object "-> Destroying deployment using plan file...`n" -ForegroundColor DarkGray
					if ($AutoApprove) {
						Start-Process -FilePath "terraform.exe" -ArgumentList "apply -destroy -auto-approve $LockOption $OutFile" -NoNewWindow -PassThru -Wait | Out-Null
					} else {
						Start-Process -FilePath "terraform.exe" -ArgumentList "apply -destroy $LockOption $OutFile" -NoNewWindow -PassThru -Wait | Out-Null
					}
				} else {
					Write-Host -Object "-> Destroying deployment...`n" -ForegroundColor DarkGray
					if ($AutoApprove) {
						Start-Process -FilePath "terraform.exe" -ArgumentList "apply -destroy -auto-approve $LockOption" -NoNewWindow -PassThru -Wait | Out-Null
					} else {
						Start-Process -FilePath "terraform.exe" -ArgumentList "apply -destroy $LockOption" -NoNewWindow -PassThru -Wait | Out-Null
					}
				}

			}
		}
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}