$here = (Get-Item $MyInvocation.MyCommand.path)
#Load Private Functions
$scriptPath = '{0}\private\EBGLogging_PrivateFunctions.ps1' -f $here.DirectoryName
. $scriptPath
#Load Public Functions - There currently aren't any public functions
$scriptPath = '{0}\Public\public.ps1' -f $here.DirectoryName
. $scriptPath
# Default values for a new logger object
$Script:defaultLogFile = ''
$Script:defaultRotateSize = 1
$Script:defaultRotateDays = 7
$Script:defaultAutoRotate = $false
function Get-EBGLogger{
    [CmdletBinding()]
    param
    (
    )
    $myLogger = New-Object PSCustomObject -Property @{'LogFile' = $Script:defaultLogFile;
                                                      'RotateSize' = $Script:defaultRotateSize;
                                                      'RotateDays' = $Script:defaultRotateDays;
                                                      'AutoRotate' = $Script:defaultAutoRotate;
    }
    Add-Member -InputObject $myLogger -Name GetLogSize -Value {'method: {0}' -f $this.LogFile;Get-LogSize $($this.LogFile)} -MemberType ScriptMethod
    return $myLogger
}
Export-ModuleMember -Function Get-EBGLogger
Export-ModuleMember -Function SomePublicFunction