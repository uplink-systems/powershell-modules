function Get-EntraCustomDomainDnsRecordSet {

    <#
        .SYNOPSIS
        The function queries an Entra custom domain for its DNS records.
        .DESCRIPTION
        The function queries an Entra custom domain for its verification DNS record set
        and / or its service DNS record sets.
        The function does query/support the following record sets:
        - Domain verification
        - Email service configuration
        - Intune service configuration
        - OrgIdAuthentication service configuration
        - SharePointDefaultDomain service configuration
        The function does NOT query/support the following record sets:
        - EmailInternalRelay service configuration
        - OfficeCommunicationOnline service configuration (deprecated)
        - SharePointPublic service configuration (retired)
        - Yammer service configuration (retired)
        .PARAMETER Domain [String]
        The mandator parameter -Domain represents the FQDN of the domain to query
        .PARAMETER VerificationDnsRecordOnly [Switch]
        The optional parameter -VerificationDnsRecordOnly limits the query to the domain verification
        TXT record set only (Get-MgDomainVerificationDnsRecord) and skips the service record sets.
        If both switches, $VerificationDnsRecordOnly and $ServiceConfigurationOnly, are set to $true,
        the function returns $null values.
        Alias: VerificationDns
        .PARAMETER ServiceConfigurationRecordsOnly [Switch]
        The optional parameter -ServiceConfigurationRecordsOnly limits the query to the domain service
        record sets (Get-MgDomainServiceConfigurationRecord) and skips the domain verification TXT
        record set. If both switches, $VerificationDnsRecordOnly and $ServiceConfigurationOnly, are
        set to $true, the function returns $null values.
        Alias: ServiceConfig
        .OUTPUTS
        System.Array
        .COMPONENT
        Microsoft.Graph
        .NOTES
        A valid MgGraph PowerShell user session with valid scopes or a client id session
        with valid consents must be established for the function to work:
        - Domain.ReadWrite.All
        .EXAMPLE
        Get-EntraCustomDomainDnsRecordSet -Domain "company.org"
        .EXAMPLE
        Get-CustomDomainDnsRecordSet "company.org" -ServiceConfigurationRecordsOnly
        .EXAMPLE
        Get-EntraCustomDomainDnsRecordSet "company.org" -VerificationDnsRecordOnly
        .EXAMPLE
        (Get-MgDomain | Where-object {$_.IsVerified -ne $true}).id | Get-EntraCustomDomainDnsRecordSet -VerificationDnsRecordOnly
    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Get-CustomDomainDnsRecordSet')]

    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)] [String] $Domain,
        [Parameter(Mandatory=$false)] [Alias('VerificationDns')] [Switch] $VerificationDnsRecordOnly,
        [Parameter(Mandatory=$false)] [Alias('ServiceConfig')] [Switch] $ServiceConfigurationRecordsOnly
    )

    begin {
        if (-not(Get-MgContext)) {Write-Host -Object "Error: Not connected to MgGraph..." -ForegroundColor Red; return}
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'SilentlyContinue'
    }
    process {
        $DomainVerificationDnsRecords = Get-MgDomainVerificationDnsRecord -DomainId $Domain
        $DomainServiceConfigurationRecords = Get-MgDomainServiceConfigurationRecord -DomainId $Domain
        if ($VerificationDnsRecordOnly -and $ServiceConfigurationRecordsOnly) {
            $DomainDnsRecords = @(
                @{Description=$null;Type=$null;Name=$null;Value=$null}) `
                | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru
            }
        }
        elseif ($VerificationDnsRecordOnly) {
            $DomainDnsRecords = @(
                @{Description="DomainVerificationTxt";Type="Txt";Name="$Domain";Value="$(($DomainVerificationDnsRecords | Where-Object {$_.RecordType -eq "Txt"}).AdditionalProperties.text)"}) `
                | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru
            }
        }
        elseif ($ServiceConfigurationRecordsOnly) {
            $DomainDnsRecords = @(
                @{Description="EmailServiceMx";Type="Mx";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "Mx") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.mailExchange)"},
                @{Description="EmailServiceTxt";Type="Txt";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "Txt") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.text)"},
                @{Description="EmailServiceCNameAutodiscover";Type="CName";Name="autodiscover.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "autodiscover.*") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.canonicalName)"},
                @{Description="EmailServiceCNameDkimSelector1";Type="CName";Name="selector1._domainkey.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "selector1._domainkey.*") }).AdditionalProperties.canonicalName)"},
                @{Description="EmailServiceCNameDkimSelector2";Type="CName";Name="selector2._domainkey.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "selector2._domainkey.*") }).AdditionalProperties.canonicalName)"},
                @{Description="IntuneServiceCNameEnrollment";Type="CName";Name="enterpriseenrollment.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "enterpriseenrollment.*") -and ($_.SupportedService -eq "Intune")}).AdditionalProperties.canonicalName)"},
                @{Description="IntuneServiceCNameRegistration";Type="CName";Name="enterpriseregistration.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "enterpriseregistration.*") -and ($_.SupportedService -eq "Intune")}).AdditionalProperties.canonicalName)"},
                @{Description="OrgIdAuthenticationServiceCName";Type="CName";Name="msoid.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "msoid.*") -and ($_.SupportedService -eq "OrgIdAuthentication")}).AdditionalProperties.canonicalName)"},
                @{Description="SharepointDefaultDomainServiceCName";Type="CName";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "SharepointDefaultDomain")}).AdditionalProperties.canonicalName)"}) `
                | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru
            }
        }
        else {
            $DomainDnsRecords = @(
                @{Description="DomainVerificationTxt";Type="Txt";Name="$Domain";Value="$(($DomainVerificationDnsRecords | Where-Object {$_.RecordType -eq "Txt"}).AdditionalProperties.text)"},
                @{Description="EmailServiceMx";Type="Mx";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "Mx") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.mailExchange)"},
                @{Description="EmailServiceTxt";Type="Txt";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "Txt") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.text)"},
                @{Description="EmailServiceCNameAutodiscover";Type="CName";Name="autodiscover.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "autodiscover.*") -and ($_.SupportedService -eq "Email")}).AdditionalProperties.canonicalName)"},
                @{Description="EmailServiceCNameDkimSelector1";Type="CName";Name="selector1._domainkey.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "selector1._domainkey.*") }).AdditionalProperties.canonicalName)"},
                @{Description="EmailServiceCNameDkimSelector2";Type="CName";Name="selector2._domainkey.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "selector2._domainkey.*") }).AdditionalProperties.canonicalName)"},
                @{Description="IntuneServiceCNameEnrollment";Type="CName";Name="enterpriseenrollment.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "enterpriseenrollment.*") -and ($_.SupportedService -eq "Intune")}).AdditionalProperties.canonicalName)"},
                @{Description="IntuneServiceCNameRegistration";Type="CName";Name="enterpriseregistration.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "enterpriseregistration.*") -and ($_.SupportedService -eq "Intune")}).AdditionalProperties.canonicalName)"},
                @{Description="OrgIdAuthenticationServiceCName";Type="CName";Name="msoid.$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -like "msoid.*") -and ($_.SupportedService -eq "OrgIdAuthentication")}).AdditionalProperties.canonicalName)"},
                @{Description="SharepointDefaultDomainServiceCName";Type="CName";Name="$Domain";Value="$(($DomainServiceConfigurationRecords | Where-Object {($_.RecordType -eq "CName") -and ($_.Label -eq "$Domain") -and ($_.SupportedService -eq "SharepointDefaultDomain")}).AdditionalProperties.canonicalName)"}) `
                | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru
            }
        }
        Write-Output -InputObject $DomainDnsRecords
    }

    end {
        $ErrorActionPreference = $Preferences[0]
        return
    }
    
}