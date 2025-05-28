## Module 'UplinkSystems.Terraform'

### Description

The module **UplinkSystems.Terraform** provides PowerShell functions to manage Terraform projects from PowerShell scripts where no DevOps pipelining is available for automation. To achieve this goal the module contains the following public functions that can be used with its parameters to automate Terraform project commands:  
  
* <code>Install-TerraformApplication</code>
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
  
For detailed information about each functions options please refer to each function's comment based help.  
  
Please note:  
The module is currently intended to run on Windows operating systems only.  

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_powershell"></a> [PowerShell](#requirement\_powershell) | >= 7.0.0 |

### Release Notes

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