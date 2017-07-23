$here = (Get-Item $MyInvocation.MyCommand.path)
$p = $here.DirectoryName | Split-Path -Parent
$ThisModule = $MyInvocation.MyCommand.Path -replace '\.Tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
$modulePath = '{0}\EBGLogging.psm1' -f $here.DirectoryName
Import-Module -Name $modulePath -Force -ErrorAction Stop
$logger = Get-EBGLogger
$logger.LogFile = 'C:\temp\test.log'
$logger.Verbose = $true
<# if($cred -eq $null){
    $cred = Get-Credential
}
$mailInfo = @{
        'to' = 'robert.dowell@gmail.com';
        'from' = 'robert.dowell@gmail.com';
        'cc' = '';
        'subject' = 'Test Log Email';
        'body' = 'This was only a test';
        'SMTPServer' = 'smtp.gmail.com';
        'SMTPPort' = '587';
        'credentials' = $cred
}
$logger.MailInfo = $mailInfo #>

