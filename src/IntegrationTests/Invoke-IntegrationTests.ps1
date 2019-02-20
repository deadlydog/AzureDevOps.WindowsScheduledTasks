# These tests create and manipulate real Scheduled Tasks on the localhost.
# The Scheduled Tasks it manipulates are isolated in their own directory, and get cleaned up when the tests are done.
#Requires -RunAsAdministrator

Process
{
	Describe 'Installing Scheduled Tasks' {
		Context 'When the task definition parameters are valid' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'For an inline definition with an AtStartup trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml definition with an AtStartup trigger, it gets created as expected.'
					scheduledTaskParameters = $XmlAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline definition with an AtLogOn trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineAtLogOnScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml definition with an AtLogOn trigger, it gets created as expected.'
					scheduledTaskParameters = $XmlAtLogOnScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline definition with a DateTime trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineDateTimeScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml definition with a DateTime trigger, it gets created as expected.'
					scheduledTaskParameters = $XmlDateTimeScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For a Weekly DateTime trigger on one day of the week, it gets created as expected.'
					scheduledTaskParameters = $WeeklyScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For a Weekly DateTime trigger on multiple days of the week, it gets created as expected.'
					scheduledTaskParameters = $WeeklyMultipleDaysScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_
				Assert-ScheduledTaskIsInstalledCorrectly @parameters

				# Cleanup Scheduled Task after installing it.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}
	}

	Describe 'Uninstalling Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is installed, it gets removed as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before removing it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsUninstalledCorrectly @parameters
			}
		}

		Context 'When the scheduled task to uninstall does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Uninstall-ScheduledTask -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $NeverInstalledScheduledTaskParameters.ScheduledTaskFullName
				$scheduledTask | Should -BeNullOrEmpty
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When uninstalling multiple scheduled tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $uninstallMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Act.
				$warningOutput = Uninstall-ScheduledTask -scheduledTaskParameters $uninstallMultipleTasksParameters 3>&1

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $uninstallMultipleTasksParameters.ScheduledTaskFullName
				$scheduledTask | Should -BeNullOrEmpty
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When uninstalling multiple scheduled tasks that do exist' {
			It 'Should uninstall all of the scheduled tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $uninstallMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Ensure multiple tasks exist before acting.
				Install-ScheduledTask -scheduledTaskParameters $InlineAtStartupScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $XmlAtStartupScheduledTaskParameters
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Uninstall-ScheduledTask -scheduledTaskParameters $uninstallMultipleTasksParameters

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTask | Should -BeNullOrEmpty
			}
		}
	}

	Describe 'Enabling Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is disabled, it gets enabled as expected.'
					scheduledTaskParameters = $DisabledScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already enabled, it stays enabled as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before enabling it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsEnabledCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the scheduled task to enable does not exist' {
			It 'Should log a an warning, but still continue' {
				# Act.
				$warningOutput = Enable-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When enabling multiple scheduled tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $enableMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Act.
				$warningOutput = Enable-ScheduledTaskCustom -scheduledTaskParameters $enableMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When enabling multiple scheduled tasks that do exist' {
			It 'Should enable all of the scheduled tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $enableMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Ensure multiple tasks exist before acting.
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $XmlAtStartupScheduledTaskParameters
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Enable-ScheduledTaskCustom -scheduledTaskParameters $enableMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.Settings.Enabled | Should -BeTrue
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $XmlAtStartupScheduledTaskParameters
			}
		}
	}

	Describe 'Disabling Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is enabled, it gets disabled as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already disabled, it stays disabled as expected.'
					scheduledTaskParameters = $DisabledScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before enabling it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsDisabledCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the scheduled task to disable does not exist' {
			It 'Should log a an warning, but still continue' {
				# Act.
				$warningOutput = Disable-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When disabling multiple scheduled tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $disableMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Act.
				$warningOutput = Disable-ScheduledTaskCustom -scheduledTaskParameters $disableMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When disabling multiple scheduled tasks that do exist' {
			It 'Should disable all of the scheduled tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $disableMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = $false
				}

				# Ensure multiple tasks exist before acting
				Install-ScheduledTask -scheduledTaskParameters $XmlAtStartupScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Disable-ScheduledTaskCustom -scheduledTaskParameters $disableMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.Settings.Enabled | Should -BeFalse
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $XmlAtStartupScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
			}
		}
	}

	# This should be the last to to run to ensure all test tasks are uninstalled to keep everything nice and clean.
	Write-Output "Uninstalling any lingering Scheduled Tasks. Typically nothing should be left to uninstall at this point."
	Uninstall-AllTestScheduledTasks
}

Begin
{
	# Turn on Strict Mode to help catch syntax-related errors.
	Set-StrictMode -Version Latest

	# Global Variables
	[string] $CommonScheduledTaskPath = '\WindowsScheduledTasksTests\'
	[string] $XmlDefinitionsDirectoryPath = [string]::Empty # Populated dynamically below.
	[string] $InstallScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.
	[string] $UninstallScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.
	[string] $EnableScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.
	[string] $DisableScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.

	# Build paths to the scripts to run.
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot
	[string] $srcDirectoryPath = Split-Path -Path $THIS_SCRIPTS_DIRECTORY_PATH -Parent

	[string] $XmlDefinitionsDirectoryPath = Join-Path -Path $srcDirectoryPath -ChildPath 'IntegrationTests\ScheduledTaskXmlDefinitions'
	if (!(Test-Path -Path $XmlDefinitionsDirectoryPath -PathType Container))
	{
		throw "Could not locate the TestData directory at the expected path '$XmlDefinitionsDirectoryPath'."
	}

	[string] $installScheduledTaskEntryPointScriptName = 'Install-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $InstallScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $installScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($InstallScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$installScheduledTaskEntryPointScriptName' file."
	}

	[string] $uninstallScheduledTaskEntryPointScriptName = 'Uninstall-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $UninstallScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $uninstallScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($UninstallScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$uninstallScheduledTaskEntryPointScriptName' file."
	}

	[string] $enableScheduledTaskEntryPointScriptName = 'Enable-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $EnableScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $enableScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($EnableScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$enableScheduledTaskEntryPointScriptName' file."
	}

	[string] $disableScheduledTaskEntryPointScriptName = 'Disable-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $DisableScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $disableScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($DisableScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$disableScheduledTaskEntryPointScriptName' file."
	}

	[string] $userInputToScheduledTaskMapperScriptName = 'UserInputToScheduledTaskMapper.psm1'
	[string] $userInputToScheduledTaskMapperScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $userInputToScheduledTaskMapperScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($userInputToScheduledTaskMapperScriptPath))
	{
		throw "Could not locate the '$userInputToScheduledTaskMapperScriptName' file."
	}
	Import-Module -Name $userInputToScheduledTaskMapperScriptPath -Force

	function Install-ScheduledTask([hashtable] $scheduledTaskParameters)
	{
		Invoke-Expression -Command "& $InstallScheduledTaskEntryPointScriptPath @scheduledTaskParameters"
	}

	function Uninstall-ScheduledTask([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $uninstallTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $UninstallScheduledTaskEntryPointScriptPath @uninstallTaskParameters"
	}

	# Enable-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Enable-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $enableTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $EnableScheduledTaskEntryPointScriptPath @enableTaskParameters"
	}

	# Disable-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Disable-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $disableTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $DisableScheduledTaskEntryPointScriptPath @disableTaskParameters"
	}

	function Uninstall-AllTestScheduledTasks
	{
		[hashtable] $uninstallTaskParameters = @{
			ScheduledTaskFullName = "$CommonScheduledTaskPath*"
		}
		Invoke-Expression -Command "& $UninstallScheduledTaskEntryPointScriptPath @uninstallTaskParameters"
	}

	function Get-ScheduledTaskByFullName([string] $taskFullName)
	{
		$taskPathAndName = Get-ScheduledTaskNameAndPath -fullTaskName $taskFullName
		$scheduledTask = $null
		$scheduledTask = Get-ScheduledTask -TaskPath $taskPathAndName.Path -TaskName $taskPathAndName.Name -ErrorAction SilentlyContinue
		return $scheduledTask
	}

	function Get-XmlDefinitionPath([string] $fileName)
	{
		Join-Path -Path $XmlDefinitionsDirectoryPath -ChildPath $fileName
	}

	function Assert-ScheduledTaskIsInstalledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Install-ScheduledTask -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Install-ScheduledTask -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
		}
	}

	function Assert-ScheduledTaskIsUninstalledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Uninstall-ScheduledTask -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Uninstall-ScheduledTask -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -BeNullOrEmpty
		}
	}

	function Assert-ScheduledTaskIsEnabledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Enable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Enable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.Settings.Enabled | Should -BeTrue
		}
	}

	function Assert-ScheduledTaskIsDisabledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Disable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Disable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.Settings.Enabled | Should -BeFalse
		}
	}

	# Scheduled Task that should never be installed, as it's used to run tests against Scheduled Tasks that are not installed.
	[hashtable] $NeverInstalledScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-')
		ScheduledTaskDescription = 'A test task.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an Inline definition and an AtStartup trigger.
	[hashtable] $InlineAtStartupScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineAtStartup')
		ScheduledTaskDescription = 'A test task set to trigger At Startup.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an XML definition and an AtStartup trigger.
	[hashtable] $XmlAtStartupScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'ImportFromXmlFile' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'AtStartup.xml'
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-XmlAtStartup')
		ScheduledTaskDescription = 'A test task set to trigger At Startup.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an Inline definition and an AtLogOn trigger.
	[hashtable] $InlineAtLogOnScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineAtLogOn')
		ScheduledTaskDescription = 'A test task set to trigger At Log On.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtLogOn' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an XML definition and an AtLogOn trigger.
	[hashtable] $XmlAtLogOnScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'ImportFromXmlFile' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'AtLogOn.xml'
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineAtLogOn')
		ScheduledTaskDescription = 'A test task set to trigger At Log On.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtLogOn' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an Inline definition and an DateTime trigger.
	[hashtable] $InlineDateTimeScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineDateTime')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an XML definition and a DateTime trigger.
	[hashtable] $XmlDateTimeScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'ImportFromXmlFile' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'DateTime.xml'
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-XmlDateTime')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	[hashtable] $DisabledScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-DisabledTask')
		ScheduledTaskDescription = 'A test task that gets installed as disabled.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'false'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	[hashtable] $WeeklyScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-Weekly')
		ScheduledTaskDescription = 'A test task.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Weekly' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = '1'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	[hashtable] $WeeklyMultipleDaysScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-WeeklyMultipleDays')
		ScheduledTaskDescription = 'A test task.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '01/01/2050 01:00:00'
		DateTimeScheduleFrequencyOptions = 'Weekly' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = '1'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}
}