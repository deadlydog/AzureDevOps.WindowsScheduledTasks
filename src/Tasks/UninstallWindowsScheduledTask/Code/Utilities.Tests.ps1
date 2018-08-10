# Import the module to test.
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
		[string[]] $computerNamesArray = $computerNames -split ','

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

Describe 'Get-PowerShellVersion' {
	It 'Returns a version number' {
		[string] $versionNumber = Get-PowerShellVersion

		[System.Version] $version = $null
		[bool] $isValidVersionNumber = [System.Version]::TryParse($versionNumber, [ref] $version)
		$isValidVersionNumber | Should -Be $true
	}
}