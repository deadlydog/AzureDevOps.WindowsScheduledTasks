function Get-ScheduledTaskNameAndPath([string] $fullTaskName)
{
	$fullTaskName = $fullTaskName.TrimStart('\\')
	[string[]] $taskNameParts = $fullTaskName -split '\\'
	[string] $taskName = $taskNameParts | Select-Object -Last 1
	[string] $taskPath = '\' + $fullTaskName.Substring(0, $fullTaskName.Length - $taskName.Length)

	[hashtable] $taskNameAndPath = @{
		Name = $taskName
		Path = $taskPath
	}
	return $taskNameAndPath
}

function Get-AccountCredentialsToRunScheduledTaskAs
{
	param
	(
		[ValidateSet('System', 'LocalService', 'NetworkService', 'CustomAccount')]
		[string] $scheduldTaskAccountToRunAsOptions,
		[string] $customAccountToRunScheduledTaskAsUsername,
		[string] $customAccountToRunScheduledTaskAsPassword
	)

	[string] $username = [string]::Empty
	[string] $password = [string]::Empty
	switch ($scheduldTaskAccountToRunAsOptions)
	{
		"System" { $username = 'NT AUTHORITY\SYSTEM'; break }
		"LocalService" { $username = 'NT AUTHORITY\LOCALSERVICE'; break }
		"NetworkService" { $username = 'NT AUTHORITY\NETWORKSERVICE'; break }
		default
		{
			$username = $customAccountToRunScheduledTaskAsUsername
			$password = $customAccountToRunScheduledTaskAsPassword
			break
		}
	}

	[hashtable] $accountCredentials = @{
		Username = $username
		Password = $password
	}
	return $accountCredentials
}

function Get-WorkingDirectory
{
	param
	(
		[ValidateSet('ApplicationDirectory', 'CustomDirectory')]
		[string] $workingDirectoryOption,
		[string] $customWorkingDirectory,
		[string] $applicationPath
	)

	[string] $workingDirectory = $customWorkingDirectory
	if ($workingDirectoryOption -eq 'ApplicationDirectory')
	{
		$workingDirectory = Split-Path -Path $applicationPath -Parent
	}
	return $workingDirectory
}

function Get-ScheduledTaskAction([string] $applicationPathToRun, [string] $applicationArguments, [string] $workingDirectory)
{
	$createActionExpression = "New-ScheduledTaskAction -Execute `"$applicationPathToRun`""

	if (!([string]::IsNullOrWhiteSpace($applicationArguments)))
	{
		$createActionExpression += " -Argument `"$applicationArguments`""
	}

	if (!([string]::IsNullOrWhiteSpace($workingDirectory)))
	{
		$createActionExpression += " -WorkingDirectory `"$workingDirectory`""
	}

	[CimInstance[]] $scheduledTaskAction = Invoke-Expression -Command $createActionExpression
	return $scheduledTaskAction
}

function Get-ScheduledTaskTrigger
{
	param
	(
		[ValidateSet('DateTime', 'AtLogOn', 'AtStartup')]
		[string] $triggerType,
		[string] $atLogOnTriggerUsername,
		[string] $dateTimeScheduleStartTime,
		[string] $dateTimeScheduleFrequencyOptions,
		[string] $dateTimeScheduleFrequencyDailyInterval,
		[string] $dateTimeScheduleFrequencyWeeklyInterval,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnMondays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnFridays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSundays,
		[bool] $shouldScheduledTaskRunRepeatedly,
		[string] $scheduleRepetitionIntervalInMinutes,
		[string] $scheduleRepetitionDurationInMinutes,
		[string] $scheduleStartTimeRandomDelayInMinutes
	)

	[string] $createTriggerExpression = 'New-ScheduledTaskTrigger'

	switch ($triggerType)
	{
		'AtLogOn' {
			$createTriggerExpression += ' -AtLogOn'
			$createTriggerExpression += " -User '$atLogOnTriggerUsername'"
			break
		}

		'AtStartup' {
			$createTriggerExpression += ' -AtStartup'
			break
		}

		'DateTime' {
			$createTriggerExpression += " -At '$dateTimeScheduleStartTime'"

			switch ($dateTimeScheduleFrequencyOptions)
			{
				'Once' {
					$createTriggerExpression += ' -Once'
				}

				'Daily' {
					$createTriggerExpression += ' -Daily'
					$createTriggerExpression += " -DaysInterval $dateTimeScheduleFrequencyDailyInterval"
				}

				'Weekly' {
					$createTriggerExpression += ' -Weekly'
					$createTriggerExpression += " -WeeksInterval $dateTimeScheduleFrequencyWeeklyInterval"

					[System.DayOfWeek[]] $daysOfTheWeekToRunOn = @()
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnMondays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Monday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Tuesday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Wednesday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Thursday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnFridays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Friday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Saturday }
					if ($shouldDateTimeScheduleFrequencyWeeklyRunOnSundays) { $daysOfTheWeekToRunOn += [System.DayOfWeek]::Sunday }
					[string] $daysOfTheWeekToRunOnString = $daysOfTheWeekToRunOn -join ','
					$createTriggerExpression += " -DaysOfWeek $daysOfTheWeekToRunOnString"
				}
			}
			break
		}
	}

	if (!([string]::IsNullOrWhiteSpace($scheduleStartTimeRandomDelayInMinutes)))
	{
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RandomDelay' -minutes $scheduleStartTimeRandomDelayInMinutes
	}

	if ($shouldScheduledTaskRunRepeatedly)
	{
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RepetitionInterval' -minutes $scheduleRepetitionIntervalInMinutes
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RepetitionDuration' -minutes $scheduleRepetitionDurationInMinutes
	}

	[CimInstance[]] $scheduledTaskTrigger = Invoke-Expression -Command $createTriggerExpression
	return $scheduledTaskTrigger
}

function ConvertMinutesToTimeSpanAndAddParameterToExpression([string] $expression, [string] $parameterName, [string] $minutes)
{
	[double] $minutesAsDouble = [double]::Parse($minutes)
	[timespan] $minutesAsTimeSpan = [timespan]::FromMinutes($minutesAsDouble)
	[string] $minutesTimeSpanAsString = $minutesAsTimeSpan.ToString()
	$expression += " -$parameterName $minutesTimeSpanAsString"
}

function Get-ScheduledTaskSettings([bool] $shouldBeEnabled)
{
	[string] $createSettingsExpression = "New-ScheduledTaskSettingsSet"

	if (!($shouldBeEnabled)) { $createSettingsExpression += ' -Disable' }

	[CimInstance] $scheduledTaskSettings = Invoke-Expression -Command $createSettingsExpression
	return $scheduledTaskSettings
}

function Get-ScheduledTaskRunLevel([bool] $shouldScheduledTaskRunWithHighestPrivileges)
{
	[string] $privileges = 'Limited'
	if ($shouldScheduledTaskRunWithHighestPrivileges)
	{
		$privileges = 'Highest'
	}
	return $privileges
}

Export-ModuleMember -Function Get-ScheduledTaskNameAndPath
Export-ModuleMember -Function Get-AccountCredentialsToRunScheduledTaskAs
Export-ModuleMember -Function Get-WorkingDirectory
Export-ModuleMember -Function Get-ScheduledTaskAction
Export-ModuleMember -Function Get-ScheduledTaskTrigger
Export-ModuleMember -Function Get-ScheduledTaskSettings
Export-ModuleMember -Function Get-ScheduledTaskRunLevel