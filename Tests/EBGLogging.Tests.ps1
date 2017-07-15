$here = (Get-Item $MyInvocation.MyCommand.path)
$p = $here.DirectoryName | Split-Path -Parent
$ThisModule = $MyInvocation.MyCommand.Path -replace '\.Tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
$modulePath = '{0}\{1}.psm1' -f $p, $ThisModuleName
Import-Module -Name $modulePath -Force -ErrorAction Stop
InModuleScope EBGLogging{
    $logger = Get-EBGLogger
    Describe GetLogSize{
        Context NormalOperations{
            It GetLogSize{
                Mock Get-ChildItem {[PSCustomObject]@{length='468732'}}
                Get-LogSize $foo | Should Be 0.45
            }
        }
    }
}
# To test private functions:
# InModuleScope $ThisModuleName {
# describe 'Set-Something' {
# it 'does this thing' {
# Set-Something
#    }
#  }
#}

