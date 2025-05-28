function Install-TerraformApplication {
	<#
		.SYNOPSIS
		Download and install Terraform application (Windows x64 version only)
		.DESCRIPTION
		The function installs the Terraform application to the local system (Windows x64 version
        only). It checks HashiCorps' GitHub repository for the latest release number (tag) and
        downloads the 64 bit version for Windows from HashiCorp's release site. After that the
        script expands the archive, moves the application to program files directory and adds
        the installation path to the system's PATH environment variable. The function depends on 
        HashiCorp maintaining its current naming convention.
        .PARAMETER WorkingDir [System.IO.FileInfo]
        The optional parameter $WorkingDir specifies the directory to download the archive to
        and to expand the archive to.
        Default: $ENV:TEMP
        .PARAMETER DebugEnabled [Switch]
        The optional parameter $DebugEnabled specifies to run the script in debug mode. Exception
        types are written to console in debug mode.
        .OUTPUTS
        System.IO.File
        .EXAMPLE
        Install-Terraform
        .EXAMPLE
        Install-Terraform -DebugEnabled
        .EXAMPLE
        Install-Terraform -WorkingDir "C:\TEMP\TfInstall"
	#>
    [CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Install-TfApplication")]
    param(
        [Parameter(Mandatory=$false)] [System.IO.FileInfo] $WorkingDir = $ENV:TEMP,
        [Parameter(Mandatory=$false)] [System.IO.FileInfo] $InstallDir = (Join-Path -Path $ENV:ProgramFiles -ChildPath "Terraform"),
        [Parameter()] [switch] $DebugEnabled
    )
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
        $VersionNumber = ((Invoke-RestMethod -Method GET -Uri "https://api.github.com/repos/hashicorp/terraform/releases/latest" -ErrorAction Stop).tag_name).SubString(1)
        $WebRequestUri = "https://releases.hashicorp.com/terraform/$($VersionNumber)/terraform_$($VersionNumber)_windows_amd64.zip"
        $ArchiveFile = "terraform_$($VersionNumber)_windows_amd64.zip"
        $ArchiveFilePath = Join-Path -Path $WorkingDir -ChildPath $ArchiveFile
        $ArchiveExpandDir = Join-Path -Path $WorkingDir -ChildPath "Terraform"
        $ArchiveExpandFilePath = Join-Path -Path $ArchiveExpandDir -ChildPath "*"
    }
    process {
        if ($DebugEnabled.IsPresent) {
            Write-Host -Object "NOTE: debug mode is enabled... writing debug messages to console..." -ForegroundColor Yellow
        }
        if (Test-Path -Path $WorkingDir) {
            Set-Location -Path $WorkingDir
        } else {
            Write-Host "Directory specified in WorkingDir parameter not found. Please restart Terraform installation with a valid WorkingDir parameter." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host -Object "Insufficient permissions detected. Please restart Terraform installation as Administrator." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
        try {
            Write-Host -Object "Downloading Terraform version $VersionNumber archive file... " -ForegroundColor DarkGray -NoNewline
            Invoke-WebRequest -Uri $WebRequestUri -OutFile $ArchiveFile -ErrorAction Stop
            Write-Host -Object "Success..." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Host -Object "Failed..." -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
        try {
            Write-Host -Object "Expanding downloaded Terraform archive file... " -ForegroundColor DarkGray -NoNewline
            Expand-Archive -Path $ArchiveFile -DestinationPath $ArchiveExpandDir -Force -ErrorAction Stop
            Write-Host -Object "Success..." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Host -Object "Failed... " -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
        try {
            Write-Host -Object "Installing Terraform executable... " -ForegroundColor DarkGray -NoNewline
            if (-not(Test-Path -Path $InstallDir)) {
                New-Item -Path $InstallDir -ItemType Directory
            }
            Copy-Item -Path $ArchiveExpandFilePath -Destination $InstallDir -Recurse -Force -ErrorAction Stop
            Write-Host -Object "Success..." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Host -Object "Failed..." -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
        try {
            Write-Host -Object "Adding Terraform path to PATH environment variable... " -ForegroundColor DarkGray -NoNewline
            $GetEnvPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
            if ($GetEnvPath -notlike "*$InstallDir*") {
                $SetEnvPath = "$GetEnvPath;$InstallDir"
                [System.Environment]::SetEnvironmentVariable("Path", $SetEnvPath, [System.EnvironmentVariableTarget]::Machine)
                Write-Host -Object "Success..." -ForegroundColor Green
                Start-Sleep -Seconds 2
            } else {
                Write-Host -Object "Skipped, already existing..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 2
            }
        }
        catch {
            Write-Host -Object "Failed..." -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
    }
    end {
        Remove-Item -Path $ArchiveFilePath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $ArchiveExpandDir -Recurse -Force -ErrorAction SilentlyContinue
        Set-Location -Path $MyInvocation.PSScriptRoot
    }
}
