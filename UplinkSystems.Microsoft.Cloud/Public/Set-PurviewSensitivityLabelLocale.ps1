function Set-PurviewSensitivityLabelLocale {

    <#
        .SYNOPSIS
        The function configures multilanguage Display Names and Tooltips of a sensitivity label.
        .DESCRIPTION
        The function configures multilanguage Display Names and Tooltips of a sensitivity label.
        For details see repository folder's README.md
        .PARAMETER Name [String]
        The mandatory parameter -Name represents the unique sensitivity label name.
        .PARAMETER Languages [Array]
        The mandatory parameter -Languages represents the languages to process. Languages must be
        provided as 2-2 language/country code (e.g. en-us) 
        .PARAMETER DisplayNames [Array]
        The mandator parameter -DisplayNamnes represents the display names of the sensitivity label
        for each configured language.
        .PARAMETER Tooltips [Array]
        The manatory parameter -Tooltips represents the tooltipss of the sensitivity label for each
        configured language.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        ExchangeOnlineManagement
        .NOTES
        To connect to Security & Compliance use cmdlet 'Connect-IPPSSession' instead of
        'Connect-ExchangeOnline'.
        .EXAMPLE
        $Name = "P_01"
        $Languages = "en-us","de-de"
        $DisplayNames = "Public","Öffentlich"
        $Tooltips = "Public documents","Öffentliche Dokumente"
        Set-PurviewSensitivityLabelLocale -Name $Name -Languages $Languages -DisplayNames $DisplayNames -Tooltips $Tooltips
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]
    [Alias("Set-SensitivityLabelLocale")]

    param(
        [Parameter(Mandatory=$true,Position=0)] [String] $Name,         
        [Parameter(Mandatory=$true)] [Array] $Languages,
        [Parameter(Mandatory=$true)] [Array] $DisplayNames,
        [Parameter(Mandatory=$true)] [Array] $Tooltips
    )

    begin {
        # saving preferences and set custom preferences for the function's runtime
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }

    process {
        # verify matching array value counts
        if (-not(($DisplayNames.Count, $Tooltips.Count -eq $Languages.Count).Count -eq 2)) {return $false}
        # build 'displayName' value from $Languages and $DisplayNames array
        $DisplayNameLocaleSettings = [PSCustomObject]@{LocaleKey='displayName';
        Settings=@(
            for ( $Index = 0; $Index -lt $Languages.Count; $Index = $Index + 1)
                {
                    @{key=$Languages[$Index];Value=$DisplayNames[$Index];}
                }
            )
        }
        # build 'tooltip' value from $Languages and $Tooltips array
        $TooltipLocaleSettings = [PSCustomObject]@{LocaleKey='tooltip';
        Settings=@(
            for ( $Index = 0; $Index -lt $Languages.Count; $Index = $Index + 1)
                {
                    @{key=$Languages[$Index];Value=$Tooltips[$Index];}
                }
            )
        }
        # update label's locale settings with new values for 'displayName' and 'tooltip'
        try {
            Set-Label -Identity $Name -LocaleSettings (ConvertTo-Json $DisplayNameLocaleSettings -Depth 2 -Compress),(ConvertTo-Json $TooltipLocaleSettings -Depth 2 -Compress) -ErrorAction Stop | Out-Null
        }
        catch {
            return $false
        }
        # verify that label's locale settings contain all new values for 'displayName' and 'tooltip'
        $LabelLocaleSettings = (Get-Label -Identity $Name).LocaleSettings
        $LanguagesCount = 0
        foreach ($Language in $Languages) {if ($LabelLocaleSettings -like "*$($Language)*") {$LanguagesCount = $LanguagesCount + 1}}
        $DisplayNamesCount = 0
        foreach ($DisplayName in $DisplayNames) {if ($LabelLocaleSettings -like "*$($DisplayName)*") {$DisplayNamesCount = $DisplayNamesCount + 1}}
        $TooltipsCount = 0
        foreach ($Tooltip in $Tooltips) {if ($LabelLocaleSettings -like "*$($Tooltip)*") {$TooltipsCount = $TooltipsCount + 1}}
        # return depending on verification result (true/false)
        if (($LanguagesCount -eq $Languages.Count) -and ($DisplayNamesCount -eq $DisplayNames.Count) -and ($TooltipsCount -eq $Tooltips.Count)) {return $true} else {return $false}
    }

    end {
        $ErrorActionPreference = $Preferences[0]
    }
    
}