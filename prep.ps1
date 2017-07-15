$here = (Get-Item $MyInvocation.MyCommand.path)
$p = $here.DirectoryName | Split-Path -Parent
$ThisModule = $MyInvocation.MyCommand.Path -replace '\.Tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
$modulePath = '{0}\EBGLogging.psm1' -f $here.DirectoryName
Import-Module -Name $modulePath -Force -ErrorAction Stop
$logger = Get-EBGLogger
$logger.LogFile = 'C:\temp\test.log'