#Requires -Version 3.0
# Requires -RunAsAdministrator # Commented out because this directive was introduced in PowerShell v4 and we want to be compatible with v3.

function Enable-WindowsScheduledTask
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to enable.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be enabled.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory = $false, HelpMessage = "The settings used to connect to remote computers.")]
		[hashtable] $WinRmSettings
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskPath = $ScheduledTaskPath
		}

		Invoke-EnableWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -winRmSettings $WinRmSettings
	}

	Begin
	{
		function Invoke-EnableWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [hashtable] $winRmSettings)
		{
			[string] $enableTaskCommand = 'Invoke-Command -ScriptBlock $enableScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $winRmSettings.Computers -and $winRmSettings.Computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$enableTaskCommand += ' -ComputerName $($winRmSettings.Computers)'

				# Only provide the Authentication and SessionOption when connecting to remote computers, otherwise we get an ambiguous parameter set error.
				$enableTaskCommand += ' -Authentication $($winRmSettings.AuthenticationMechanism) -SessionOption $($winRmSettings.PsSessionOptions)'
			}

			[bool] $credentialWasSpecified = ($null -ne $winRmSettings.Credential)
			if ($credentialWasSpecified)
			{
				$enableTaskCommand += ' -Credential $($winRmSettings.Credential)'
			}

			if ($winRmSettings.UseSsl)
			{
				$enableTaskCommand += ' -UseSSL'
			}

			Write-Debug "About to expand the string '$enableTaskCommand' to retrieve the expression in invoke."
			[string] $enableTaskCommandWithVariablesExpanded = $ExecutionContext.InvokeCommand.ExpandString($enableTaskCommand)

			Write-Debug "About to invoke expression '$enableTaskCommandWithVariablesExpanded'."
			Invoke-Expression -Command $enableTaskCommand -Verbose
		}

		[scriptblock] $enableScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			[string] $taskName = $scheduledTaskSettings.ScheduledTaskName
			[string] $taskPath = $scheduledTaskSettings.ScheduledTaskPath

			Write-Verbose "Searching for a Scheduled Task with the path '$taskPath' and name '$taskName'." -Verbose
			$tasks = ScheduledTasks\Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
			if ($null -eq $tasks)
			{
				[string] $taskPathAndName = $taskPath + $taskName
				Write-Warning "A Scheduled Task matching the path and name '$taskPathAndName' was not found on computer '$computerName', so no scheduled tasks will be enabled."
				return
			}

			foreach ($task in $tasks)
			{
				[string] $taskPathAndName = $task.TaskPath + $task.TaskName
				Write-Output "Enabling Scheduled Task '$taskPathAndName' on computer '$computerName'."
				$task | Enable-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Enable-WindowsScheduledTask
