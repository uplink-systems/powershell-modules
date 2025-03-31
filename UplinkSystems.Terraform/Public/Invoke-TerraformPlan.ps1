function Invoke-TerraformPlan {
	<#
		.SYNOPSIS
		Invoke "terraform.exe plan" command
		.DESCRIPTION
		The function plans changes of a Terraform project folder using "terraform plan" command and options. In addition, 
        using -OutFileGraph parameter, the function creates a tfgraph file for VS Code Terraform Graph extention.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir represents the project directory (project's root module) to execute the command in.
		Either a full path must be provided or a subfolder as relative path to $PSScriptRoot.
		.PARAMETER Lock [bool]
		The optional parameter $Lock specifies whether or not the state file shall be locked while planning the changes.
        Defaults to: $true
		.PARAMETER Out [bool]
		The optional parameter $Out specifies whether or not to plan with or without out plan file.
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
		.OUTPUTS
		System.IO.FileInfo
	#>
	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Invoke-TfPlan")]
	param(
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter the Terraform working/project directory...")]
		[ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
		[System.IO.FileInfo] $WorkingDir,
		[Parameter(Mandatory=$false)]
		[bool] $Lock = $true,
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
		if ($Out) {
			Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
			Write-Host -Object "-> Planning changes using plan file...`n" -ForegroundColor DarkGray
			$Global:TerraformPlan = Start-Process -FilePath "terraform.exe" -ArgumentList "plan $LockOption $RefreshOption -out=$OutFile" -NoNewWindow -PassThru -Wait
			Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
			if ($OutFileGraph) {
				Write-Host -Object "-> Creating visualization file from plan for Terraform Graph VSCode extension... " -ForegroundColor DarkGray -NoNewLine
				$Global:TerraformShow = Start-Process -FilePath "terraform.exe" -ArgumentList "show -json $OutFile" -NoNewWindow -PassThru -Wait -RedirectStandardOutput ".\$OutFile.tfgraph"
			}
		}
		else {
			Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
			Write-Host -Object "-> Planning changes...`n" -ForegroundColor DarkGray
			$Global:TerraformPlan = Start-Process -FilePath "terraform.exe" -ArgumentList "plan $LockOption $RefreshOption" -NoNewWindow -PassThru -Wait
		}
	}
	end {
		Set-Location -Path $MyInvocation.PSScriptRoot
	}
}