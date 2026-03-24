function Set-TerraformApplicationActiveVersion {
    <#
        .SYNOPSIS
        Set the active version of Terraform in a multi-version environment.
        .DESCRIPTION
        Set the version of Terraform that you want active. If the version doesn't
        exists in the library, it will ask to download the version.
        .PARAMETER Version [String]
        The mandatory parameter -Version specifies the version number of Terraform
        to set as active.
        .INPUTS
        None. You cannot pipe objects to Set-TerraformApplicationActiveVersion.
        .OUTPUTS
        System.String
        .NOTES
        The workflow for Windows is successfully tested but the workflow for Linux 
        and MacOS is not and should therefore treated as beta on these platforms.
        .EXAMPLE
        Set-TerraformApplicatonActiveVersion -Version 0.13.1
        .EXAMPLE
        Set-TerraformApplicatonActiveVersion 0.13.1
    #>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Set-TfApplicationActiveVersion')]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $Version,
        [Parameter(Mandatory=$false)]
        [ValidateSet('darwin_amd64','linux_amd64','windows_amd64')]
        [Alias('TfAppPlatform','TfPlatform')]
        [String] $TerraformAppPlatform = (Get-TerraformApplicationCurrentPlatform),
        [Parameter(Mandatory=$false)]
        [Alias('TfAppRoot','TfRootPath')]
        [String] $TerraformAppRootPath = (Get-TerraformApplicationDefaultRootPath),
        [Parameter(Mandatory=$false)]
        [Alias('TfAppVersion','TfVersionPath')]
        [String] $TerraformAppVersionPath = (Join-Path -Path $TerraformAppRootPath -ChildPath $Version)
    )
    try {
        Write-Host -Object "Switching active Terraform version to $Version... " -NoNewline
        switch ($TerraformAppPlatform) {
            'linux_amd64' {
                Copy-Item -Path (Join-Path -Path $TerraformAppVersionPath -ChildPath 'terraform') -Destination (Join-Path -Path $TerraformAppRootPath -ChildPath 'terraform') -Force -ErrorAction Stop
                chmod +x (Join-Path -Path $TerraformAppRootPath -ChildPath 'terraform')
            }
            'darwin_amd64' {
                Copy-Item -Path (Join-Path -Path $TerraformAppVersionPath -ChildPath 'terraform') -Destination (Join-Path -Path $TerraformAppRootPath -ChildPath 'terraform') -Force -ErrorAction Stop
                chmod +x (Join-Path -Path $TerraformAppRootPath -ChildPath 'terraform')
            }
            default {
                Copy-Item -Path (Join-Path -Path $TerraformAppVersionPath -ChildPath 'terraform.exe') -Destination (Join-Path -Path $TerraformAppRootPath -ChildPath 'terraform.exe') -Force -ErrorAction Stop
            }
        }
        $ActiveVersion = (Invoke-Expression "terraform --version" -ErrorAction Stop | Where-Object { $_ -match 'Terraform v\d{1,}\.\d{1,}\.\d{1,}' } | Select-String -Pattern "([\d]+.[\d]+.[\d]+-[\w]+[\d]+|[\d]+.[\d]+.[\d]+)").Matches.Value
        if ($ActiveVersion -eq $Version) {
            Write-Host -Object "Success..." -ForegroundColor Green
        }
        else {
            Write-Host -Object "Failed..." -ForegroundColor Red
        }
    }
    catch {
        Write-Host -Object "Failed... " -ForegroundColor Red -NoNewLine; Write-Host -Object "Version not found..."
    }
}