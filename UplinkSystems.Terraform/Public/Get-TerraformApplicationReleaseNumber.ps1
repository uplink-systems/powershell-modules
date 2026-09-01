function Get-TerraformApplicationReleaseNumber {
	<#
		.SYNOPSIS
		Get version numbers of published/available Terraform releases
		.DESCRIPTION
		The function gets version numbers of published/available Terraform releases either from
        HashiCorp's release website or from GitHub repository. Either the latest stable release
        number or all release numbers are returned.
        .PARAMETER HashiCorp [Switch]
        The mandatory parameter -HashiCorp forces the function to use HashiCorp's release website
        as data source.
        .PARAMETER GitHub [Switch]
        The mandatory parameter -GitHub forces the function to use HashiCorp's GitHub repository.
        as data source.
        .PARAMETER All [Switch]
        The optional parameter -All specifies to return all version numbers instead of the latest
        stable.
        .OUTPUTS
        System.IO.String
        .EXAMPLE
        Get-TerraformApplicationReleaseNumber -HashiCorp
        .EXAMPLE
        Get-TerraformApplicationReleaseNumber -GitHub -All
        .EXAMPLE
        To process the result for version comparison use [Version] prefix (only working without -All
        switch because -All switch returns an array of values and also includes alpha/beta releases),
        e.g.:
        $AsVersion = [Version]$(Get-TerraformApplicationReleaseNumber -HashiCorp)
	#>
    [CmdletBinding(HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform')]
	[Alias('Get-TfApplicationReleaseNumber')]
    param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='HashiCorp')] [Switch] $HashiCorp,
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='GitHub')] [Switch] $GitHub,
        [Parameter(Mandatory=$false)] [Switch] $All
    )
    begin {
        [Array]$Preferences = $ErrorActionPreference,$WarningPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'HashiCorp' {
                try {
                    [System.Collections.ArrayList]$Releases = (Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/' -UseBasicParsing | Select-Object -ExpandProperty Content) -split "`n" | Select-String -Pattern '(?<=\/)([\d]+.[\d]+.[\d]+-[\w]+[\d]+|[\d]+.[\d]+.[\d]+)' | ForEach-Object {$_.Matches | ForEach-Object {$_.Groups[1].Value}}
                    switch ($All) {
                        $true { return $Releases }
                        default {
                            switch ($Releases[0] -match '-') {
                                $true { 
                                    $i = 0; do {$i += 1; $Release = $Releases[$i]} while ($Release -match '-')
                                }
                                default {$Release = $Releases[0]}
                            }
                            return $Release
                        }
                    }
                }
                catch {
                    return $null
                }
            }
            'GitHub' {
                try {
                    switch ($All) {
                        $true  { $RestMethodUri = 'https://api.github.com/repos/hashicorp/terraform/releases' }
                        default { $RestMethodUri = 'https://api.github.com/repos/hashicorp/terraform/releases/latest' }
                    }
                    $Releases = ((Invoke-RestMethod -Method GET -Uri $RestMethodUri -ErrorAction Stop).tag_name).SubString(1)
                    return $Releases
                }
                catch {
                    return $null
                }
            }
        }
    }
    end {
        $ErrorActionPreference = $Preferences[0]
    }
}