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
        .PARAMETER LocaleSet [Array]
        The mandatory parameter -LocalSet represents a complete array set for a single sensitivity
        label locale setting. The parameter is used to to call the function from a pipeline.
        .PARAMETER Silent [Switch]
        The optional parameter -Silent suppresses all console messages. Error messages are not 
        affected by the parameter and are never suppressed.
        .OUTPUTS
        System.Boolean
        .COMPONENT
        ExchangeOnlineManagement
        .NOTES
        To connect to Security & Compliance use cmdlet 'Connect-IPPSSession' instead of
        'Connect-ExchangeOnline'.
        .EXAMPLE
        $Name = "P_01"
        $Languages = "en-us","de-de","es-es"
        $DisplayNames = "Public","Öffentlich,"Público"
        $Tooltips = "Public documents","Öffentliche Dokumente","Documentos públicos"
        Set-PurviewSensitivityLabelLocale -Name $Name -Languages $Languages -DisplayNames $DisplayNames -Tooltips $Tooltips
        .EXAMPLE
        $LocaleSets = @(
            @("P_01",@("en-us","de-de"),@("Public","Öffentlich"),@("Public documents","Öffentliche Dokumente")),
            @("I_01",@("en-us","de-de"),@("Internal","Intern"),@("Internal documents","Interne Dokumente"))
        )
        $LocaleSets | Set-PurviewSensitivityLabelLocale
        .EXAMPLE
        [Array]$LocaleSets = (
            ("P_01",("en-us","de-de"),("Public","Öffentlich"),("Public documents","Öffentliche Dokumente")),
            ("I_01",("en-us","de-de"),("Internal","Intern"),("Internal documents","Interne Dokumente"))
        )
        $LocaleSets | Set-PurviewSensitivityLabelLocale -Silent
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Set-SensitivityLabelLocale')]

    param(
        [Parameter(Mandatory=$true,ParameterSetName='default',Position=0)] [String] $Name,         
        [Parameter(Mandatory=$true,ParameterSetName='default')] [Array] $Languages,
        [Parameter(Mandatory=$true,ParameterSetName='default')] [Array] $DisplayNames,
        [Parameter(Mandatory=$true,ParameterSetName='default')] [Array] $Tooltips,
        [Parameter(Mandatory=$true,ParameterSetName='pipeline',Position=0,ValueFromPipeline=$true)] [Array] $LocaleSet,
        [Parameter(Mandatory=$false)] [Switch] $Silent
    )

    begin {
        # saving preferences and set custom preferences for the function's runtime
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        if ($Silent) {$InformationPreference = 'SilentlyContinue'} else {$InformationPreference = 'Continue'}
    }

    process {
        # split $LocaleSet values and configure variable names if pipeline input
        if ($PSCmdlet.ParameterSetName -eq 'pipeline') {
            [String]$Name = $LocaleSet[0]; [Array]$Languages = $LocaleSet[1]; [Array]$DisplayNames = $LocaleSet[2]; [Array]$Tooltips = $LocaleSet[3]
        }
        # verify matching array value counts
        if (-not(($DisplayNames.Count, $Tooltips.Count -eq $Languages.Count).Count -eq 2)) {return $false | Out-Null}
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
            return $false | Out-Null
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
        if (($LanguagesCount -eq $Languages.Count) -and ($DisplayNamesCount -eq $DisplayNames.Count) -and ($TooltipsCount -eq $Tooltips.Count)) {
            Write-Information -MessageData "INFO: label $Name successfully updated..."
            return $true | Out-Null
        }
        else {
            return $false | Out-Null
        }
    }

    end {
        $InformationPreference = $Preferences[1]
    }
    
}