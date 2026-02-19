function Confirm-MgGraphScopeInContextScopes {

    <#
        .SYNOPSIS
        The function confirms if current MgGraph context scopes include specified scopes.
        .DESCRIPTION
        The function confirms if current MgGraph context scopes include one or more specified
        scopes. The function returns $true only if all specified scope are in current context
        scopes. In all other cases it returns $false.
        .PARAMETER Scopes [Array]
        The mandatory parameter -Scopes represents the scopes to confirm. Can be a single scope
        or multiple scopes.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        Microsoft.Graph
        .NOTES
        The function requires an established MgGraph connection to work.
        .EXAMPLE
        Confirm-MgGraphScopeInContextScope -Scopes "User.Read.All","Device.ReadWrite.All"
        .EXAMPLE
        Confirm-MgGraphScope -Scope "Directory.AccessAsUser.All"
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Confirm-MgGraphScope")]

    param(
        [Parameter(Mandatory=$true,Position=0)] [Alias("Scope")] [Array] $Scopes
    )

    begin {
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }

    process {
        try {
            $ContextScopes = Get-MgContext -ErrorAction Stop | Select-Object -ExpandProperty Scopes
            $ScopesInContextScopes = 0
            foreach ($Scope in $Scopes) {
                if ($ContextScopes -contains $Scope) {
                    $ScopesInContextScopes = $ScopesInContextScopes + 1
                }
            }
            if ($ScopesInContextScopes -eq $Scopes.Count) {return $true} else {return $false}
        }
        catch {return $false}
    }
    
    end {
        $ErrorActionPreference = $Preferences[0]
    }

}
