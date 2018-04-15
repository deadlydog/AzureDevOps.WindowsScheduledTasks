[string] $serverNames = '$(Servers)'
[string] $scheduledTaskName = '$(ScheduledTaskName)'
[string] $scheduledTaskDescription = '$(ScheduledTaskDescription)'
[string] $applicationPathToRun = '$(ApplicationFilePath)'
[string] $applicationArguments = '$(ApplicationFilePathArguments)'
[string] $scheduleFrequency = '$(ScheduledTaskFrequency)'
[string] $scheduleStartTime = '$(ScheduledTaskStartTime)'
[string] $scheduleStartTimeRandomDelayInMinutes = '$(ScheduledTaskStartTimeRandomDelayInMinutes)'
[string] $scheduleRepeatIntervalInMinutes = '$(ScheduledTaskRepeatIntervalInMinutes)'
[string] $scheduleRepeatIntervalDurationInMinutes = '$(ScheduledTaskRepeatIntervalDurationInMinutes)'
[bool] $runScheduledTaskAfterInstallation = $(RunScheduledTaskAfterInstallation)
[string] $username = '$(UsernameToConnectToServersWith)'
[SecureString] $password = '$(PasswordToConnectToServersWith)' | ConvertTo-SecureString -AsPlainText -Force
Write-Host "Installing Scheduled Task '$scheduledTaskName' on '$serverNames'."

[string[]] $servers = $serverNames -split ','
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

[hashtable] $scheduledTaskSettings = @{
	TaskName = $scheduledTaskName
	TaskDescription = $scheduledTaskDescription
	ApplicationPathToRun = $applicationPathToRun
	ApplicationArguments = $applicationArguments
	ScheduleFrequency = $scheduleFrequency
	ScheduleStartTime = $scheduleStartTime
	ScheduleStartTimeRandomDelayInMinutes = $scheduleStartTimeRandomDelayInMinutes
	ScheduleRepeatIntervalInMinutes = $scheduleRepeatIntervalInMinutes
	ScheduleRepeatIntervalDurationInMinutes = $scheduleRepeatIntervalDurationInMinutes
	RunScheduledTaskAfterInstallation = $runScheduledTaskAfterInstallation
}

$installScheduledTaskScriptBlock = {
	param ([hashtable] $scheduledTaskSettings)
	$serverName = $Env:COMPUTERNAME

	$taskName = $scheduledTaskSettings.TaskName
	$applicationPathToRun = $scheduledTaskSettings.ApplicationPathToRun
	if (!(Test-Path -Path $applicationPathToRun -PathType Leaf))
	{
		Write-Error "The Scheduled Task '$taskName' was not installed on server '$serverName' because the file path '$applicationPathToRun' that it should launch does not exist."
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

	Write-Host "Creating Scheduled Task '$taskName' on server '$serverName'."
	$task = Register-ScheduledTask -TaskName $taskName -Description $scheduledTaskSettings.TaskDescription -Action $action -Trigger $trigger -User $userToRunAs

	Write-Host "Updating Scheduled Task '$taskName' on server '$serverName' to apply repeat interval."
	$task.Triggers.Repetition.Interval = [System.Xml.XmlConvert]::ToString($repeatInterval)
	$task.Triggers.Repetition.Duration = [System.Xml.XmlConvert]::ToString($repeatIntervalDuration)
	$task | Set-ScheduledTask

	if ($scheduledTaskSettings.RunScheduledTaskAfterInstallation)
	{
		Write-Host "Triggering the Scheduled Task '$taskName' on server '$serverName' to run now."
		$task | Start-ScheduledTask
	}
}

Invoke-Command -ComputerName $servers -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose