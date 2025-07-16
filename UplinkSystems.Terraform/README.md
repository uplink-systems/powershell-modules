## Module 'UplinkSystems.Terraform'

### Description

The module **UplinkSystems.Terraform** provides PowerShell functions for the following tasks:
* manage installation of Terraform executable where no software distribution or package manager like MECM or Chocolatey is available  
* manage Terraform projects from PowerShell scripts where no Azure DevOps pipelining or GitHub Actions is available for automation  
  
To achieve this goal the module contains the following public functions that can be used with its parameters to automate Terraform project commands:  
  
* <code>Install-Terraform</code>
* <code>Invoke-TerraformApply</code>
* <code>Invoke-TerraformCustom</code>
* <code>Invoke-TerraformDestroy</code>
* <code>Invoke-TerraformGet</code>
* <code>Invoke-TerraformInit</code>
* <code>Invoke-TerraformPlan</code>
* <code>Invoke-TerraformValidate</code>
* <code>Invoke-TerraformWorkingDirectoryCleanup</code>
* <code>Set-TerraformEnvironmentVariable</code>
* <code>Test-TerraformRequirement</code>
* <code>Uninstall-Terraform</code>
  
For detailed information about each functions options please refer to each function's comment based help.  
  
Please note:  
The module is currently intended to run on Windows operating systems only.  

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_powershell"></a> [PowerShell](#requirement\_powershell) | >= 7.0.0 |

### Release Notes

#### 1.1.0

BREAKING CHANGES:  
* Existing function <code>Install-TerraformApplication</code> changed to <code>Install-Terraform</code>.

NEW FEATURES:  
* New module function: <code>Uninstall-Terraform</code>
* New module private function: <code>Compare-TerraformVersion</code>
* New module private function: <code>Get-TerraformVersionAvailable</code>
* New module private function: <code>Get-TerraformVersionInstalled</code>

IMPROVEMENTS:
* <code>Install-Terraform</code>: improved pre-check order.
* <code>Install-Terraform</code>: added -Update switch to select to update existing Terraform installation.
* <code>Install-Terraform</code>: changed RunAsAdmin detection method from direct code to <code>Test-TerraformRunningAsAdmin</code> private function.
* <code>Install-Terraform</code>: changed online available Terraform version detection from direct code to new <code>Get-TerraformVersionAvailable</code> private function.
* <code>Test-TerraformRequirement</code>: added module's minimum Terraform version number validation; the minimum version has a default value matching the latest tested version (currently "1.12.0") but can be configured by passing a differnt value for the $MinTerraformVersion parameter.

#### 1.0.3

BUG FIX:  
* <code>UplinkSystems.Terraform.psm1</code>: resized module logo and removed window/buffer size configuration for better host compatibility and to fix terminating errors on import with Windows 11 in some cases.

#### 1.0.2

BUG FIX:  
* <code>Install-TerraformApplication</code>: changed method to add Terraform installation path to PATH environment variable as previous method was not persistent.

#### 1.0.1

BUG FIX:  
* <code>Invoke-TerraformApply</code>: fixed bug where <code>-lock=</code> string is redundant in <code>Start-Process</code>.

#### 1.0.0

NOTES:  
* Version 1.0.0 is the initial release of the UplinkSystems.Terraform PowerShell module.  

FEATURES:  
* New module function: <code>Install-TerraformApplication</code>
* New module function: <code>Invoke-TerraformApply</code>
* New module function: <code>Invoke-TerraformCustom</code>
* New module function: <code>Invoke-TerraformDestroy</code>
* New module function: <code>Invoke-TerraformGet</code>
* New module function: <code>Invoke-TerraformInit</code>
* New module function: <code>Invoke-TerraformPlan</code>
* New module function: <code>Invoke-TerraformValidate</code>
* New module function: <code>Invoke-TerraformWorkingDirectoryCleanup</code>
* New module function: <code>Set-TerraformEnvironmentVariable</code>
* New module function: <code>Test-TerraformRequirement</code>
* New module private function: <code>Test-TerraformRunningAsAdmin</code>
* New module private function: <code>Test-TerraformWorkingDirectory</code>