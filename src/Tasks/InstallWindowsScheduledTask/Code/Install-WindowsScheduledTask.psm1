#Requires -Version 3.0

function Install-WindowsScheduledTask
{
	[cmdletbinding(DefaultParameterSetName='Inline')]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to install.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler where the Windows Scheduled Task should be installed.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$true,HelpMessage="The account that should be used to run the Scheduled Task.")]
		[ValidateNotNull()]
		[PSCredential] $AccountCredentialsToRunScheduledTaskAs,

		[parameter(ParameterSetName="Xml",Mandatory=$true,HelpMessage="The path to the XML file containing the Scheduled Task definition.")]
		[string] $XmlFilePath,

		[parameter(ParameterSetName="Inline",Mandatory=$false,HelpMessage="The description for the Scheduled Task.")]
		[string] $ScheduledTaskDescription,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task action.")]
		[ValidateNotNull]
		[CimInstance[]] $ScheduledTaskAction,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task settings.")]
		[ValidateNotNull]
		[CimInstance] $ScheduledTaskSettings,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task trigger.")]
		[ValidateNotNull]
		[CimInstance[]] $ScheduledTaskTrigger,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task run level (i.e. admin or regular user).")]
		[ValidateNotNullOrEmpty]
		[string] $ScheduledTaskRunLevel,

		[parameter(Mandatory=$false,HelpMessage="If the Scheduled Task should be ran immediately after installation or not.")]
		[bool] $ShouldScheduledTaskRunAfterInstall,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to uninstall the scheduled task from. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential,

		[parameter(Mandatory=$false,HelpMessage="If Cred SSP should be used when connecting to the remote computers or not.")]
		[bool] $UseCredSsp
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
			ShouldRunScheduledTaskAfterInstallation = $ShouldScheduledTaskRunAfterInstall
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

			if ($scheduledTaskSettings.ShouldRunScheduledTaskAfterInstallation)
			{
				Write-Host "Triggering the Scheduled Task '$taskName' on computer '$computerName' to run now."
				$task | Start-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Install-WindowsScheduledTask