## Module 'UplinkSystems.Microsoft.Cloud'

### Description

The module **UplinkSystems.Microsoft.Cloud** provides PowerShell functions for the following tasks:
* manage common tasks in Microsoft cloud tenants  
  
To achieve this goal the module contains the following public functions that can be used with its parameters:  
  
* <code>Confirm-EntraCustomDomain</code>
* <code>Confirm-EntraUserRoleAssignment</code>
* <code>Confirm-MgGraphScopeInContextScopes</code>
* <code>Disable-MsCommerceSelfServicePurchase</code>
* <code>Enable-MsCommerceSelfServicePurchase</code>
* <code>Get-EntraCustomDomainDnsRecordSet</code>
* <code>Get-EntraTenantId</code>
* <code>New-EntraCustomDomain</code>
* <code>Set-PurviewSensitivityLabelLocale</code>
  
For detailed information about each functions options and features please refer to each function's comment based help.  
  
Please note:  
The module is currently intended to run on Windows operating systems only.  

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_powershell"></a> [PowerShell](#requirement\_powershell) | >= 7.4.0 |

### Release Notes

#### 1.0.0

NOTES:  
* Version 1.0.0 is the initial release of the UplinkSystems.Microsoft.Cloud PowerShell module.  

FEATURES:  
* New module function: <code>Confirm-EntraCustomDomain</code>
* New module function: <code>Confirm-EntraUserRoleAssignment</code>
* New module function: <code>Confirm-MgGraphScopeInContextScopes</code>
* New module function: <code>Disable-MsCommerceSelfServicePurchase</code>
* New module function: <code>Enable-MsCommerceSelfServicePurchase</code>
* New module function: <code>Get-EntraCustomDomainDnsRecordSet</code>
* New module function: <code>Get-EntraTenantId</code>
* New module function: <code>New-EntraCustomDomain</code>
* New module function: <code>Set-PurviewSensitivityLabelLocale</code>

### Functions
  
The following chapters explain the modules' functions where needed...  

#### Confirm-MgGraphScopeInContextScopes
  
The function <code>Confirm-MgGraphScopeInContextScopes</code> validates if all specified Microsoft Graph scopes are member of the context scopes of the current session. The main purpose is to validate scopes that are required in other functions to work, but it can be used as a separate verification function, too.  
  
#### Confirm-UserEntraRoleAssignment
  
The function <code>Confirm-UserEntraRoleAssignment</code> validates if a Entra user is member of one ore several Entra roles (NOT Azure roles!).  
A set of roles can be specified and it is possible to validate the membership in one of the roles ('or'-condition) or all of the rules ('and'-condition). The user must be a direct member of the role; it is currently not possible to validate membership via group assignment.  
  
#### Get-EntraCustomDomainDnsRecordSet
  
The function <code>Get-EntraCustomDomainDnsRecordSet</code> queries the set of DNS records from a custom domain in Entra. It is selectable to output only the domain verification code TXT record, only the service records (MX/TXT/CNAME) or all (default).  
  
#### Set-PurviewSensitivityLabelLocale
  
The function <code>Set-PurviewSensitivityLabelLocale</code> can configure one or multiple locale-specific settings (multilanguage). This is currently not possible to configure using the Purview admin interface. The function configures the display names as well as the tooltips in multilanguage environments.  
  