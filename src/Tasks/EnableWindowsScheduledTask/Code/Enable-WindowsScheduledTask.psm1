#Requires -Version 3.0
#Requires -RunAsAdministrator

function Enable-WindowsScheduledTask
{
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to enable.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be enabled.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to enable the scheduled task on. If null localhost will be used.")]
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

		Invoke-EnableWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential -useCredSsp $UseCredSsp
	}

	Begin
	{
		function Invoke-EnableWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential, [bool] $useCredSsp)
		{
			[string] $enableTaskCommand = 'Invoke-Command -ScriptBlock $enableScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $computers -and $computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$enableTaskCommand += ' -ComputerName $computers'
			}

			[bool] $credentialWasSpecified = ($null -ne $credential)
			if ($credentialWasSpecified)
			{
				$enableTaskCommand += ' -Credential $credential'
			}

			if ($useCredSsp)
			{
				$enableTaskCommand += ' -Authentication Credssp'
			}

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
			$tasks = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
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