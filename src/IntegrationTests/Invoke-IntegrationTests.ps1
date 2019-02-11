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

	# This should be the last to to run to ensure all test tasks are uninstalled to keep everything nice and clean.
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
		ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false
		ShouldScheduledTaskRunRepeatedly = $false
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabled = $true
		ShouldScheduledTaskRunWithHighestPrivileges = $false
		ShouldScheduledTaskRunAfterInstall = $false
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
		ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false
		ShouldScheduledTaskRunRepeatedly = $false
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabled = $true
		ShouldScheduledTaskRunWithHighestPrivileges = $false
		ShouldScheduledTaskRunAfterInstall = $false
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
		ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false
		ShouldScheduledTaskRunRepeatedly = $false
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabled = $true
		ShouldScheduledTaskRunWithHighestPrivileges = $false
		ShouldScheduledTaskRunAfterInstall = $false
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
		ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false
		ShouldScheduledTaskRunRepeatedly = $false
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabled = $true
		ShouldScheduledTaskRunWithHighestPrivileges = $false
		ShouldScheduledTaskRunAfterInstall = $false
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}

	# Scheduled Task with an XML definition and an AtLogOn trigger.
	[hashtable] $XmlAtLogOnScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'ImportFromXmlFile' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom =  Get-XmlDefinitionPath -fileName 'AtLogOn.xml'
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
		ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = $false
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays = $false
		ShouldScheduledTaskRunRepeatedly = $false
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabled = $true
		ShouldScheduledTaskRunWithHighestPrivileges = $false
		ShouldScheduledTaskRunAfterInstall = $false
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = $false
	}
}