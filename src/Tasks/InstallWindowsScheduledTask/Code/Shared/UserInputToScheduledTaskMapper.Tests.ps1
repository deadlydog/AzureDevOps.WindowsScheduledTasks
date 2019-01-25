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

# # Commenting out for now as these are duplicated below in a different coding style, and I'm not certain which one I want to go with yet.
# Describe 'Get-WorkingDirectory' {
# 	function Assert-GetWorkingDirectoryReturnsCorrectResult
# 	{
# 		param
# 		(
# 			[string] $workingDirectoryOption,
# 			[string] $customWorkingDirectory,
# 			[string] $applicationPath,
# 			[string] $expectedWorkingDirectory
# 		)

# 		$result = Get-WorkingDirectory -workingDirectoryOption $workingDirectoryOption -customWorkingDirectory $customWorkingDirectory -applicationPath $applicationPath

# 		$result | Should -Be $expectedWorkingDirectory
# 	}

# 	Context 'When requesting the Application Directory as the working directory' {
# 		It 'Returns the applications directory when no Custom Working Directory is given' {
# 			Assert-GetWorkingDirectoryReturnsCorrectResult -workingDirectoryOption 'ApplicationDirectory' -customWorkingDirectory '' -applicationPath 'C:\AppDirectory\MyApp.exe' -expectedWorkingDirectory 'C:\AppDirectory'
# 		}
# 		It 'Returns the applications directory when a Custom Working Directory is given' {
# 			Assert-GetWorkingDirectoryReturnsCorrectResult -workingDirectoryOption 'ApplicationDirectory' -customWorkingDirectory 'C:\SomeDirectory' -applicationPath 'C:\AppDirectory\MyApp.exe' -expectedWorkingDirectory 'C:\AppDirectory'
# 		}
# 	}

# 	Context 'When requesting a custom working directory' {
# 		It 'Returns the custom directory' {
# 			Assert-GetWorkingDirectoryReturnsCorrectResult -workingDirectoryOption 'CustomDirectory' -customWorkingDirectory 'C:\SomeDirectory' -applicationPath 'C:\AppDirectory\MyApp.exe' -expectedWorkingDirectory 'C:\SomeDirectory'
# 		}
# 		It 'Returns the custom directory even if its blank' {
# 			Assert-GetWorkingDirectoryReturnsCorrectResult -workingDirectoryOption 'CustomDirectory' -customWorkingDirectory '' -applicationPath 'C:\AppDirectory\MyApp.exe' -expectedWorkingDirectory ''
# 		}
# 	}
# }

# # Commenting out for now as these are duplicated below in a different coding style, and I'm not certain which one I want to go with yet.
# Describe 'Get-WorkingDirectory' {
# 	Context 'When requesting the Application Directory' {
# 		It 'Returns the correct working directory' -TestCases @(
# 			@{ workingDirectoryOption = 'ApplicationDirectory'; customWorkingDirectory = ''; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\AppDirectory' }
# 			@{ workingDirectoryOption = 'ApplicationDirectory'; customWorkingDirectory = 'C:\SomeDirectory'; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\AppDirectory' }
# 		) {
# 			param
# 			(
# 				[string] $workingDirectoryOption,
# 				[string] $customWorkingDirectory,
# 				[string] $applicationPath,
# 				[string] $expectedWorkingDirectory
# 			)

# 			$result = Get-WorkingDirectory -workingDirectoryOption $workingDirectoryOption -customWorkingDirectory $customWorkingDirectory -applicationPath $applicationPath

# 			$result | Should -Be $expectedWorkingDirectory
# 		}
# 	}

# 	Context 'When requesting a Custom Directory' {
# 		It 'Returns the correct working directory' -TestCases @(
# 			@{ workingDirectoryOption = 'CustomDirectory'; customWorkingDirectory = ''; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = '' }
# 			@{ workingDirectoryOption = 'CustomDirectory'; customWorkingDirectory = 'C:\SomeDirectory'; applicationPath = 'C:\AppDirectory\MyApp.exe'; expectedWorkingDirectory = 'C:\SomeDirectory' }
# 		) {
# 			param
# 			(
# 				[string] $workingDirectoryOption,
# 				[string] $customWorkingDirectory,
# 				[string] $applicationPath,
# 				[string] $expectedWorkingDirectory
# 			)

# 			$result = Get-WorkingDirectory -workingDirectoryOption $workingDirectoryOption -customWorkingDirectory $customWorkingDirectory -applicationPath $applicationPath

# 			$result | Should -Be $expectedWorkingDirectory
# 		}
# 	}
# }

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