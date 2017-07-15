$ThisModule = $MyInvocation.MyCommand.Path -replace '\.Tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$ThisModule.psm1" -Force -ErrorAction Stop
# To test private functions:
# InModuleScope $ThisModuleName {
# describe 'Set-Something' {
# it 'does this thing' {
# Set-Something
#    }
#  }
#}

