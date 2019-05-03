# Import the module to test.
Set-StrictMode -Version Latest
[string] $THIS_SCRIPTS_PATH = $PSCommandPath
[string] $moduleFilePathToTest = $THIS_SCRIPTS_PATH.Replace('.Tests.ps1', '.psm1') | Resolve-Path
Write-Verbose "Importing the module file '$moduleFilePathToTest' to run tests against it." -Verbose
Import-Module -Name $moduleFilePathToTest -Force

Describe 'Getting the WinRM settings' {
	It 'Should set the UseSSL to false when HTTP is specified' {
		$settings = Get-WinRmSettings -computers $null -credential $null -useCredSsp $false -protocol 'HTTP' -skipCaCheck $false -skipCnCheck $false -skipRevocationCheck $false

		$settings.UseSSL | Should -BeFalse
	}

	It 'Should set the UseSSL to true when HTTPS is specified' {
		$settings = Get-WinRmSettings -computers $null -credential $null -useCredSsp $false -protocol 'HTTPS' -skipCaCheck $false -skipCnCheck $false -skipRevocationCheck $false

		$settings.UseSSL | Should -BeTrue
	}
}