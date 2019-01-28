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

function Get-ScheduledTaskTrigger
{
	param
	(
		[ValidateSet('DateTime', 'AtLogOn', 'AtStartup')]
		[string] $triggerType,	# TEMP: parameter accounted for in function.
		[string] $atLogOnTriggerUsername,	# TEMP: parameter accounted for in function.
		[string] $dateTimeScheduleStartTime,	# TEMP: parameter accounted for in function.
		[string] $dateTimeScheduleFrequencyOptions,	# TEMP: parameter accounted for in function.
		[string] $dateTimeScheduleFrequencyDailyInterval,
		[string] $dateTimeScheduleFrequencyWeeklyInterval,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnMondays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnFridays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays,
		[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSundays,
		[bool] $shouldScheduledTaskRunRepeatedly,	# TEMP: parameter accounted for in function.
		[string] $scheduleRepetitionIntervalInMinutes,	# TEMP: parameter accounted for in function.
		[string] $scheduleRepetitionDurationInMinutes,	# TEMP: parameter accounted for in function.
		[string] $scheduleStartTimeRandomDelayInMinutes	# TEMP: parameter accounted for in function.
	)

	[string] $createTriggerExpression = 'New-ScheduledTaskTrigger'

	switch ($triggerType)
	{
		'AtLogOn' {
			$createTriggerExpression += ' -AtLogOn'
			$createTriggerExpression += " -User '$atLogOnTriggerUser'"
		}

		'AtStartup' {
			$createTriggerExpression += ' -AtStartup'
		}

		'DateTime' {
			$createTriggerExpression += " -At $dateTimeScheduleStartTime"

# TODO: finsih this
			case ($dateTimeScheduleFrequencyOptions)
			{
				'Once' {
					$createTriggerExpression += ' -Once'
				}

				'Daily' {
					$createTriggerExpression += ' -Daily'

				}

				'Weekly' {
					$createTriggerExpression += ' -Weekly'

				}
			}
		}
	}

	if (!([string]::IsNullOrWhiteSpace($scheduleStartTimeRandomDelayInMinutes))
	{
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RandomDelay' -minutes $scheduleStartTimeRandomDelayInMinutes
	}

	if ($shouldScheduledTaskRunRepeatedly)
	{
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RepetitionInterval' -minutes $scheduleRepetitionIntervalInMinutes
		ConvertMinutesToTimeSpanAndAddParameterToExpression -expression $createTriggerExpression -parameterName 'RepetitionDuration' -minutes $scheduleRepetitionDurationInMinutes
	}
}

function ConvertMinutesToTimeSpanAndAddParameterToExpression([string] $expression, [string] $parameterName, [string] $minutes)
{
	[double] $minutesAsDouble = [double]::Parse($scheduleStartTimeRandomDelayInMinutes)
	[timespan] $minutesAsTimeSpan = [timespan]::FromMinutes($randomDelayInMinutes)
	[string] $minutesTimeSpanAsString = $minutesAsTimeSpan.ToString()
	$createTriggerExpression += " -$parameterName $minutesTimeSpanAsString"
}

Export-ModuleMember -Function Get-ScheduledTaskNameAndPath
Export-ModuleMember -Function Get-AccountCredentialsToRunScheduledTaskAs
Export-ModuleMember -Function Get-WorkingDirectory
Export-ModuleMember -Function Get-ScheduledTaskTrigger