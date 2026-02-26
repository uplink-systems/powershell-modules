function Add-EntraApplicationCredential {

    <#
        .SYNOPSIS
        The function adds a credential to an app registration.
        .DESCRIPTION
        The function adds a credential to an app registration. The credential can
        either be a secret or a certificate depending on the selected parameters.
        .PARAMETER ApplicationName [String]
        The mandatory parameter -ApplicationName specifies the name of the application
        to add either a secret or a certificate for.
        Alias: Application
        .PARAMETER SecretName [String]
        The optional parameter -SecretName specifies the display name of the secret 
        to create. If this parameter is specified it forces the function to add a
        secret credential.
        .PARAMETER CertificateName [String]
        The optional parameter -CertificateName specifies the subject of the
        certificate to add. If this parameter is specified it forces the function
        to add a certificate credential.
        .PARAMETER ValidMonths [Int32]
        The optional parameter -ValidMonths specifies the validity period of the
        secret or certificate in months. This parameter only affects if no certificate
        with a subject containing the certificate name can be found in current user's
        certificate store and a new self-signed certificate is created.
        Defaults to: 24
        .PARAMETER ReplaceExisting [Switch]
        The optional parameter -ReplaceExisting forces the function to remove existing
        credentials before adding new ones. The parameter affects secrets as well as
        certificates.
        Defauls to: $false
        .PARAMETER Silent [Switch]
        The optional paramter -Silent forces the function to suppress all informational
        output except error messages.
        .OUTPUTS
        System.String
        .COMPONENT
        Microsoft.Graph
        .NOTES
        A valid MgGraph PowerShell user session with valid scopes or a client id session
        with valid consents must be established for the function to work:
        - Application.ReadWrite.All
        - Directory.ReadWrite.All
        Secret credential:
        The function redirects the secret text (secret value) to the clipboard, too, if
        selected credential is a client secret.
        Certificate credential:
        The function tries to find the certificate with the provided name as subject in
        local machine's and current user's certificate stores and selects the first one
        if multiple are found. If no certificate can be found it creates a new self-signed
        certificate in the current user's certificate store.
        .EXAMPLE
        Add-EntraApplicationCredential -ApplicationName 'MyApp' -SecretName 'MyAppSecret' -ValidMonths 6 -ReplaceExisting
        .EXAMPLE
        Add-EntraApplicationCredential -ApplicationName 'MyApp' -CertificateName 'MyAppCertificate' -ValidMonths 12

    #>

    [CmdletBinding(PositionalBinding=$false,HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]
    [Alias('Add-AzureAdApplicationCredential')]

    param (
        [Parameter(Mandatory=$true,Position=0)] [Alias('Application')] [String] $ApplicationName,
        [Parameter(Mandatory=$true,ParameterSetName='Secret')] [String] $SecretName,
        [Parameter(Mandatory=$true,ParameterSetName='Certificate')] [String] $CertificateName,
        [Parameter(Mandatory=$false)] [ValidateSet(3,6,12,18,24)] [Int32] $ValidMonths = 24,
        [Parameter(Mandatory=$false)] [Switch] $ReplaceExisting,
        [Parameter(Mandatory=$false)] [Switch] $Silent
    )

    begin {
        if (-not(Get-MgContext)) {Write-Host -Object "Error: Not connected to MgGraph..." -ForegroundColor Red; return}
        [Array]$Preferences = $ErrorActionPreference,$InformationPreference
        $ErrorActionPreference = 'Stop'
        if ($Silent) {$InformationPreference = 'SilentlyContinue'} else {$InformationPreference = 'Continue'}
    }
 
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Secret' {
                try {
                    $MgApplication = Get-MgApplication -Filter "DisplayName eq '$ApplicationName'"
                    if ($ReplaceExisting) {
                        foreach ($PasswordCredential in (Get-MgApplication -ApplicationId $MgApplication.id).PasswordCredentials) {
                            Remove-MgApplicationPassword -ApplicationId $MgApplication.id -KeyId $PasswordCredential.KeyId
                        }
                    }
                    $PasswordCredential = @{
                        displayName = $SecretName;
                        startDateTime = (Get-Date).ToUniversalTime();
                        endDateTime = (Get-Date).ToUniversalTime().AddMonths(+$ValidMonths)
                    }
                    $Global:MgApplicationPassword = Add-MgApplicationPassword -ApplicationId $MgApplication.Id -PasswordCredential $PasswordCredential
                    $MgApplicationPassword.SecretText | Set-Clipboard
                    return $MgApplicationPassword
                }
                catch {return}
            }
            'Certificate' {
                try {
                    $MgApplication = Get-MgApplication -Filter "DisplayName eq '$ApplicationName'"
                    if (-not($Certificate = Get-ChildItem -Path 'Cert:\LocalMachine\My','Cert:\CurrentUser\My'| Where-Object {($_.Subject -eq "$CertificateName") -and ($_.NotBefore -le (Get-Date)) -and $_.NotAfter -gt (Get-Date)} | Select-Object -First 1)) {
                        $Certificate = New-SelfSignedCertificate -Subject $CertificateName -CertStoreLocation 'Cert:\CurrentUser\My' -NotBefore $((Get-Date).ToUniversalTime()) -NotAfter $((Get-Date).ToUniversalTime().AddMonths(+$ValidMonths)) -KeyExportPolicy 'ExportableEncrypted'
                    }
                    if ($ReplaceExisting) {
                        $KeyCredentials = @{
                            Type = 'AsymmetricX509Cert';
                            Usage = 'Verify';
                            Key = $Certificate.RawData 
                        }
                    }
                    else {
                        $KeyCredentials = $MgApplication.KeyCredentials
                        $KeyCredentials += @{
                            Type = 'AsymmetricX509Cert';
                            Usage = 'Verify';
                            Key = $Certificate.RawData 
                        }
                    }
                    Update-MgApplication -ApplicationId $MgApplication.Id -KeyCredentials $KeyCredentials | Out-Null
                    $Global:MgApplicationKeys = (Get-MgApplication -ApplicationId $MgApplication.Id).KeyCredentials
                    return $MgApplicationKeys
                }
                catch {return}
            }
            default {return}
        }
    }
    end {
        $ErrorActionPreference = $Preferences[0]
        $InformationPreference = $Preferences[1]
    }

}