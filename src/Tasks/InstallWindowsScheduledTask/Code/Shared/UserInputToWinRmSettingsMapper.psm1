# This file should only be modified if it is the one in the `SharedTaskCode` directory.
# Otherwise changes here will be overwritten the next time the Copy Files script is ran.

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

Export-ModuleMember -Function Get-WinRmSettings
