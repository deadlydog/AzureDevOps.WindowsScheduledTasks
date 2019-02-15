#Requires -Version 3.0
#Requires -RunAsAdministrator

function Disable-WindowsScheduledTask
{
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to disable.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be disabled.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to disable the scheduled task on. If null localhost will be used.")]
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

		Invoke-DisableWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential -useCredSsp $UseCredSsp
	}

	Begin
	{
		function Invoke-DisableWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential, [bool] $useCredSsp)
		{
			[string] $disableTaskCommand = 'Invoke-Command -ScriptBlock $disableScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $computers -and $computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$disableTaskCommand += ' -ComputerName $computers'
			}

			[bool] $credentialWasSpecified = ($null -ne $credential)
			if ($credentialWasSpecified)
			{
				$disableTaskCommand += ' -Credential $credential'
			}

			if ($useCredSsp)
			{
				$disableTaskCommand += ' -Authentication Credssp'
			}

			[string] $disableTaskCommandWithVariablesExpanded = $ExecutionContext.InvokeCommand.ExpandString($disableTaskCommand)
			Write-Debug "About to invoke expression '$disableTaskCommandWithVariablesExpanded'."
			Invoke-Expression -Command $disableTaskCommand -Verbose
		}

		[scriptblock] $disableScheduledTaskScriptBlock = {
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
				Write-Warning "A Scheduled Task matching the path and name '$taskPathAndName' was not found on computer '$computerName', so no scheduled tasks will be disabled."
				return
			}

			foreach ($task in $tasks)
			{
				[string] $taskPathAndName = $task.TaskPath + $task.TaskName
				Write-Output "Disabling Scheduled Task '$taskPathAndName' on computer '$computerName'."
				$task | Disable-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Disable-WindowsScheduledTask