# Import the module to test.
Set-StrictMode -Version Latest
[string] $THIS_SCRIPTS_PATH = $PSCommandPath
[string] $moduleFilePathToTest = $THIS_SCRIPTS_PATH.Replace('.Tests.ps1', '.psm1') | Resolve-Path
Write-Verbose "Importing the module file '$moduleFilePathToTest' to run tests against it." -Verbose
Import-Module -Name $moduleFilePathToTest -Force

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
		[string[]] $expectedComputerNamesArray = @('localhost', 'DansPc')

		$computers = Get-ComputersToConnectToOrNull -computerNames $computerNames

		$computers | Should -Be $expectedComputerNamesArray
	}

	It 'ReturnsAllComputersWithWhitespaceTrimmedWhenMultipleAreSpecifiedWithWhitespaceBetweenThem' {
		[string] $computerNames = 'localhost , DansPc'
		[string[]] $expectedComputerNamesArray = @('localhost', 'DansPc')

		$computers = Get-ComputersToConnectToOrNull -computerNames $computerNames

		$computers | Should -Be $expectedComputerNamesArray
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

	It 'Returns a credential object when both a username and password are supplied' {
		[string] $username = 'Dan'
		[string] $password = 'secret'

		$credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $username -password $password

		$credential | Should -Not -Be $null
	}
}

Describe 'Getting the WinRM settings' {
	It 'Should set the UseSSL to false when HTTP is specified' {
		$settings = Get-WinRmSettings -computers $null -credential $null -authenticationMechanism 'Default' -protocol 'HTTP' -skipCaCheck $false -skipCnCheck $false -skipRevocationCheck $false

		$settings.UseSSL | Should -BeFalse
	}

	It 'Should set the UseSSL to true when HTTPS is specified' {
		$settings = Get-WinRmSettings -computers $null -credential $null -authenticationMechanism 'Default' -protocol 'HTTPS' -skipCaCheck $false -skipCnCheck $false -skipRevocationCheck $false

		$settings.UseSSL | Should -BeTrue
	}
}
