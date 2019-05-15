#Requires -Version 3.0
#Requires -RunAsAdministrator

function Stop-WindowsScheduledTask
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to stop.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be stopped.")]
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

		Invoke-StopWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -winRmSettings $WinRmSettings
	}

	Begin
	{
		function Invoke-StopWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [hashtable] $winRmSettings)
		{
			[string] $stopTaskCommand = 'Invoke-Command -ScriptBlock $stopScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $winRmSettings.Computers -and $winRmSettings.Computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$stopTaskCommand += ' -ComputerName $($winRmSettings.Computers)'

				# Only provide the Authentication and SessionOption when connecting to remote computers, otherwise we get an ambiguous parameter set error.
				$stopTaskCommand += ' -Authentication $($winRmSettings.AuthenticationMechanism) -SessionOption $($winRmSettings.PsSessionOptions)'
			}

			[bool] $credentialWasSpecified = ($null -ne $winRmSettings.Credential)
			if ($credentialWasSpecified)
			{
				$stopTaskCommand += ' -Credential $($winRmSettings.Credential)'
			}

			Write-Debug "About to expand the string '$stopTaskCommand' to retrieve the expression in invoke."
			[string] $stopTaskCommandWithVariablesExpanded = $ExecutionContext.InvokeCommand.ExpandString($stopTaskCommand)

			Write-Debug "About to invoke expression '$stopTaskCommandWithVariablesExpanded'."
			Invoke-Expression -Command $stopTaskCommand -Verbose
		}

		[scriptblock] $stopScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			[string] $taskName = $scheduledTaskSettings.ScheduledTaskName
			[string] $taskPath = $scheduledTaskSettings.ScheduledTaskPath

			Write-Verbose "Searching for a Scheduled Task with the path '$taskPath' and name '$taskName'." -Verbose
			$tasks = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
			if ($null -eq $tasks)
			{
				[string] $taskPathAndName = $taskPath + $taskName
				Write-Warning "A Scheduled Task matching the path and name '$taskPathAndName' was not found on computer '$computerName', so no scheduled tasks will be stopped."
				return
			}

			foreach ($task in $tasks)
			{
				[string] $taskPathAndName = $task.TaskPath + $task.TaskName
				Write-Output "Stopping Scheduled Task '$taskPathAndName' on computer '$computerName'."
				$task | Stop-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Stop-WindowsScheduledTask
