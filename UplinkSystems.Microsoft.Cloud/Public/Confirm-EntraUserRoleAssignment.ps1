function Confirm-EntraUserRoleAssignment {
    
    <#
        .SYNOPSIS
        The function confirms if a user has one/more M365 roles directly assigned.
        .DESCRIPTION
        The function confirms if a specified or the currently logged in user is direct member of 
        one or one of several M365 roles ("OR" conjunction). Group assignment is not supported.
        .PARAMETER UserPrincipalName [String]
        The optional parameter -UserPrincipalName represents the user name (UPN) to confirm if
        role is assigned. The function uses the currently logged on user by default.
        .PARAMETER TargetDirectoryRoles [Array]
        The mandatory paramter -TargetDirectoryRoles specifies one or more directory roles to
        confirm if the user has it/them assigned.
        .PARAMETER All [Switch]
        The test uses an "OR" conjuntion by default (any role assigned). Applying the -All
        parameter forces the function to use an "AND" conjunction (all roles assigned)
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Graph
        .NOTES
        The function requires an authenticated MgGraph session with at least "User.Read.All" and
        "RoleManagement.Read.Directory" scope.
        The function validates required scopes and initiates a new MgGraph connection if current
        scopes are insufficient.
        Only direct user assignments can be validated. Group-nested assignment is currently not in
        scope of the function.
        .EXAMPLE
        Confirm-EntraUserRoleAssignment -User "john.doe@company.com" -TargetDirectoryRoles "Global Administrator"
        .EXAMPLE
        Confirm-UserRoleAssignment -TargetDirectoryRoles "Exchange Administrator","Intune Administrator" -All
        .EXAMPLE
        (Get-MgContext).Account | Confirm-UserRoleAssignment -TargetDirectoryRoles "Global Administrator"
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Confirm-UserRoleAssignment")]

    param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)] [Alias("UPN")] [String] $UserPrincipalName = (Get-MgContext).Account,         
        [Parameter(Mandatory=$true)] [Alias("TargetRoles","Roles")] [Array] $TargetDirectoryRoles,
        [Parameter(Mandatory=$false)] [Switch] $All
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
         $MgGraphScopes = "User.Read.All","RoleManagement.Read.Directory"
        if (-not(Confirm-MgGraphScopeInContextScopes -Scopes $MgGraphScopes)) {Connect-MgGraph -Scopes $MgGraphScopes -NoWelcome}
    }

    process {
        $User = (Get-MgUser -UserId $UserPrincipalName)
        $DirectoryRoles = Get-MgDirectoryRole | Where-Object {$_.DisplayName -in $TargetDirectoryRoles}
        $HasDirectoryRoleAssigned = 0
        switch ($All) {
            $true {
                foreach ($DirectoryRole in $DirectoryRoles) {
                    $DirectoryRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $DirectoryRole.Id
                    foreach ($DirectoryRoleMember in $DirectoryRoleMembers) {
                        if (($DirectoryRoleMember.Id -eq $User.Id) -and ($TargetDirectoryRoles -contains $DirectoryRole.DisplayName)) {
                            $HasDirectoryRoleAssigned = $HasDirectoryRoleAssigned + 1
                            break
                        }
                    }
                }
                if ($HasDirectoryRoleAssigned -eq $TargetDirectoryRoles.Count) { return $true } else { return $false }        
            }
            default {
                foreach ($DirectoryRole in $DirectoryRoles) {
                    $DirectoryRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $DirectoryRole.Id
                    foreach ($DirectoryRoleMember in $DirectoryRoleMembers) {
                        if (($DirectoryRoleMember.Id -eq $User.Id) -and ($TargetDirectoryRoles -contains $DirectoryRole.DisplayName)) {
                            $HasDirectoryRoleAssigned = 1
                            break
                        }
                    }
                    if ($HasDirectoryRoleAssigned -eq 1) { break }
                }
                if ($HasDirectoryRoleAssigned -eq 1) { return $true } else { return $false }
            }
        }
    }
    
    end {
        $ErrorActionPreference = $Preferences[0]
    }

}