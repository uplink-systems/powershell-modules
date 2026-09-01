function New-TerraformProject {
    <#
        .SYNOPSIS
        Create a new default file and folder structure for a Terraform project.
        .DESCRIPTION
        The function creates a default file and folder structure for a Terraform
        project. It creates the folders, .tf files and a .gitignore file optimized
        for Terraform.
        .PARAMETER ProjectPath [String]
        The mandatory parameter -ProjectPath defines the project's root folder to
        create.
        .PARAMETER TfFiles [Array]
        The optional parameter -TfFiles defines an array of .tf files to create.
        Defaults to:
        data.tf,locals.tf,main.tf,output.tf,provider.tf,terraform.tf,variable.tf
        .PARAMETER RemoveExisting [Switch]
        The optional parameter -RemoveExisting forces to remove the project folder
        and project files before recreating them if the project already exists.
        Use this parameter carefully!
        .PARAMETER SkipGitIgnore [Switch]
        The optional parameter -SkipGitIgnore skips the creation of the .gitignore
        file, e.g. if the code is not stored in a Git repository.
        .INPUTS
        None. You cannot pipe objects to New-TerraformProject.
        .OUTPUTS
        System.IO.File
        .EXAMPLE
        New-TerraformProject -ProjectPath 'C:\Terraform\Project1'
        .EXAMPLE
        New-TerraformProject 'C:\Terraform\Project1' -NoGitIgnore -RemoveExisiting
    #>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('New-TfProject')]
    param (
        [Parameter(Mandatory=$true,Position=0)] [Alias('Project')] [String] $ProjectPath,
        [Parameter(Mandatory=$false)] [Array] $TfFiles = @('data.tf','locals.tf','main.tf','output.tf','provider.tf','terraform.tf','variable.tf'),
        [Parameter(Mandatory=$false)] [Switch] $RemoveExisting,
        [Parameter(Mandatory=$false)] [Switch] $SkipGitIgnore
    )
    begin {
		[Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
		$ErrorActionPreference = 'SilentlyContinue'
        $GitIgnore = @"
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets. These should not be part of version 
# control as they are data points which are potentially sensitive and subject 
# to change depending on the environment.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
# example: *tfplan*

# Ignore CLI configuration files
.terraformrc
terraform.rc
"@
    }
    process {
        # create (or recreate) project folder
        switch ($RemoveExisting.IsPresent) {
            $true {if (Test-Path -Path $ProjectPath) {Remove-Item -Path $ProjectPath -Recurse -Force | Out-Null}}
            default {}
        }
        if (-not(Test-Path -Path $ProjectPath)) {New-Item -Path $ProjectPath -ItemType Directory -Force | Out-Null}
        # create .tf files
        foreach ($TfFile in $TfFiles) {
            New-Item -Path (Join-Path -Path $ProjectPath -ChildPath $TfFile) -ItemType File -Force | Out-Null
        }
        # create .gitignore
        switch ($SkipGitIgnore.IsPresent) {
            $true {}
            default {$GitIgnore | Out-File -FilePath (Join-Path -Path $ProjectPath -ChildPath '.gitignore')}
        }
    }
    end {
        $ErrorActionPreference = $Preferences[0]
    }
}