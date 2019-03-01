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

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to stop the scheduled task on. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential,

		[parameter(Mandatory=$false,HelpMessage="If CredSSP should be used when connecting to remote computers or not.")]
		[bool] $UseCredSsp
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskPath = $ScheduledTaskPath
		}

		Invoke-StopWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential -useCredSsp $UseCredSsp
	}

	Begin
	{
		function Invoke-StopWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential, [bool] $useCredSsp)
		{
			[string] $stopTaskCommand = 'Invoke-Command -ScriptBlock $stopScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $computers -and $computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$stopTaskCommand += ' -ComputerName $computers'
			}

			[bool] $credentialWasSpecified = ($null -ne $credential)
			if ($credentialWasSpecified)
			{
				$stopTaskCommand += ' -Credential $credential'
			}

			if ($useCredSsp)
			{
				$stopTaskCommand += ' -Authentication Credssp'
			}

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