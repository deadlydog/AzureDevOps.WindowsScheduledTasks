function Get-ScheduledTaskNameAndPath([string] $fullTaskName)
{
	$fullTaskName = $fullTaskName.TrimStart('\\')
	[string[]] $taskNameParts = $fullTaskName -split '\\'
	[string] $taskName = $taskNameParts | Select-Object -Last 1
	[string] $taskPath = '\' + $fullTaskName.Substring(0, $fullTaskName.Length - $taskName.Length)

	[hashtable] $taskNameAndPath = @{
		Name = $taskName
		Path = $taskPath
	}
	return $taskNameAndPath
}

function Get-AccountCredentialsToRunScheduledTaskAs
{
	param
	(
		[ValidateSet('System', 'LocalService', 'NetworkService', 'CustomAccount')]
		[string] $scheduldTaskAccountToRunAsOptions,
		[string] $customAccountToRunScheduledTaskAsUsername,
		[string] $customAccountToRunScheduledTaskAsPassword
	)

	[string] $username = [string]::Empty
	[string] $password = [string]::Empty
	switch ($scheduldTaskAccountToRunAsOptions)
	{
		"System" { $username = 'NT AUTHORITY\SYSTEM'; break }
		"LocalService" { $username = 'NT AUTHORITY\LOCALSERVICE'; break }
		"NetworkService" { $username = 'NT AUTHORITY\NETWORKSERVICE'; break }
		default
		{
			$username = $customAccountToRunScheduledTaskAsUsername
			$password = $customAccountToRunScheduledTaskAsPassword
			break
		}
	}

	[hashtable] $accountCredentials = @{
		Username = $username
		Password = $password
	}
	return $accountCredentials
}

function Get-WorkingDirectory
{
	param
	(
		[ValidateSet('ApplicationDirectory', 'CustomDirectory')]
		[string] $workingDirectoryOption,
		[string] $customWorkingDirectory,
		[string] $applicationPath
	)

	[string] $workingDirectory = $customWorkingDirectory
	if ($workingDirectoryOption -eq 'ApplicationDirectory')
	{
		$workingDirectory = Split-Path -Path $applicationPath -Parent
	}
	return $workingDirectory
}

Export-ModuleMember -Function Get-ScheduledTaskNameAndPath
Export-ModuleMember -Function Get-AccountCredentialsToRunScheduledTaskAs
Export-ModuleMember -Function Get-WorkingDirectory