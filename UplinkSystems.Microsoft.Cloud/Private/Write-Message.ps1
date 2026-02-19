function Write-Message {

    <#
        .SYNOPSIS
        This private function handles custom messages in the module's public functions.
        .DESCRIPTION
        The function writes custom messages in user friendly format and colors to the cli and
        avoids the use of -especially- Write-Host commands. 
        In case of message type 'ErrorM' it adds the message as error to the $Error variable.
        It writes the message to StdErr when running in a regular console window and to the
        host's error stream otherwise.
        The message is treated as default output message if no type parameter is selected.
        .PARAMETER MessageData [PSObject]
        The optional parameter -MessageData contains the message content to write to cli.
        Alias: -Data
        .PARAMETER ErrorMessage [Switch]
        The optional parameter -ErrorMessage sets the message processing type 'Error'.
        Alias: -E
        .PARAMETER WarningMessage [Switch]
        The optional parameter -WarningMessage sets the message processing to type 'Warning'.
        Alias: -W
        .PARAMETER InformationMessage [Switch]
        The optional parameter -InformationMessage sets the message processing type 'Information'.
        Alias: -I
        .PARAMETER Silent [Switch]
        The optional parameter -Silent supresses the output of the message. Although it sounds
        senseless, it can be used in functions or scripts where the output of messages can be 
        enabled or disabled depending on the situation. Instead of splitting the function if 
        output is written or not, a single parameter is sufficient to control the output behavior
        script-wide.
        Note that messages of type 'Error' cannot be suppressed by this parameter and are always
        written.
        .NOTES
        $PSStyle is available from PowerShell 7.2. Lower versions are not supported. Running this
        function in lower versions will cause it to fail and terminate.
        .OUTPUTS
        System.String
        .EXAMPLE
        Write-Message -MessageData "Another day in paradise has begun."
        .EXAMPLE
        Write-Message "ERROR: Weather in paradise should be paradise-like but isn't." -ErrorMessage
        .EXAMPLE
        Write-Message -MessageData "INFO: Weather in paradise is paradise-like." -I
        .EXAMPLE
        Write-Message "WARNING: Weather in paradise may become paradise-unlike." -WarningMessage
    #>

    [CmdletBinding(PositionalBinding=$false,DefaultParameterSetName="Default",HelpUri="https://github.com/uplink-systems/powershell-modules/UplinkSystems.Microsoft.Cloud")]

    param (
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)] [Alias("Data")] [PSObject] $MessageData,
        [Parameter(Mandatory=$false,ParameterSetName="Error")] [Alias("E")] [Switch] $ErrorMessage,
        [Parameter(Mandatory=$false,ParameterSetName="Warning")] [Alias("W")] [Switch] $WarningMessage,
        [Parameter(Mandatory=$false,ParameterSetName="Information")] [Alias("I")] [Switch] $InformationMessage,
        [Parameter(Mandatory=$false)] [Switch] $Silent
    )

    switch ($PsCmdlet.ParameterSetName) {
        "Error" {
            if ($MessageData) {
                $WriteCommand = if ($Host.Name -eq 'ConsoleHost') {[Console]::Error.WriteLine} else {$Host.UI.WriteErrorLine}
                [void] $WriteCommand.Invoke(("$($PSStyle.Foreground.BrightRed)$MessageData$($PSStyle.Reset)").ToString())
                $Error.Add($MessageData) | Out-Null
            }
        }
        "Warning" {
            if (($MessageData) -and (-not($Silent))) {
                $WriteCommand = if ($Host.Name -eq 'ConsoleHost') {[Console]::Out.WriteLine} else {$Host.UI.WriteLine}
                [void] $WriteCommand.Invoke(("$($PSStyle.Foreground.BrightYellow)$MessageData$($PSStyle.Reset)").ToString())
            }
        }
        "Information" {
            if (($MessageData) -and (-not($Silent))) {
                $WriteCommand = if ($Host.Name -eq 'ConsoleHost') {[Console]::Out.WriteLine} else {$Host.UI.WriteLine}
                [void] $WriteCommand.Invoke(("$($PSStyle.Foreground.BrightBlue)$MessageData$($PSStyle.Reset)").ToString())
            }
        }
        default {
            if (($MessageData) -and (-not($Silent))) {
                $WriteCommand = if ($Host.Name -eq 'ConsoleHost') {[Console]::Out.WriteLine} else {$Host.UI.WriteLine}
                [void] $WriteCommand.Invoke(("$MessageData").ToString())
            }
        }
    }

}