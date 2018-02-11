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
    $mailInfo = @{
            'to' = '';
            'from' = '';
            'cc' = '';
            'subject' = '';
            'body' = '';
            'SMTPServer' = '';
            'SMTPPort' = '';
            'credentials' = ''
    }
    $myLogger = New-Object PSCustomObject -Property @{'LogFile' = $Script:defaultLogFile;
                                                      'RotateSize' = $Script:defaultRotateSize;
                                                      'RotateDays' = $Script:defaultRotateDays;
                                                      'AutoRotate' = $Script:defaultAutoRotate;
                                                      'TimeStampFormat' = 'yyyy-MM-dd HH:mm:ss';
                                                      'Verbose' = $false;
                                                      'MailInfo' = $mailInfo;
                                                      'MakeCMTraceCompatible' = $false;
                                                      'SeverityLimit' = 'Verbose';
    }
    Add-Member -InputObject $myLogger -Name GetLogSize -Value {Get-LogSize $($this.LogFile)} -MemberType ScriptMethod
    Add-Member -InputObject $myLogger -Name Write -Value {param($msg, $severity = '');Write-LogLine -Msg $msg -File $($this.LogFile) -TimeStampFormat $($this.TimeStampFormat) -Verbose $($this.Verbose) -Severity $severity -UseCMTrace $($this.MakeCMTraceCompatible)} -MemberType ScriptMethod
    Add-Member -InputObject $myLogger -Name RemoveLog -Value {Remove-LogFile $($this.LogFile)} -MemberType ScriptMethod
    Add-Member -InputObject $myLogger -Name GetLogContent -Value {Get-LogContent $($this.LogFile)} -MemberType ScriptMethod
    Add-Member -InputObject $myLogger -Name EmailLogFile -Value {Send-LogFileViaEmail -MailInfo $mailInfo -File $($this.LogFile)} -MemberType ScriptMethod

    return $myLogger
}
Export-ModuleMember -Function Get-EBGLogger