# Import the module to test.
Set-StrictMode -Version Latest
[string] $THIS_SCRIPTS_PATH = $PSCommandPath
[string] $moduleFilePathToTest = $THIS_SCRIPTS_PATH.Replace('.Tests.ps1', '.psm1') | Resolve-Path
Write-Verbose "Importing the module file '$moduleFilePathToTest' to run tests against it." -Verbose
Import-Module -Name $moduleFilePathToTest -Force

Describe 'Get-ScheduledTaskNameAndPath' {
	Context 'When given a valid task name at the root level' {
		It 'Returns back the correct Name and Path' -TestCases @(
			@{ fullTaskName = 'MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\' }
			@{ fullTaskName = '\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\' }
		) {
			param
			(
				[string] $fullTaskName,
				[string] $expectedTaskName,
				[string] $expectedTaskPath
			)
			$result = Get-ScheduledTaskNameAndPath -fullTaskName $fullTaskName

			$result.Name | Should -Be $expectedTaskName
			$result.Path | Should -Be $expectedTaskPath
		}
	}

	Context 'When given a valid task name several directories deep' {
		It 'Returns back the correct Name and Path' -TestCases @(
			@{ fullTaskName = 'Level1\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\' }
			@{ fullTaskName = '\Level1\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\' }
			@{ fullTaskName = 'Level1\Level2\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\Level2\' }
			@{ fullTaskName = '\Level1\Level2\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\Level2\' }
			@{ fullTaskName = 'Level1\Level2\Level3\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\Level2\Level3\' }
			@{ fullTaskName = '\Level1\Level2\Level3\MyTask'; expectedTaskName = 'MyTask'; expectedTaskPath = '\Level1\Level2\Level3\' }
		) {
			param
			(
				[string] $fullTaskName,
				[string] $expectedTaskName,
				[string] $expectedTaskPath
			)
			$result = Get-ScheduledTaskNameAndPath -fullTaskName $fullTaskName

			$result.Name | Should -Be $expectedTaskName
			$result.Path | Should -Be $expectedTaskPath
		}
	}
}

Describe 'Get-AccountCredentialsToRunScheduledTaskAs' {
	Context 'When requested to run as a service account' {
		It 'Returns back the correct account with a blank password' -TestCases @(
			@{ runAsOption = 'System'; username = ''; password = ''; expectedUsername = 'NT AUTHORITY\SYSTEM'; expectedPassword = '' }
			@{ runAsOption = 'System'; username = 'user'; password = 'pass'; expectedUsername = 'NT AUTHORITY\SYSTEM'; expectedPassword = '' }
			@{ runAsOption = 'LocalService'; username = ''; password = ''; expectedUsername = 'NT AUTHORITY\LOCALSERVICE'; expectedPassword = '' }
			@{ runAsOption = 'LocalService'; username = 'user'; password = 'pass'; expectedUsername = 'NT AUTHORITY\LOCALSERVICE'; expectedPassword = '' }
			@{ runAsOption = 'NetworkService'; username = ''; password = ''; expectedUsername = 'NT AUTHORITY\NETWORKSERVICE'; expectedPassword = '' }
			@{ runAsOption = 'NetworkService'; username = 'user'; password = 'pass'; expectedUsername = 'NT AUTHORITY\NETWORKSERVICE'; expectedPassword = '' }
		) {
			param
			(
				[string] $runAsOption,
				[string] $username,
				[string] $password,
				[string] $expectedUsername,
				[string] $expectedPassword
			)
			$result = Get-AccountCredentialsToRunScheduledTaskAs -scheduldTaskAccountToRunAsOptions $runAsOption -customAccountToRunScheduledTaskAsUsername $username -customAccountToRunScheduledTaskAsPassword $password

			$result.Username | Should -Be $expectedUsername
			$result.Password | Should -Be $expectedPassword
		}
	}

	Context 'When requested to run as a custom user account' {
		It 'Returns back the provided user credentials' -TestCases @(
			@{ runAsOption = 'CustomAccount'; username = ''; password = ''; expectedUsername = ''; expectedPassword = '' }
			@{ runAsOption = 'CustomAccount'; username = 'user'; password = ''; expectedUsername = 'user'; expectedPassword = '' }
			@{ runAsOption = 'CustomAccount'; username = ''; password = 'pass'; expectedUsername = ''; expectedPassword = 'pass' }
			@{ runAsOption = 'CustomAccount'; username = 'user'; password = 'pass'; expectedUsername = 'user'; expectedPassword = 'pass' }
		) {
			param
			(
				[string] $runAsOption,
				[string] $username,
				[string] $password,
				[string] $expectedUsername,
				[string] $expectedPassword
			)
			$result = Get-AccountCredentialsToRunScheduledTaskAs -scheduldTaskAccountToRunAsOptions $runAsOption -customAccountToRunScheduledTaskAsUsername $username -customAccountToRunScheduledTaskAsPassword $password

			$result.Username | Should -Be $expectedUsername
			$result.Password | Should -Be $expectedPassword
		}
	}
}

Describe 'Get-WorkingDirectory' {
	function Assert-GetWorkingDirectoryReturnsCorrectResult
	{
		param
		(
			[string] $testDescription,
			[string] $workingDirectoryOption,
			[string] $customWorkingDirectory,
			[string] $applicationPath,
			[string] $expectedWorkingDirectory
		)

		It $testDescription {
			$result = Get-WorkingDirectory -workingDirectoryOption $workingDirectoryOption -customWorkingDirectory $customWorkingDirectory -applicationPath $applicationPath

			$result | Should -Be $expectedWorkingDirectory
		}
	}

	Context 'When requesting the Application Directory as the working directory' {
		[hashtable[]] $tests = @(
			@{	testDescription = 'Returns the applications directory when no Custom Working Directory is given'
				workingDirectoryOption = 'ApplicationDirectory'; customWorkingDirectory = ''; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\AppDirectory'
			}
			@{	testDescription = 'Returns the applications directory when a Custom Working Directory is given'
				workingDirectoryOption = 'ApplicationDirectory'; customWorkingDirectory = 'C:\SomeDirectory'; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\AppDirectory'
			}
		)
		$tests | ForEach-Object {
			[hashtable] $parameters = $_
			Assert-GetWorkingDirectoryReturnsCorrectResult @parameters
		}
	}

	Context 'When requesting a custom working directory' {
		[hashtable[]] $tests = @(
			@{	testDescription = 'Returns the custom directory'
				workingDirectoryOption = 'CustomDirectory'; customWorkingDirectory = 'C:\SomeDirectory'; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\SomeDirectory'
			}
			@{	testDescription = 'Returns the custom directory even if its blank'
				workingDirectoryOption = 'CustomDirectory'; customWorkingDirectory = ''; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = ''
			}
		)
		$tests | ForEach-Object {
			[hashtable] $parameters = $_
			Assert-GetWorkingDirectoryReturnsCorrectResult @parameters
		}
	}
}

Describe 'Get-ScheduledTaskAction' {
	function Assert-GetScheduledTaskActionReturnsCorrectResult
	{
		param
		(
			[string] $testDescription,
			[string] $applicationPathToRun,
			[string] $applicationArguments,
			[string] $workingDirectory,
			[string] $expectedApplicationPathToRun,
			[string] $expectedApplicationArguments,
			[string] $expectedWorkingDirectory,
			[bool] $expectExceptionToBeThrown
		)

		It $testDescription {
			[string] $expression = "Get-ScheduledTaskAction -applicationPathToRun `"$applicationPathToRun`" -applicationArguments `"$applicationArguments`" -workingDirectory `"$workingDirectory`""

			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Invoke-Expression -Command $expression } | Should -Throw
			}
			else
			{
				# Act.
				$result = Invoke-Expression -Command $expression

				# Assert.
				$result | Should -Not -BeNullOrEmpty
				$result.Execute | Should -Be $expectedApplicationPathToRun

				# We need to explicitly check for empty string instead of null because we wrap the "null" parameter in a string and it turns into an empty string.
				if ([string]::IsNullOrWhiteSpace($expectedApplicationArguments))
				{ $result.Arguments | Should -BeNullOrEmpty }
				else { $result.Arguments | Should -Be $expectedApplicationArguments }

				if ([string]::IsNullOrWhiteSpace($expectedWorkingDirectory))
				{ $result.WorkingDirectory | Should -BeNullOrEmpty }
				else
				{ $result.WorkingDirectory | Should -Be $expectedWorkingDirectory }
			}
		}
	}

	[string] $validApplicationPath = 'C:\SomeDirectory\SomeApp.exe'
	[string] $validApplicationArguments = '/someArg value'
	[string] $validWorkingDirectory = 'C:\SomeDirectory'

	[hashtable[]] $tests = @(
		@{	testDescription = 'When all parameters are provided with valid values, it should have the specified values.'
			applicationPathToRun = $validApplicationPath; applicationArguments = $validApplicationArguments; workingDirectory = $validWorkingDirectory
			expectedApplicationPathToRun = $validApplicationPath; expectedApplicationArguments = $validApplicationArguments; expectedWorkingDirectory = $validWorkingDirectory
			expectExceptionToBeThrown = $false
		}
		@{	testDescription = 'When no Application Path is supplied, it throws an exception.'
			applicationPathToRun = ''; applicationArguments = $validApplicationArguments; workingDirectory = $validWorkingDirectory
			expectedApplicationPathToRun = ''; expectedApplicationArguments = $validApplicationArguments; expectedWorkingDirectory = $validWorkingDirectory
			expectExceptionToBeThrown = $true
		}
		@{	testDescription = 'When no Arguments are provided, it should not have any specified.'
			applicationPathToRun = $validApplicationPath; applicationArguments = ''; workingDirectory = $validWorkingDirectory
			expectedApplicationPathToRun = $validApplicationPath; expectedApplicationArguments = $null; expectedWorkingDirectory = $validWorkingDirectory
			expectExceptionToBeThrown = $false
		}
		@{	testDescription = 'When no Working Directory is provided, it should not have one specified.'
			applicationPathToRun = $validApplicationPath; applicationArguments = $validApplicationArguments; workingDirectory = ''
			expectedApplicationPathToRun = $validApplicationPath; expectedApplicationArguments = $validApplicationArguments; expectedWorkingDirectory = $null
			expectExceptionToBeThrown = $false
		}
	)
	$tests | ForEach-Object {
		[hashtable] $parameters = $_
		Assert-GetScheduledTaskActionReturnsCorrectResult @parameters
	}
}

Describe 'Get-ScheduledTaskTrigger' {
	function Assert-GetScheduledTaskTriggerReturnsCorrectResult
	{
		param
		(
			[string] $testDescription,
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
			[string] $scheduleStartTimeRandomDelayInMinutes,
			[string] $expectedAtLogOnTriggerUsername,
			[string] $expectedDateTimeScheduleStartTime,
			[string] $expectedDateTimeScheduleFrequencyDailyInterval,
			[string] $expectedDateTimeScheduleFrequencyWeeklyInterval,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnMondays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnThursdays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnFridays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays,
			[bool] $expectedShouldDateTimeScheduleFrequencyWeeklyRunOnSundays,
			[string] $expectedScheduleRepetitionIntervalInMinutes,
			[string] $expectedScheduleRepetitionDurationInMinutes,
			[string] $expectedScheduleStartTimeRandomDelayInMinutes,
			[bool] $expectExceptionToBeThrown
		)

		It $testDescription {
			[string] $expression = "Get-ScheduledTaskTrigger -triggerType $triggerType -atLogOnTriggerUsername `"$atLogOnTriggerUsername`" -dateTimeScheduleStartTime `"$dateTimeScheduleStartTime`" -dateTimeScheduleFrequencyOptions `"$dateTimeScheduleFrequencyOptions`" -dateTimeScheduleFrequencyDailyInterval `"$dateTimeScheduleFrequencyDailyInterval`" -dateTimeScheduleFrequencyWeeklyInterval `"$dateTimeScheduleFrequencyWeeklyInterval`" -shouldDateTimeScheduleFrequencyWeeklyRunOnMondays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnMondays -shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays -shouldDateTimeScheduleFrequencyWeeklyRunOnFridays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnFridays -shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays -shouldDateTimeScheduleFrequencyWeeklyRunOnSundays `$$shouldDateTimeScheduleFrequencyWeeklyRunOnSundays -shouldScheduledTaskRunRepeatedly `$$shouldScheduledTaskRunRepeatedly -scheduleRepetitionIntervalInMinutes `"$scheduleRepetitionIntervalInMinutes`" -scheduleRepetitionDurationInMinutes `"$scheduleRepetitionDurationInMinutes`" -scheduleStartTimeRandomDelayInMinutes `"$scheduleStartTimeRandomDelayInMinutes`""

			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Invoke-Expression -Command $expression } | Should -Throw
			}
			else
			{
				# Act.
				$result = Invoke-Expression -Command $expression

				# Assert.
				$result | Should -Not -BeNullOrEmpty
				# The $result object doesn't expose the properties we need to check and validate that they were set properly, so all we can really do is make sure an exception wasn't thrown and the result object is not null.
			}
		}
	}

	[string] $validAtLogOnUsername = 'Dan'
	[string] $validDateTimeStartTime = '3am'

	Context 'When using an At Startup trigger' {
		[hashtable[]] $tests = @(
			@{	testDescription = 'When all parameters are provided with valid values, it should not throw an exception.'
				triggerType = 'AtStartup'
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
			@{	testDescription = 'When an invalid Trigger Type is specified, it should throw an exception.'
				triggerType = 'InvalidType'
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $true
			}
		)
		$tests | ForEach-Object {
			[hashtable] $parameters = $_
			Assert-GetScheduledTaskTriggerReturnsCorrectResult @parameters
		}
	}

	Context 'When using an At Logon trigger' {
		[hashtable[]] $tests = @(
			@{	testDescription = 'When all parameters are provided with valid values, it should not throw an exception.'
				triggerType = 'AtLogOn'
				atLogOnTriggerUsername = $validAtLogOnUsername
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
		)
		$tests | ForEach-Object {
			[hashtable] $parameters = $_
			Assert-GetScheduledTaskTriggerReturnsCorrectResult @parameters
		}
	}

	Context 'When using a Date Time trigger' {
		[hashtable[]] $tests = @(
			@{	testDescription = 'When all parameters are provided with valid values for a Once frequency, it should not throw an exception.'
				triggerType = 'DateTime'
				dateTimeScheduleStartTime = $validDateTimeStartTime
				dateTimeScheduleFrequencyOptions = 'Once'
				dateTimeScheduleFrequencyDailyInterval = ''
				dateTimeScheduleFrequencyWeeklyInterval = ''
				shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false;shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false;
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
			@{	testDescription = 'When all parameters are provided with valid values for a Daily frequency, it should not throw an exception.'
				triggerType = 'DateTime'
				dateTimeScheduleStartTime = $validDateTimeStartTime
				dateTimeScheduleFrequencyOptions = 'Daily'
				dateTimeScheduleFrequencyDailyInterval = '1'
				dateTimeScheduleFrequencyWeeklyInterval = ''
				shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false;shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false;
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
			@{	testDescription = 'When all parameters are provided with valid values for a Weekly frequency, including a weekday is specified, it should not throw an exception.'
				triggerType = 'DateTime'
				dateTimeScheduleStartTime = $validDateTimeStartTime
				dateTimeScheduleFrequencyOptions = 'Weekly'
				dateTimeScheduleFrequencyDailyInterval = ''
				dateTimeScheduleFrequencyWeeklyInterval = '1'
				shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false;
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
			@{	testDescription = 'When all parameters are provided with valid values for a Weekly frequency and several weekdays are specified, it should not throw an exception.'
				triggerType = 'DateTime'
				dateTimeScheduleStartTime = $validDateTimeStartTime
				dateTimeScheduleFrequencyOptions = 'Weekly'
				dateTimeScheduleFrequencyDailyInterval = ''
				dateTimeScheduleFrequencyWeeklyInterval = '1'
				shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $true; shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $true;
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $false
			}
			@{	testDescription = 'When a Weekly frequency is specified, but no weekdays are specified it should throw an exception.'
				triggerType = 'DateTime'
				dateTimeScheduleStartTime = $validDateTimeStartTime
				dateTimeScheduleFrequencyOptions = 'Weekly'
				dateTimeScheduleFrequencyDailyInterval = ''
				dateTimeScheduleFrequencyWeeklyInterval = '1'
				shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false; shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false;
				shouldScheduledTaskRunRepeatedly = $false; scheduleRepetitionIntervalInMinutes = ''; scheduleRepetitionDurationInMinutes = ''
				scheduleStartTimeRandomDelayInMinutes = ''
				expectExceptionToBeThrown = $true
			}
		)
		$tests | ForEach-Object {
			[hashtable] $parameters = $_
			Assert-GetScheduledTaskTriggerReturnsCorrectResult @parameters
		}
	}
}

Describe 'Get-ScheduledTaskSettings' {
	Context 'When requesting the task to be disabled' {
		It 'Should be disabled in the settings' {
			# Arrange.
			$shouldBeEnabled = $false

			# Act.
			$result = Get-ScheduledTaskSettings -shouldBeEnabled $shouldBeEnabled

			# Assert.
			$result | Should -Not -BeNullOrEmpty
			$result.Enabled | Should -Be $shouldBeEnabled
		}
	}

	Context 'When requesting the task to be enabled' {
		It 'Should be enabled in the settings' {
			# Arrange.
			$shouldBeEnabled = $true

			# Act.
			$result = Get-ScheduledTaskSettings -shouldBeEnabled $shouldBeEnabled

			# Assert.
			$result | Should -Not -BeNullOrEmpty
			$result.Enabled | Should -Be $shouldBeEnabled
		}
	}
}

Describe 'Get-ScheduledTaskRunLevel' {
	Context 'When highest level privileges are not requested' {
		It 'Should return the Limited level' {
			$result = Get-ScheduledTaskRunLevel -shouldScheduledTaskRunWithHighestPrivileges $false
			$result | Should -Be 'Limited'
		}
	}

	Context 'When highest level privileges are requested' {
		It 'Should return the Highest level' {
			$result = Get-ScheduledTaskRunLevel -shouldScheduledTaskRunWithHighestPrivileges $true
			$result | Should -Be 'Highest'
		}
	}
}