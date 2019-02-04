# Import the module to test.
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
				{ $results.WorkingDirectory | Should -BeNullOrEmpty }
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
		@{	testDescription = 'When no arguments are provided, it should not have any specified.'
			applicationPathToRun = $validApplicationPath; applicationArguments = ''; workingDirectory = $validWorkingDirectory
			expectedApplicationPathToRun = $validApplicationPath; expectedApplicationArguments = $null; expectedWorkingDirectory = $validWorkingDirectory
			expectExceptionToBeThrown = $false
		}
		@{	testDescription = 'When no working directory is provided, it should not have a working directory specified.'
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