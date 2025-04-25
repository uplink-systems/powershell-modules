
function Invoke-TerraformWorkingDirectoryCleanup {
	<#
		.SYNOPSIS
		Cleanup the working directory
		.DESCRIPTION
		The function runs a cleanup of the working directory for the following files:
        - plan file
        - plan tfgraph file
        The function can be used before and after deployment to run a cleanup.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The optional parameter $WorkingDir represents the project directory (project's root module) to execute the
        command in. Either a full path must be provided or a subfolder as relative path to $PSScriptRoot. The function
        uses the current directory if no value is specified.
        Default: $PWD
        .PARAMETER OutFile [string]
        The optional parameter $OutFile specifies the name of the plan file to search for.
        Default: tfplan
        .PARAMETER OutFileTfGraph [string]
        The optional parameter $OutFileTfGraph specifies the name of the plan tfgraph file to search for.
        Default: $OutFile.tfgraph
        .EXAMPLE
        Invoke-TerraformWorkingDirectoryCleanup
        .EXAMPLE
        Invoke-TerraformWorkingDirectoryCleanup -WorkingDir "C:\Terraform\ProjectName" -OutFile "terraformplan"
	#>

	[CmdletBinding(SupportsShouldProcess=$true,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
    [Alias ("Invoke-TfWorkingDirCleanup")]
	param(
        [Parameter(Mandatory=$false)] [ValidateScript({if(-not($_ | Test-Path)) {throw "Directory does not exist..."}; return $true})]
        [System.IO.FileInfo] $WorkingDir = $PWD,
        [Parameter(Mandatory=$false)]
        [string] $OutFile = "tfplan",
        [Parameter(Mandatory=$false)]
        [string] $OutFileTfGraph = "$OutFile.tfgraph"
    )
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
        $OutFilePath = Join-Path -Path $WorkingDir -ChildPath $OutFile
        $OutFilePathTfGraph = Join-Path -Path $WorkingDir -ChildPath $OutFileTfGraph
    }
    process {
        if ((Test-Path -Path $OutFilePath) -or (Test-Path -Path $OutFilePathTfGraph)) {
            Write-Host -Object "`n$($WorkingDir) " -ForegroundColor White -NoNewLine
            Write-Host -Object "-> Files found in project folder, cleaning up...`n" -ForegroundColor DarkGray
            Start-Sleep -Seconds 2
        }
        if (Test-Path -Path $OutFilePath) {
            Remove-Item -Path $OutFilePath -Force
        }
        if (Test-Path -Path $OutFilePathTfGraph) {
            Remove-Item -Path $OutFilePathTfGraph -Force
        }
    }
    end {}
}
