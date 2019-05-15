# This file should only be modified if it is the one in the `SharedTaskCode` directory.
# Otherwise changes here will be overwritten the next time the Copy Files script is ran.

function Get-ComputersToConnectToOrNull([string] $computerNames)
{
	[string[]] $computers = $computerNames -split '\s*,\s*'

	[bool] $arrayContainsOneBlankElement = ($computers.Count -eq 1 -and [string]::IsNullOrWhiteSpace($computers[0]))
	if ($arrayContainsOneBlankElement)
	{
		$computers = $null
	}

	return $computers
}

function Convert-UsernameAndPasswordToCredentialsOrNull([string] $username, [string] $password)
{
	if ([string]::IsNullOrWhiteSpace($username) -or [string]::IsNullOrWhiteSpace($password))
	{
		return $null
	}

	[SecureString] $securePassword = ($password | ConvertTo-SecureString -AsPlainText -Force)

	$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword
	return $credential
}

function Get-WinRmSettings
{
	param
	(
		[string[]] $computers,
		[PSCredential] $credential,

		[ValidateSet('Default', 'Basic', 'CredSSP', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
		[string] $authenticationMechanism,

		[ValidateSet('HTTP', 'HTTPS')]
		[string] $protocol,

		[bool] $skipCaCheck,
		[bool] $skipCnCheck,
		[bool] $skipRevocationCheck
	)

	[bool] $useSsl = $false
	if ($protocol -ieq 'HTTPS')
	{
		$useSsl = $true
	}

	[System.Management.Automation.Remoting.PSSessionOption] $psSessionOptions = New-PSSessionOption -SkipCACheck:$protocolSkipCaCheck -SkipCNCheck:$protocolSkipCnCheck -SkipRevocationCheck:$protocolSkipRevocationCheck

	[hashtable] $winRmSettings = @{
		Computers = $computers
		Credential = $credential
		AuthenticationMechanism = $authenticationMechanism
		UseSsl = $useSsl
		PsSessionOptions = $psSessionOptions
	}

	return $winRmSettings
}

Export-ModuleMember -Function Get-ComputersToConnectToOrNull
Export-ModuleMember -Function Convert-UsernameAndPasswordToCredentialsOrNull
Export-ModuleMember -Function Get-WinRmSettings
