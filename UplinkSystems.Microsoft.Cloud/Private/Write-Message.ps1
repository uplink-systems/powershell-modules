function Write-Message {

    <#
        .SYNOPSIS
        This private function handles custom messages in the module's public functions.
        .DESCRIPTION
        The function writes custom messages in user friendly format and colors to the cli.
        To avoid Write-Host commands and to avoid the inconsistent output of Write-Error and
        Write-Warning, the function always uses Write-Information for output. If required,
        it adds the messages to the $Error variable or to the warning stream silently.
        The message is treated as default output message (equivalent to Write-Host) if no
        type parameter (see parameter below) is selected.
        .PARAMETER Content [PSObject]
        The optional parameter -Content contains the message content (text) to write to cli.
        Alias: -Data, -Message
        .PARAMETER ErrorMessage [Switch]
        The optional parameter -ErrorMessage sets the message processing type 'Error'.
        Alias: -E, -Error
        .PARAMETER WarningMessage [Switch]
        The optional parameter -WarningMessage sets the message processing to type 'Warning'.
        Alias: -W, -Warning
        .PARAMETER InformationMessage [Switch]
        The optional parameter -InformationMessage sets the message processing type 'Information'.
        Alias: -I, -Information
        .PARAMETER Category [Switch]')
        The optional parameter -Category represents the -Category parameter in Write-Error
        commands (only if message is type 'Error').
        .PARAMETER ErrorId [Switch]
        The optional parameter -ErrorId represents the -ErrorId parameter in Write-Error
        commands (only if message is type 'Error').
        .PARAMETER TargetObject [Switch]
        The optional parameter -TargetObject represents the -TargetObject parameter in Write-
        Error commands (only if message is type 'Error').
        .PARAMETER Tags [Array]
        The optional parameter -Tags represents the -Tags parameter in Write-Information 
        commands (only if message is type 'Information').
        .PARAMETER Inquire [Switch]
        The optional parameter -Inquire enable inquiry mode for the output which means the cli
        prompts for confirmation to proceed. If -Inquire is selected, the value of -Silent is
        ignored and the message output to console is enfored.
        .PARAMETER Silent [Switch]
        The optional parameter -Silent supresses the output of the message. Although it sounds
        senseless, it can be used in functions or scripts where the output of messages can be 
        enabled or disabled depending on the situation. Instead of splitting the function if 
        output is written or not, a single parameter is sufficient to control the output
        behavior script-wide.
        Note that messages of type 'Error' cannot be suppressed by this parameter and are
        always written.
        .NOTES
        This function makes use of the $PSStyle variable which is available in PowerShell
        7.2 or higher. Lower versions are not supported. Install module 'PSStyle' in to
        implement the $PSStyle variable in lower verions, too. Otherwise running this
        function in lower versions will cause it to fail and terminate.
        .OUTPUTS
        System.String
        .EXAMPLE
        Write-Message -Content "Another day in paradise has begun."
        .EXAMPLE
        Write-Message "ERROR: Weather in paradise should be paradise-like but isn't." -ErrorMessage -Category InvalidResult
        .EXAMPLE
        Write-Message "WARNING: Weather in paradise becomes paradise-unlike. Really stay here?" -WarningMessage -Inquire
        .EXAMPLE
        Write-Message -Content "INFO: Weather in paradise is paradise-like." -I -Tags "Weather","Paradise"
    #>

    [CmdletBinding(PositionalBinding=$false,DefaultParameterSetName='default',HelpUri='https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud')]

    param (
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)] [Alias('Data','Message')] [PSObject] $Content,
        [Parameter(Mandatory=$false,ParameterSetName='Error')] [Alias('E','Error')] [Switch] $ErrorMessage,
        [Parameter(Mandatory=$false,ParameterSetName='Warning')] [Alias('W','Warning')] [Switch] $WarningMessage,
        [Parameter(Mandatory=$false,ParameterSetName='Information')] [Alias('I','Information')] [Switch] $InformationMessage,
        [Parameter(Mandatory=$false,ParameterSetName='Error')] [String] $Category = 'NotSpecified',
        [Parameter(Mandatory=$false,ParameterSetName='Error')] [String] $ErrorId = $null,
        [Parameter(Mandatory=$false,ParameterSetName='Error')] [String] $TargetObject = $null,
        [Parameter(Mandatory=$false,ParameterSetName='Information')][Array] $Tags = $null,
        [Parameter(Mandatory=$false)] [Switch] $Inquire,
        [Parameter(Mandatory=$false)] [Switch] $Silent
    )

    begin {
        # return if $PSStyle variable is unavailable
        if (-not($PSStype)) {return $null}
    }
    
    process {
        # output message depending on selected type
        switch ($PsCmdlet.ParameterSetName) {
            'Error' {
                if (($Content) -and ($Inquire)) {
                    # write message and parameter to error stream but suppress output
                    Write-Error -Message $Content -Category $Category -ErrorId $ErrorErrorId -TargetObject $TargetObject -ErrorAction SilentlyContinue
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightRed)$Content$($PSStyle.Reset)") -InformationAction Inquire
                }
                elseif ($Content) {
                    # write message and parameter to error stream but suppress output
                    Write-Error -Message $Content -Category $Category -ErrorId $ErrorErrorId -TargetObject $TargetObject -ErrorAction SilentlyContinue
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightRed)$Content$($PSStyle.Reset)") -InformationAction Continue
                }
            }
            'Warning' {
                if (($Content) -and ($Inquire)) {
                    # write message to warning stream but suppress output
                    Write-Warning -Message $Content -WarningAction SilentlyContinue
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightYellow)$Content$($PSStyle.Reset)") -WarningAction Inquire
                }
                elseif (($Content) -and ($Silent)) {
                    # write message to warning stream but suppress output
                    Write-Warning -Message $Content -WarningAction SilentlyContinue
                    # write message to information stream but suppress output
                    Write-Information -MessageData $Content -WarningAction SilentlyContinue

                }
                elseif (($Content) -and (-not($Silent))) {
                    # write message to warning stream but suppress output
                    Write-Warning -Message $Content$ -WarningAction SilentlyContinue
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightYellow)$Content$($PSStyle.Reset)") -WarningAction Continue
                }
            }
            'Information' {
                if (($Content) -and ($Inquire)) {
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightBlue)$Content$($PSStyle.Reset)") -Tags $Tags -InformationAction Inquire
                }
                elseif (($Content) -and ($Silent)) {
                    # write message to information stream but suppress output
                    Write-Information -MessageData $Content -Tags $Tags -InformationAction SilentlyContinue
                }
                elseif (($Content) -and (-not($Silent))) {
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightBlue)$Content$($PSStyle.Reset)") -Tags $Tags -InformationAction Continue
                }
            }
            default {
                if (($Content) -and ($Inquire)) {
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightBlack)$Content$($PSStyle.Reset)") -InformationAction Inquire
                }
                elseif (($Content) -and ($Silent)) {
                    # write message to information stream but suppress output
                    Write-Information -MessageData $Content -InformationAction SilentlyContinue
                }
                elseif (($Content) -and (-not($Silent))) {
                    # write formatted message to information stream and output
                    Write-Information -MessageData ("$($PSStyle.Foreground.BrightBlack)$Content$($PSStyle.Reset)") -InformationAction Continue
                }
            }
        }
    }

}