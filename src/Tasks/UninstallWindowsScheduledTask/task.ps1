param
(
	[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to uninstall.")]
	[ValidateNotNullOrEmpty()]
	[string] $scheduledTaskName,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to uninstall the scheduled task from.")]
	[ValidateNotNullOrEmpty()]
	[string] $computerNames,

	[parameter(Mandatory=$false,HelpMessage="The username to use to connect to the computer(s).")]
	[string] $username,

	[parameter(Mandatory=$false,HelpMessage="The password to use to connect to the computer(s).")]
	[string] $password
)

Process
{
	Write-Verbose "About to uninstall Windows Scheduled Task '$scheduledTaskName' on '$computerNames'." -Verbose

	[string[]] $computers = Get-ComputersToConnectTo -computerNames $computerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $username -password $password

	[hashtable] $scheduledTaskSettings = @{
		TaskName = $scheduledTaskName
	}

	Invoke-WindowsScheduledTaskUninstallOnComputers -scheduledTaskSettings $scheduledTaskSettings -computers $computers -credential $credential
}

Begin
{
	function Get-ComputersToConnectTo([string] $computerNames)
	{
# TODO - Write unit test to see if $null or an empty array are returned when no computersNames are given
		[string[]] $computers = $computerNames -split ','

		[bool] $arrayContainsOneBlankElement = ($computers.Count -eq 1 -and [string]::IsNullOrWhiteSpace($computers[0]))
		if ($arrayContainsOneBlankElement)
		{
			$computers = [string[]]::new(0)
		}

		return $computers
	}

	function Convert-UsernameAndPasswordToCredentialsOrNull([string] $username, [string] $password)
	{
		if ([string]::IsNullOrWhiteSpace($username))
		{
			return $null
		}
# TODO - Write unit test to see what happens with a blank password
		[SecureString] $securePassword = ($password | ConvertTo-SecureString -AsPlainText -Force)

		$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$securePassword
		return $credential
	}

	function Invoke-WindowsScheduledTaskUninstallOnComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential)
	{
		[bool] $noComputersWereSpecified = ($computers -eq $null -or $computers.Count -eq 0)
		[bool] $noCredentialWasSpecified = ($credential -eq $null)

		if ($noComputersWereSpecified)
		{
			if ($noCredentialWasSpecified)
			{
				Invoke-Command -ScriptBlock $uninstallScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
			}
			else
			{
				Invoke-Command -Credential $credential -ScriptBlock $uninstallScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
			}
		}
		else
		{
			if ($noCredentialWasSpecified)
			{
				Invoke-Command -ComputerName $computers -ScriptBlock $uninstallScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
			}
			else
			{
				Invoke-Command -ComputerName $computers -Credential $credential -ScriptBlock $uninstallScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
			}
		}
	}

	$uninstallScheduledTaskScriptBlock = {
		param ([hashtable] $scheduledTaskSettings)
		[string] $computerName = $Env:COMPUTERNAME
		[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
		Write-Verbose "Connected to computer '$computerName' as user '$username'." -Verbose

		$taskNameParts = $scheduledTaskSettings.TaskName -split '\\'
		$taskName = $taskNameParts | Select-Object -Last 1
		$taskPath = '\' + $scheduledTaskSettings.TaskName.Substring(0, $scheduledTaskSettings.TaskName.Length - $taskName.Length)

		$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
		if ($task -eq $null)
		{
			Write-Host "A scheduled task with the path '$taskPath' and name '$taskName' was not found on computer '$computerName', so no scheduled tasks will be uninstalled."
			return
		}

		Write-Host "Uninstalling Scheduled Task '$taskName' on computer '$computerName'."
		$task | Disable-ScheduledTask
		$task | Stop-ScheduledTask
		$task | Unregister-ScheduledTask -Confirm:$false
	}
}