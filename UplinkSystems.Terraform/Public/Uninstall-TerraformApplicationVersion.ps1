function Uninstall-TerraformApplicationVersion {
    <#
        .SYNOPSIS
        Remove a specific version of the Terraform CLI application.
        .DESCRIPTION
        The function removes a specific version of Terraform from the local multi-version
        library folder.
        .PARAMETER Version [String]
        The mandatory parameter -Version specifies the version number of Terraform to remove.
        .PARAMETER AllVersionsExceptLast [Int32]
        The mandatory parameter -AllVersionsExceptLast specifies a number of last versions
        to remain installed. The function removes all other versions.
        .INPUTS
        None. You cannot pipe objects to Uninstall-TerraformApplicationVersion.
        .OUTPUTS
        None. The function Uninstall-TerraformApplicationVersion does not create an output.
        .EXAMPLE
        Uninstall-TerraformApplicationVersion -Version 0.13.1
        .EXAMPLE
        Uninstall-TerraformApplicationVersion -AllVersionsExceptLast 3
    #>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Uninstall-TfApplicationVersion')]
    param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='UninstallVersionNumber')]
        [ValidateNotNullOrEmpty()]
        [String] $Version,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='UninstallAllExceptLastVersions')]
        [Int32] $AllVersionsExceptLast,
        [Parameter(Mandatory=$false)]
        [Alias('TfAppRoot','TfPath')]
        [String] $TerraformAppRootPath = (Get-TerraformApplicationDefaultRootPath),
        [Parameter(Mandatory=$false)] [Bool] $Confirm = $false
    )

    switch ($PSCmdlet.ParameterSetName) {
        'UninstallAllExceptLastVersions' {
            Write-Host -Object "Detecting installed versions of Terraform application in $TerraformAppRootPath..."
            $InstalledVersions = Get-ChildItem -Path $TerraformAppRootPath -Directory | Sort-Object -Property Name -Descending
            if ($InstalledVersions.Count -gt $AllVersionsExceptLast) {
                $UninstallVersions = $InstalledVersions[$AllVersionsExceptLast..($InstalledVersions.count)]
                Write-Host -Object "Number of versions to keep ($AllVersionsExceptLast) is greater than number of versions installed ($($InstalledVersions.Count))... Proceeding..."
                Start-Sleep -Seconds 1
                foreach ($UninstallVersion in $UninstallVersions) {
                    Write-Host -Object "Uninstalling Terraform version $($UninstallVersion.Name)... " -NoNewline
                    Remove-Item -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $($UninstallVersion.Name)) -Recurse -Force -Confirm:$Confirm -ErrorAction Stop
                    if (-not(Test-Path -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $($UninstallVersion.Name)))) {Write-Host -Object "Success..." -ForegroundColor Green} else {Write-Host -Object "Failed..." -ForegroundColor Red}
                }
            }
            else {
                Write-Host -Object "Number of versions to remain ($AllVersionsExceptLast) is less or equal than number of versions installed ($($InstalledVersions.Count))... Skipping..."
            }
        }
        'UninstallVersionNumber' {
            if (Test-Path -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $Version)) {
                Write-Host -Object "Uninstalling Terraform version $Version... " -NoNewline
                Remove-Item -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $Version) -Recurse -Force -Confirm:$Confirm -ErrorAction Stop
                if (-not(Test-Path -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $Version))) {Write-Host -Object "Success..." -ForegroundColor Green} else {Write-Host -Object "Failed..." -ForegroundColor Red}
            }
            else {
                Write-Host -Object "Terraform version $Version not found... Skipping..."
            }
        }
    }
}