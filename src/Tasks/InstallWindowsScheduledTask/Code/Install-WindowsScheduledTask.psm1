#Requires -Version 3.0
#Requires -RunAsAdministrator

function Install-WindowsScheduledTask
{
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to uninstall.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to uninstall the scheduled task from. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential,

		[parameter(Mandatory=$true,HelpMessage="The description for the Scheduled Task.")]
		[string] $ScheduledTaskDescription,

		[parameter(Mandatory=$true,HelpMessage="The full path to the application executable or script file to run.")]
		[ValidateNotNullOrEmpty()]
		[string] $ApplicationPathToRun,

		[parameter(Mandatory=$false,HelpMessage="The arguments to pass to the application executable or script to run.")]
		[string] $ApplicationArguments,

		[parameter(Mandatory=$true,HelpMessage="How often the Scheduled Task should run.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduleFrequency,

		[parameter(Mandatory=$true,HelpMessage="When the Scheduled Task should start running.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduleStartTime,

		[parameter(Mandatory=$false,HelpMessage="How much potential delay to wait for after the Scheduled Tasks specified start time.")]
		[string] $ScheduleStartTimeRandomDelayInMinutes,

		[parameter(Mandatory=$false,HelpMessage="How long to wait between each running of the Scheduled Task.")]
		[string] $ScheduleRepeatIntervalInMinutes,

		[parameter(Mandatory=$false,HelpMessage="How long the Scheduled Task should keep repeating at the specified interval for.")]
		[string] $ScheduleRepeatIntervalDurationInMinutes = '$(ScheduledTaskRepeatIntervalDurationInMinutes)',

		[parameter(Mandatory=$false,HelpMessage="If the Scheduled Task should be ran immediately after installation or not.")]
		[bool] $RunScheduledTaskAfterInstallation
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			TaskName = $ScheduledTaskName
			TaskDescription = $ScheduledTaskDescription
			ApplicationPathToRun = $ApplicationPathToRun
			ApplicationArguments = $ApplicationArguments
			ScheduleFrequency = $ScheduleFrequency
			ScheduleStartTime = $ScheduleStartTime
			ScheduleStartTimeRandomDelayInMinutes = $ScheduleStartTimeRandomDelayInMinutes
			ScheduleRepeatIntervalInMinutes = $ScheduleRepeatIntervalInMinutes
			ScheduleRepeatIntervalDurationInMinutes = $ScheduleRepeatIntervalDurationInMinutes
			RunScheduledTaskAfterInstallation = $RunScheduledTaskAfterInstallation
		}

		Invoke-InstallWindowsScheduledTaskOnComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential
	}

	Begin
	{
		function Invoke-InstallWindowsScheduledTaskOnComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential)
		{
			[bool] $noComputersWereSpecified = ($computers -eq $null -or $computers.Count -eq 0)
			[bool] $noCredentialWasSpecified = ($credential -eq $null)

			if ($noComputersWereSpecified)
			{
				if ($noCredentialWasSpecified)
				{
					Invoke-Command -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
				else
				{
					Invoke-Command -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
			}
			else
			{
				if ($noCredentialWasSpecified)
				{
					Invoke-Command -ComputerName $computers -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
				else
				{
					Invoke-Command -ComputerName $computers -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
			}
		}

		$installScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			$taskName = $scheduledTaskSettings.TaskName
			$applicationPathToRun = $scheduledTaskSettings.ApplicationPathToRun
			if (!(Test-Path -Path $applicationPathToRun -PathType Leaf))
			{
				Write-Error "The Scheduled Task '$taskName' was not installed on computer '$computerName' because the file path '$applicationPathToRun' that it should launch does not exist."
				return
			}

			[bool] $noArguments = [string]::IsNullOrWhiteSpace($scheduledTaskSettings.ApplicationArguments) -or [string]::Equals($scheduledTaskSettings.ApplicationArguments, 'None', [StringComparison]::OrdinalIgnoreCase)
			if ($noArguments)
			{
				$scheduledTaskSettings.ApplicationArguments = ' '	# Empty Argument parameter results in error, so fill it with a meaningless space value.
			}

			[string] $applicationDirectory = Split-Path -Path $applicationPathToRun -Parent
			[TimeSpan] $startTimeRandomDelay = [TimeSpan]::FromMinutes($scheduledTaskSettings.ScheduleStartTimeRandomDelayInMinutes)
			[TimeSpan] $repeatInterval = [TimeSpan]::FromMinutes($scheduledTaskSettings.ScheduleRepeatIntervalInMinutes)
			[TimeSpan] $repeatIntervalDuration = [TimeSpan]::FromMinutes($scheduledTaskSettings.ScheduleRepeatIntervalDurationInMinutes)

			[string] $frequency = $scheduledTaskSettings.ScheduleFrequency
			[DateTime] $startTime = [DateTime]::Parse($scheduledTaskSettings.ScheduleStartTime)
			[string] $createTriggerCommand = "New-ScheduledTaskTrigger -$frequency -At '$startTime' -RandomDelay $startTimeRandomDelay"

			$action = New-ScheduledTaskAction -Execute $applicationPathToRun -Argument $scheduledTaskSettings.ApplicationArguments -WorkingDirectory $applicationDirectory
			$trigger = (Invoke-Expression -Command $createTriggerCommand)
			$userToRunAs = "NETWORK SERVICE"

			Write-Host "Creating Scheduled Task '$taskName' on computer '$computerName'."
			$task = Register-ScheduledTask -TaskName $taskName -Description $scheduledTaskSettings.TaskDescription -Action $action -Trigger $trigger -User $userToRunAs

			Write-Host "Updating Scheduled Task '$taskName' on computer '$computerName' to apply repeat interval."
			$task.Triggers.Repetition.Interval = [System.Xml.XmlConvert]::ToString($repeatInterval)
			$task.Triggers.Repetition.Duration = [System.Xml.XmlConvert]::ToString($repeatIntervalDuration)
			$task | Set-ScheduledTask

			if ($scheduledTaskSettings.RunScheduledTaskAfterInstallation)
			{
				Write-Host "Triggering the Scheduled Task '$taskName' on computer '$computerName' to run now."
				$task | Start-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Install-WindowsScheduledTask