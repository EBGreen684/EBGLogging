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