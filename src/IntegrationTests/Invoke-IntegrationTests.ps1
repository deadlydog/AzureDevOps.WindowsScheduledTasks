Process
{
	Describe 'Installing Scheduled Tasks' {
		Context 'When the task definition parameters are valid' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'For an inline definition with an AtStartup trigger, it should get created as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml definition with an AtStartup trigger, it should get created as expected.'
					scheduledTaskParameters = $XmlAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_
				Assert-ScheduledTaskWasInstalledCorrectly @parameters
			}
		}
	}

	Uninstall-ScheduledTask -scheduledTaskParameters $InlineAtStartupScheduledTaskParameters

	# Ensure all test tasks are uninstalled to keep everything nice and clean.
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
		$uninstallTaskParameters = @{
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
		$uninstallTaskParameters = @{
			ScheduledTaskFullName = "$CommonScheduledTaskPath*"
		}
		Invoke-Expression -Command "& $UninstallScheduledTaskEntryPointScriptPath @uninstallTaskParameters"
	}

	function Get-ScheduledTaskByFullName([string] $taskFullName)
	{
		$taskPathAndName = Get-ScheduledTaskNameAndPath -fullTaskName $taskFullName
		$scheduledTask = Get-ScheduledTask -TaskPath $taskPathAndName.Path -TaskName $taskPathAndName.Name
		return $scheduledTask
	}

	function Assert-ScheduledTaskWasInstalledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Invoke-Expression -Command $expression } | Should -Throw
				return
			}

			# Act.
			Install-ScheduledTask -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
		}
	}

	# This template is intended to be cloned for creating new Scheduled Task definitions, as it has all possible parameters defined for you.
	[hashtable] $TemplateScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-')
		ScheduledTaskDescription = 'A test task.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
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

	[hashtable] $XmlAtStartupScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'ImportFromXmlFile' # 'ImportFromXmlFile', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Join-Path -Path $XmlDefinitionsDirectoryPath -ChildPath 'AtStartup.xml'
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-XmlAtStartup')
		ScheduledTaskDescription = 'A test task set to trigger At Startup.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtStartup' # 'DateTime', 'AtLogOn', 'AtStartup'
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
}