function Test-TerraformWorkingDirectory {
	<#
		.SYNOPSIS
		Validate given working directory
		.DESCRIPTION
		This function verifies that the given working directory is valid. It tests that the directory
		exists and that it contains valid Terraform file types. It returns $true or $false as result.
		.PARAMETER WorkingDir [System.IO.FileInfo]
		The mandatory parameter $WorkingDir specifies the directory to validate.
		.INPUTS
		System.String
		.OUTPUTS
		System.Boolean
	#>
	[CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Test-TfWorkingDirectory")]
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline)] [System.IO.FileInfo] $WorkingDir
	)
	begin {
		$ErrorActionPreference = 'SilentlyContinue'
		$WorkingDir = $(Get-Item $WorkingDir).FullName
	}
	process {
		$TerraformWorkDir = Test-Path -Path $WorkingDir
		$TerraformFileTypes = Get-ChildItem -Path $(Join-Path -Path $WorkingDir -ChildPath "\*") -recurse -include "*.tf","*.tf.json","*.tfvars"
	}
	end {
		if ($TerraformWorkDir -and $TerraformFileTypes) {return $true} else {return $false}
	}
}