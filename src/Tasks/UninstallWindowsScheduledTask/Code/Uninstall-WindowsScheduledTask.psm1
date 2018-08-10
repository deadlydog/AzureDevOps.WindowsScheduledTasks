#Requires -Version 3.0
#Requires -RunAsAdministrator

function Uninstall-WindowsScheduledTask
{
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to uninstall.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to uninstall the scheduled task from. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			TaskName = $ScheduledTaskName
		}

		Invoke-WindowsScheduledTaskUninstallOnComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential
	}

	Begin
	{
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
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			$taskNameParts = $scheduledTaskSettings.TaskName -split '\\'
			$taskName = $taskNameParts | Select-Object -Last 1
			$taskPath = '\' + $scheduledTaskSettings.TaskName.Substring(0, $scheduledTaskSettings.TaskName.Length - $taskName.Length)

			Write-Verbose "Searching for a Scheduled Task with the path '$taskPath' and name '$taskName'." -Verbose
			$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
			if ($task -eq $null)
			{
				Write-Warning "A scheduled task with the path '$taskPath' and name '$taskName' was not found on computer '$computerName', so no scheduled tasks will be uninstalled."
				return
			}

			Write-Output "Uninstalling Scheduled Task '$taskName' on computer '$computerName'."
			$task | Disable-ScheduledTask > $null
			$task | Stop-ScheduledTask
			$task | Unregister-ScheduledTask -Confirm:$false
		}
	}
}

Export-ModuleMember -Function Uninstall-WindowsScheduledTask