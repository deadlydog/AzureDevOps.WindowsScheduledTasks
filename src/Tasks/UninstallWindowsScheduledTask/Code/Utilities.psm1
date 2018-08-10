function Get-ComputersToConnectToOrNull([string] $computerNames)
{
	[string[]] $computers = $computerNames -split ','

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

	$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$securePassword
	return $credential
}

Export-ModuleMember -Function Get-ComputersToConnectToOrNull
Export-ModuleMember -Function Convert-UsernameAndPasswordToCredentialsOrNull