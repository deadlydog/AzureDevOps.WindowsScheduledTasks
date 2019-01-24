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
			$sut = Get-ScheduledTaskNameAndPath -fullTaskName $fullTaskName

			$sut.Name | Should -Be $expectedTaskName
			$sut.Path | Should -Be $expectedTaskPath
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
			$sut = Get-ScheduledTaskNameAndPath -fullTaskName $fullTaskName

			$sut.Name | Should -Be $expectedTaskName
			$sut.Path | Should -Be $expectedTaskPath
		}
	}

}