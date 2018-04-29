# Dot-source the file we want to test
$THIS_SCRIPTS_PATH = $PSCommandPath
$filePathToTest = $THIS_SCRIPTS_PATH.Replace('.Tests', '')
Write-Verbose "Dot-sourcing the file '$filePathToTest' to run tests against it." -Verbose
. $filePathToTest

Describe 'Get-ComputersToConnectToOrNull' {
	It 'ReturnsNullWhenNoComputersAreSpecified' {
		[string] $computerNames = ''

		$computers = Get-ComputersToConnectToOrNull -computerNames $computerNames

		$computers | Should -Be $null
	}

	It 'ReturnsTheComputerWhenOnlyOneIsSpecified' {
		[string] $computerNames = 'localhost'

		$computers = Get-ComputersToConnectToOrNull -computerNames $computerNames

		$computers | Should -Be $computerNames
	}

	It 'ReturnsAllComputersWhenMultipleAreSpecified' {
		[string] $computerNames = 'localhost,DansPc'
		$computerNamesArray = $computerNames -split ','

		$computers = Get-ComputersToConnectToOrNull -computerNames $computerNames

		$computers | Should -Be $computerNamesArray
	}
}

Describe 'Convert-UsernameAndPasswordToCredentialsOrNull' {
	It 'Returns null when no username is supplied' {
		[string] $username = ''
		[string] $password = 'secret'

		$credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $username -password $password

		$credential | Should -Be $null
	}

	It 'Returns null when no password is supplied' {
		[string] $username = 'Dan'
		[string] $password = ''

		$credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $username -password $password

		$credential | Should -Be $null
	}
}