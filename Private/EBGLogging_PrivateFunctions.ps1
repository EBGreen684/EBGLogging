function Get-Logsize{
    param(
        $logFile
    )
    # I might want to change this to a custom error but for now just pass the error down the stack and doctor it with my info
    try{
        $file = ls $logFile -ea Stop
        [double]$length = '{0:0.00}' -f ($file.Length/1MB)
        return $length
    }
    catch{
        $e = $_.Exception
        $e = Get-EBGLoggingErrorInfo $e
        throw $e
    }
}
function Get-EBGLoggingErrorInfo{
    param(
        $e
    )
    $e.Source = 'EBGLogging Module'
    $e.HelpLink = 'https://github.com/EBGreen684/EBGLogging'
    #$E = [System.Exception]@{Source="Get-ParameterNames.ps1";HelpLink="http://go.microsoft.com/fwlink/?LinkID=113425";}
    return $e
}
function Write-LogLine{
    param(
        $msg,
        $file,
        $timeStampFormat,
        $verbose,
        $severity = '',
        $useCMTrace
    )
    if(!$useCMTrace){
        $msg = '[{0}] - {1}' -f (Get-Date).ToString($timeStampFormat), $msg
        Add-Content -Path $file -Value $msg
        if($verbose){
            Write-Host $msg
        }
        return
    }
    Write-Host (Get-CMTraceLine -msg $msg -severity $severity)
    Add-Content -Path $file -Value (Get-CMTraceLine -msg $msg -severity $severity)

}
function Remove-LogFile{
    param(
        $file
    )
    if(Test-Path $file){
        Remove-Item -Path $file -Force
    }
}
function Get-LogContent{
    param(
        $file
    )
    if(Test-Path $file){
        Get-Content $file
    }else{
        Write-Host ('NO LOGFILE FOUND ({0})' -f $file) -ForegroundColor DarkRed
        return $false
    }
}
Function Send-LogFileViaEmail{
    param(
        $mailInfo,
        $file
    )
    $to = $mailInfo.To
    $from = $mailInfo.From
    #$cc = $mailInfo.CC
    $attachment = $file
    $subject = $mailInfo.Subject
    $body = $mailInfo.Body
    $SMTPServer = $mailInfo.SMTPServer
    $SMTPPort = $mailInfo.SMTPPort
    $credentials = $mailInfo.Credentials
    if ($credentials -eq '') {
        #Send-MailMessage -To $to -From $from -CC $cc -Attachments $attachment -Subject $subject -Body $body -SmtpServer $SMTPServer -Port $SMTPPort
        Send-MailMessage -To $to -From $from -Attachments $attachment -Subject $subject -Body $body -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl
    }else{
        #Send-MailMessage -To $to -From $from -CC $cc -Attachments $attachment -Subject $subject -Body $body -SmtpServer $SMTPServer -Port $SMTPPort -Credential $credentials
        Send-MailMessage -To $to -From $from -Attachments $attachment -Subject $subject -Body $body -SmtpServer $SMTPServer -Port $SMTPPort -Credential $credentials -UseSsl
    }

}
function Get-CMTraceLine{
    param(
        $msg,
        $severity
    )
    $scriptInfo = (Get-PSCallStack)[1]
    $scriptFile = $scriptInfo.Location
    $component = (Get-Process -ID $pid).ProcessName
    $utcOffset = [int]((Get-Date) - (Get-Date).ToUniversalTime()).TotalMinutes
    $d = Get-Date
    $time = $d.ToString('HH:mm:ss.fff')
    $date = $d.ToString('M-d-yyyy')
    $context = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    switch($severity){
        'Warning'     {$severityLevel = 2}
        'Error'       {$severityLevel = 3}
        'Verbose'     {$severityLevel = 4}
        'Debug'       {$severityLevel = 5}
        'Information' {$severityLevel = 6}
    }
    $infoArray = @(($severity.ToUpper()), $msg, $time, $utcOffset, $date, $component, $context, $severityLevel, $pid, $scriptFile)
    $logLine = '<![LOG[{0}: {1}]LOG]!><time="{2}{3}" date="{4}" component="{5}" context="{6}" type="{7}" thread="{8}" file="{9}">' -f $infoArray
    return $logLine
}

Function Write-CMTraceLog{
    #Define and validate parameters 
    [CmdletBinding()] 
    Param( 

        #Path to the log file 
        [parameter(Mandatory=$true)]      
        [String]$file,
         
        #The information to log 
        [parameter(Mandatory=$True)] 
        $Message,
 
        #The severity (Error, Warning, Verbose, Debug, Information)
        [parameter(Mandatory=$True)]
        [ValidateSet('Warning','Error','Verbose','Debug', 'Information')] 
        [String]$Type,

        #Write back to the console or just to the log file. By default it will write back to the host.
        [parameter(Mandatory=$False)]
        [switch]$WriteBackToHost = $True

    )#Param

    #Get the info about the calling script, function etc
    $callinginfo = (Get-PSCallStack)[1]

    #Set Source Information
    $Source = (Get-PSCallStack)[1].Location

    #Set Component Information
    $Component = (Get-Process -Id $PID).ProcessName

    #Set PID Information
    $ProcessID = $PID

    #Obtain UTC offset 
    $DateTime = New-Object -ComObject WbemScripting.SWbemDateTime  
    $DateTime.SetVarDate($(Get-Date)) 
    $UtcValue = $DateTime.Value 
    $UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)

    #Set the order 
    switch($Type){
           'Warning' {$Severity = 2}#Warning
             'Error' {$Severity = 3}#Error
           'Verbose' {$Severity = 4}#Verbose
             'Debug' {$Severity = 5}#Debug
       'Information' {$Severity = 6}#Information
    }#Switch

    #Switch statement to write out to the log and/or back to the host.
    switch ($severity){
        2{
            #Warning
            
            #Write the log entry in the CMTrace Format.
             $logline = `
            "<![LOG[$($($Type.ToUpper()) + ": " +  $message)]LOG]!>" +`
            "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
            "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Severity`" " +`
            "thread=`"$ProcessID`" " +`
            "file=`"$Source`">";
            $logline | Out-File -Append -Encoding utf8 -FilePath $file;
            
            #Write back to the host if $Writebacktohost is true.
            if(($WriteBackToHost) -and ($Type -eq 'Warning')){
                Switch($PSCmdlet.GetVariableValue('WarningPreference')){
                    'Continue' {$WarningPreference = 'Continue';Write-Warning -Message "$Message";$WarningPreference=''}
                    'Stop' {$WarningPreference = 'Stop';Write-Warning -Message "$Message";$WarningPreference=''}
                    'Inquire' {$WarningPreference ='Inquire';Write-Warning -Message "$Message";$WarningPreference=''}
                    'SilentlyContinue' {}
                }
            }
        }#Warning
        3{  
            #Error

            #This if statement is to catch the two different types of errors that may come through. A normal terminating exception will have all the information that is needed, if it's a user generated error by using Write-Error,
            #then the else statment will setup all the information we would like to log.   
            if($Message.exception.Message){                
                if(($WriteBackToHost)-and($Type -eq 'Error')){                                        
                    #Write the log entry in the CMTrace Format.
                    $logline = `
                    "<![LOG[$($($Type.ToUpper()) + ": " +  "$([String]$Message.exception.message)`r`r" + `
                    "`nCommand: $($Message.InvocationInfo.MyCommand)" + `
                    "`nScriptName: $($Message.InvocationInfo.Scriptname)" + `
                    "`nLine Number: $($Message.InvocationInfo.ScriptLineNumber)" + `
                    "`nColumn Number: $($Message.InvocationInfo.OffsetInLine)" + `
                    "`nLine: $($Message.InvocationInfo.Line)")]LOG]!>" +`
                    "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                    "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                    "component=`"$Component`" " +`
                    "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                    "type=`"$Severity`" " +`
                    "thread=`"$ProcessID`" " +`
                    "file=`"$Source`">"
                    $logline | Out-File -Append -Encoding utf8 -FilePath $file;
                    #Write back to Host
                    Switch($PSCmdlet.GetVariableValue('ErrorActionPreference')){
                        'Stop'{$ErrorActionPreference = 'Stop';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Stop';$ErrorActionPreference=''}
                        'Inquire'{$ErrorActionPreference = 'Inquire';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Inquire';$ErrorActionPreference=''}
                        'Continue'{$ErrorActionPreference = 'Continue';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");$ErrorActionPreference=''}
                        'Suspend'{$ErrorActionPreference = 'Suspend';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Suspend';$ErrorActionPreference=''}
                        'SilentlyContinue'{}
                    }

                }
                else{                   
                    #Write the log entry in the CMTrace Format.
                    $logline = `
                    "<![LOG[$($($Type.ToUpper()) + ": " +  "$([String]$Message.exception.message)`r`r" + `
                    "`nCommand: $($Message.InvocationInfo.MyCommand)" + `
                    "`nScriptName: $($Message.InvocationInfo.Scriptname)" + `
                    "`nLine Number: $($Message.InvocationInfo.ScriptLineNumber)" + `
                    "`nColumn Number: $($Message.InvocationInfo.OffsetInLine)" + `
                    "`nLine: $($Message.InvocationInfo.Line)")]LOG]!>" +`
                    "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                    "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                    "component=`"$Component`" " +`
                    "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                    "type=`"$Severity`" " +`
                    "thread=`"$ProcessID`" " +`
                    "file=`"$Source`">"
                    $logline | Out-File -Append -Encoding utf8 -FilePath $file;
                }
            }
            else{
                if(($WriteBackToHost)-and($type -eq 'Error')){
                    [System.Exception]$Exception = $Message
                    [String]$ErrorID = 'Custom Error'
                    [System.Management.Automation.ErrorCategory]$ErrorCategory = [Management.Automation.ErrorCategory]::WriteError
                    #[System.Object]$Message
                    $ErrorRecord = New-Object Management.automation.errorrecord ($Exception,$ErrorID,$ErrorCategory,$Message)
                    $Message = $ErrorRecord
                    #Write the log entry
                    $logline = `
                        "<![LOG[$($($Type.ToUpper()) + ": " +  "$([String]$Message.exception.message)`r`r" + `
                        "`nFunction: $($Callinginfo.FunctionName)" + `
                        "`nScriptName: $($Callinginfo.Scriptname)" + `
                        "`nLine Number: $($Callinginfo.ScriptLineNumber)" + `
                        "`nColumn Number: $($callinginfo.Position.StartColumnNumber)" + `
                        "`nLine: $($Callinginfo.Position.StartScriptPosition.Line)")]LOG]!>" +`
                        "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                        "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                        "component=`"$Component`" " +`
                        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                        "type=`"$Severity`" " +`
                        "thread=`"$ProcessID`" " +`
                        "file=`"$Source`">"
                        $logline | Out-File -Append -Encoding utf8 -FilePath $file;
                    #Write back to Host.
                    Switch($PSCmdlet.GetVariableValue('ErrorActionPreference')){
                            'Stop'{$ErrorActionPreference = 'Stop';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Stop';$ErrorActionPreference=''}
                            'Inquire'{$ErrorActionPreference = 'Inquire';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Inquire';$ErrorActionPreference=''}
                            'Continue'{$ErrorActionPreference = 'Continue';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message 2>&1 > $null;$ErrorActionPreference=''}
                            'Suspend'{$ErrorActionPreference = 'Suspend';$Host.Ui.WriteErrorLine("ERROR: $([String]$Message.Exception.Message)");Write-Error $Message -ErrorAction 'Suspend';$ErrorActionPreference=''}
                            'SilentlyContinue'{}
                        }
                }
                else{
                    #Write the Log Entry
                    [System.Exception]$Exception = $Message
                    [String]$ErrorID = 'Custom Error'
                    [System.Management.Automation.ErrorCategory]$ErrorCategory = [Management.Automation.ErrorCategory]::WriteError
                    #[System.Object]$Message
                    $ErrorRecord = New-Object Management.automation.errorrecord ($Exception,$ErrorID,$ErrorCategory,$Message)
                    $Message = $ErrorRecord
                    #Write the log entry
                    $logline = `
                        "<![LOG[$($($Type.ToUpper())+ ": " +  "$([String]$Message.exception.message)`r`r" + `
                        "`nFunction: $($Callinginfo.FunctionName)" + `
                        "`nScriptName: $($Callinginfo.Scriptname)" + `
                        "`nLine Number: $($Callinginfo.ScriptLineNumber)" + `
                        "`nColumn Number: $($Callinginfo.Position.StartColumnNumber)" + `
                        "`nLine: $($Callinginfo.Position.StartScriptPosition.Line)")]LOG]!>" +`
                        "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                        "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                        "component=`"$Component`" " +`
                        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                        "type=`"$Severity`" " +`
                        "thread=`"$ProcessID`" " +`
                        "file=`"$Source`">"
                        $logline | Out-File -Append -Encoding utf8 -FilePath $file;
                }                
            }   
        }#Error
        4{  
            #Verbose
            
            #Write the Log Entry
            
            $logline = `
            "<![LOG[$($($Type.ToUpper()) + ": " +  $message)]LOG]!>" +`
            "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
            "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$severity`" " +`
            "thread=`"$processid`" " +`
            "file=`"$source`">";
            $logline | Out-File -Append -Encoding utf8 -FilePath $file; 
            
            #Write Back to Host
                
            if(($WriteBackToHost) -and ($Type -eq 'Verbose')){
                Switch ($PSCmdlet.GetVariableValue('VerbosePreference')) {
                    'Continue' {$VerbosePreference = 'Continue'; Write-Verbose -Message "$Message";$VerbosePreference = ''}
                    'Inquire' {$VerbosePreference = 'Inquire'; Write-Verbose -Message "$Message";$VerbosePreference = ''}
                    'Stop' {$VerbosePreference = 'Stop'; Write-Verbose -Message "$Message";$VerbosePreference = ''}
                }
            }              
       
        }#Verbose
        5{  
            #Debug

            #Write the Log Entry
            
            $logline = `
            "<![LOG[$($($Type.ToUpper()) + ": " +  $message)]LOG]!>" +`
            "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
            "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$severity`" " +`
            "thread=`"$processid`" " +`
            "file=`"$source`">";
            $logline | Out-File -Append -Encoding utf8 -FilePath $file;  

            #Write Back to the Host.                              

            if(($WriteBackToHost) -and ($Type -eq 'Debug')){
                Switch ($PSCmdlet.GetVariableValue('DebugPreference')){
                    'Continue' {$DebugPreference = 'Continue'; Write-Debug -Message "$Message";$DebugPreference = ''}
                    'Inquire' {$DebugPreference = 'Inquire'; Write-Debug -Message "$Message";$DebugPreference = ''}
                    'Stop' {$DebugPreference = 'Stop'; Write-Debug -Message "$Message";$DebugPreference = ''}
                }
            } 
                      
        }#Debug
        6{  
            #Information

            #Write entry to the logfile.

            $logline = `
            "<![LOG[$($($Type.ToUpper()) + ": " + $message)]LOG]!>" +`
            "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
            "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$severity`" " +`
            "thread=`"$processid`" " +`
            "file=`"$source`">";            
            $logline | Out-File -Append -Encoding utf8 -FilePath $file;

            #Write back to the host.

            if(($WriteBackToHost) -and ($Type -eq 'Information')){
                Switch ($PSCmdlet.GetVariableValue('InformationPreference')){
                    'Continue' {$InformationPreference = 'Continue'; Write-Information -Message "INFORMATION: $Message";$InformationPreference = ''}
                    'Inquire' {$InformationPreference = 'Inquire'; Write-Information -Message "INFORMATION: $Message";$InformationPreference = ''}
                    'Stop' {$InformationPreference = 'Stop'; Write-Information -Message "INFORMATION: $Message";$InformationPreference = ''}
                    'Suspend' {$InformationPreference = 'Suspend';Write-Information -Message "INFORMATION: $Message";$InformationPreference = ''}
                }
            }
        }#Information
    }#Switch
}#Function v1.5 - 12-03-2016