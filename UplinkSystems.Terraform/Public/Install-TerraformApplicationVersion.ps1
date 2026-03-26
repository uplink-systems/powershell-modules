function Install-TerraformApplicationVersion {
    <#
        .SYNOPSIS
        Install a specific or latest version of the Terraform application.
        .DESCRIPTION
        The function downloads and installs either a specific version of Terraform or the latest
        stable one available into the specified Terraform application root directory. The function
        supports multi-version setups. Alpha versions, beta versions, release candidate versions or
        similar version can only be installed/maintained using the -Version parameter and are
        ignored as latest version.
        .PARAMETER Version [String]
        The mandatory parameter -Version specifies a specific Terraform version to install.
        .PARAMETER Latest [Switch]
        The mandatory parameter -Latest forces the function to install the latest stable
        Terraform version instead of a specific version.
        .PARAMETER TerraformAppPlatform [String]
        The optional parameter -TerraformAppPlatform specifies the Terraform application platform
        version to install. Keep it unchanged if the function is used to download/install Terraform
        for the current system, because the function automatically detects the correct platform value.
        Defaults to: Get-TerraformApplicationCurrentPlatform
        .PARAMETER TerraformAppRootPath [String]
        The optional parameter -TerraformAppRootPath specifies the Terraform application versions'
        root directory. Keep it unchanged if the platforms' default paths should be used.
        Defaults to: Get-TerraformApplicationDefaultRootPath
        .PARAMETER SetAsActive [Switch]
        The optional parameter -SetAsActive instructs the function to set the new Terraform version
        as active version.
        .INPUTS
        None. You cannot pipe objects to Install-TerraformApplicationVersion.
        .OUTPUTS
        System.IO.File
        .EXAMPLE
        Install-TerraformApplicationVersion -Version 0.13.1
        .EXAMPLE
        Install-TfApplicationVersion -Latest
        .EXAMPLE
        Install-TerraformApplicationVersion -L -SetAsActive
    #>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Install-TfApplicationVersion')]
    param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Version')]
        [Alias('V')]
        [ValidatePattern("([0-9]+\.[0-9]+\.[0-9]+)?(-[\S]+)?()")]
        [String] $Version,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Latest')]
        [Alias('L')]
        [Switch] $Latest,
        [Parameter(Mandatory=$false)]
        [ValidateSet('darwin_amd64','linux_amd64','windows_amd64')]
        [Alias('TfAppPlatform','TfPlatform')]
        [String] $TerraformAppPlatform = (Get-TerraformApplicationCurrentPlatform),
        [Parameter(Mandatory=$false)]
        [Alias('TfAppRoot','TfPath')]
        [String] $TerraformAppRootPath = (Get-TerraformApplicationDefaultRootPath),
        [Parameter(Mandatory=$false)]
        [Switch] $SetAsActive
    )
    begin {
        # validate Terraform app root path, create if not exists
        if (-not(Test-Path -Path $TerraformAppRootPath)) {New-Item -Path $TerraformAppRootPath -ItemType Directory -Force | Out-Null}
        # get content of HashiCorp Terraform release page and filter for available releases
        [System.Collections.ArrayList]$TerraformReleases = (Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/' -UseBasicParsing | Select-Object -ExpandProperty Content) -split "`n" | Select-String -Pattern '(?<=\/)([\d]+.[\d]+.[\d]+-[\w]+[\d]+|[\d]+.[\d]+.[\d]+)' | ForEach-Object {$_.Matches | ForEach-Object {$_.Groups[1].Value}}
    }
    process {
        # select version number depending on parameter selected
        switch ($PSCmdlet.ParameterSetName) {
            'Version' {
                Write-Host -Object "Fetching infos for Terraform version $Version..." -ForegroundColor White
                # stop if the requested version number format is invalid or if the requested version number doesn't exist in release list
                if (($Version -notlike "*.*.*") -or ($TerraformReleases -notcontains $Version)) {Write-Host -Object "Version $Version is invalid or not found in release list..." -ForegroundColor Red; break}
            }
            'Latest' {
                Write-Host -Object "Fetching infos for the latest stable Terraform version..." -ForegroundColor White
                # find latest stable version number, if the version on top of the array is not a stable version
                switch ($TerraformReleases[0] -match '-') {
                    $true { 
                        $i = 0
                        do {$i += 1; $Version = $TerraformReleases[$i]} while ($Version -match '-')
                    }
                    default {$Version = $TerraformReleases[0]}
                }
            }
        }
        # if selected release exists, check wether or not it already exists
        switch (Test-Path -Path (Join-Path -Path $TerraformAppRootPath -ChildPath $Version)) {
            $true {
                Write-Host -Object "Terraform version $Version is already downloaded/installed..." -ForegroundColor Yellow
                continue
            }
            default {
                try {
                    # download selected release to temporary file
                    Write-Host -Object "Downloading Terraform version $Version..." -ForegroundColor White
                    $Uri = "https://releases.hashicorp.com/terraform/" + $Version + "/terraform_" + $Version + "_" + $TerraformAppPlatform + ".zip"
                    $DownloadTempFile = [System.IO.Path]::GetTempFileName()
                    Invoke-WebRequest -Uri $Uri -OutFile $DownloadTempFile -UseBasicParsing
                    # unzip temporary file to version folder
                    Expand-Archive -Path $DownloadTempFile -DestinationPath (Join-Path -Path $TerraformAppRootPath -ChildPath $Version) -Force
                    # remove temporary file
                    Remove-Item -Path $DownloadTempFile -Force
                    Write-Host -Object "Terraform version $Version downloaded/installed to $(Join-Path -Path $TerraformAppRootPath -ChildPath $Version)..." -ForegroundColor Green
                    # if switch -SetAsActive is present, set new version as active version
                    if ($SetAsActive) {
                        Set-TerraformApplicationActiveVersion -Version $Version -TerraformAppPlatform $TerraformAppPlatform -TerraformAppRootPath $TerraformAppRootPath
                        Write-Host -Object "Terraform version $Version set as active version..." -ForegroundColor Green
                    }
                }
                catch {
                    Write-Host -Object "Terraform version $Version could not be downloaded/installed..." -ForegroundColor Red
                    return
                }
            }
        }
        # add application root to PATH variable if needed
        Start-Sleep -Seconds 1
        switch ($TerraformAppPlatform) {
            # Linux
            'linux_arm64' {
                if ($ENV:PATH -notlike "*$TerraformAppRootPath*") {
                    Write-Host -Object "Adding Terraform application root path to user's PATH variable..."
                    $ENV:PATH += $TerraformAppRootPath
                }
            }
            # MacOS
            'darwin_arm64' {
                if ($ENV:PATH -notlike "*$TerraformAppRootPath*") {
                    Write-Host -Object "Adding Terraform application root path to user's PATH variable..."
                    $ENV:PATH += $TerraformAppRootPath
                }
            }
            # Windows / default
            default {
                $GetEnvPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
                if ($GetEnvPath -notlike "*$TerraformAppRootPath*") {
                    Write-Host -Object "Adding Terraform application root path to user's PATH variable..."
                    $SetEnvPath = "$GetEnvPath;$TerraformAppRootPath"
                    [System.Environment]::SetEnvironmentVariable("PATH", $SetEnvPath, [System.EnvironmentVariableTarget]::User)
                }
            }
        }
    }
    end {}
}