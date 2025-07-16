function Uninstall-Terraform {
	<#
		.SYNOPSIS
		Uninstall Terraform application (Windows x64 version only)
		.DESCRIPTION
		The function uninstalls the Terraform application to the local system (Windows x64 version
        only).
        .PARAMETER InstallDir [System.IO.FileInfo]
        The optional parameter $InstallDir specifies the install directory for Terraform.
        Default: $ENV:ProgramFiles\Terraform
        .PARAMETER DebugEnabled [Switch]
        The optional parameter $DebugEnabled specifies to run the script in debug mode. Exception
        types are written to console in debug mode.
        .OUTPUTS
        System.IO.File
        .EXAMPLE
        Uninstall-Terraform
        .EXAMPLE
        Uninstall-Terraform -DebugEnabled
        .EXAMPLE
        Uninstall-Terraform -InstallDir "C:\Windows\System32"
	#>
    [CmdletBinding(HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform")]
	[Alias("Uninstall-Tf")]
    param(
        [Parameter(Mandatory=$false)] [System.IO.FileInfo] $InstallDir = (Join-Path -Path $ENV:ProgramFiles -ChildPath "Terraform"),
        [Parameter()] [switch] $DebugEnabled
    )
    begin {
        $ErrorActionPreference = 'SilentlyContinue'
        if ($DebugEnabled.IsPresent) {Write-Host -Object "NOTE: debug mode is enabled... writing debug messages to console..." -ForegroundColor Yellow}
        if (-not(Test-TerraformRunningAsAdmin)) {
            Write-Host -Object "Insufficient permissions. Please restart Terraform uninstall as Administrator." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
        if ($InstallDir -match '\\$') {$InstallDir = $InstallDir.Substring(0,$InstallDir.Length-1)}
    }
    process {
        try {
            Write-Host -Object "Removing Terraform path from PATH environment variable... " -ForegroundColor DarkGray -NoNewline
            $GetEnvPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
            if ($GetEnvPath -like "*$InstallDir*") {
                $SetEnvPath = ($GetEnvPath.Split(';') | Where-Object { $_ -notlike "*$InstallDir*" }) -join ';'
                [System.Environment]::SetEnvironmentVariable("PATH", $SetEnvPath, [System.EnvironmentVariableTarget]::Machine)
                Write-Host -Object "Success..." -ForegroundColor Green
            }
            else {
                Write-Host -Object "Skipped... $InstallDir not found in PATH environment variable..." -ForegroundColor DarkGray
            }
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Host -Object "Failed... " -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
        try {
            Write-Host -Object "Uninstalling Terraform... " -ForegroundColor DarkGray -NoNewline
            if (Test-Path -Path $InstallDir) {
                Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
                Write-Host -Object "Success..." -ForegroundColor Green
            }
            else {
                Write-Host -Object "Skipped... $InstallDir not found in file system..." -ForegroundColor DarkGray
            }
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Host -Object "Failed... " -ForegroundColor Red
            if ($DebugEnabled) {Write-Host -Object "Exception info: $($Error[0].exception.GetType().fullname)..." -ForegroundColor DarkGray}
            Start-Sleep -Seconds 2
            return
        }
    }
    end {
        Set-Location -Path $MyInvocation.PSScriptRoot
    }
}
