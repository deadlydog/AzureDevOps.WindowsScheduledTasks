Process
{
	Install-InlineAtStartupScheduledTask
}

Begin
{
	# Turn on Strict Mode to help catch syntax-related errors.
	Set-StrictMode -Version Latest

	# Global Variables
	[string] $CommonScheduledTaskPath = '\WindowsScheduledTasksTests\'
	[string] $InstallScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.

	# Build path to the script to run.
	[string] $fileNameToRetrieveFullPathOf = 'Install-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot
	[string] $srcDirectoryPath = Split-Path -Path $THIS_SCRIPTS_DIRECTORY_PATH -Parent
	[string] $InstallScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $fileNameToRetrieveFullPathOf | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($InstallScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$fileNameToRetrieveFullPathOf' file."
	}

	# This function is not intended to be called, but can be cloned for creating new install functions, as it has all possible parameters defined for you.
	function Install-ScheduledTaskTemplateFunction
	{
		& $InstallScheduledTaskEntryPointScriptPath `
			-ScheduledTaskDefinitionSource 'Inline' ` # 'ImportFromXmlFile', 'Inline'
			-ScheduledTaskXmlFileToImportFrom '' `
			-ScheduledTaskFullName ($CommonScheduledTaskPath + 'Test-') `
			-ScheduledTaskDescription 'A test task.' `
			-ApplicationPathToRun 'C:\Dummy.exe' `
			-ApplicationArguments '' `
			-WorkingDirectoryOptions 'ApplicationDirectory' ` # 'ApplicationDirectory', 'CustomDirectory'
			-CustomWorkingDirectory '' `
			-ScheduleTriggerType 'AtStartup' ` # 'DateTime', 'AtLogOn', 'AtStartup'
			-DateTimeScheduleStartTime '' `
			-DateTimeScheduleFrequencyOptions '' ` # 'Once', 'Daily', 'Weekly'
			-DateTimeScheduleFrequencyDailyInterval '' `
			-DateTimeScheduleFrequencyWeeklyInterval '' `
			-ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays $false `
			-ShouldScheduledTaskRunRepeatedly $false `
			-ScheduleRepetitionIntervalInMinutes '' `
			-ScheduleRepetitionDurationInMinutes '' `
			-ScheduleStartTimeRandomDelayInMinutes '' `
			-ScheduledTaskAccountToRunAsOptions 'LocalService' ` # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
			-CustomAccountToRunScheduledTaskAsUsername '' `
			-CustomAccountToRunScheduledTaskAsPassword '' `
			-ShouldScheduledTaskBeEnabled $true `
			-ShouldScheduledTaskRunWithHighestPrivileges $false `
			-ShouldScheduledTaskRunAfterInstall $false `
			-ComputerNames '' `
			-Username '' `
			-Password '' `
			-UseCredSsp $false
	}

	function Install-InlineAtStartupScheduledTask
	{
		& $InstallScheduledTaskEntryPointScriptPath `
			-ScheduledTaskDefinitionSource 'Inline' ` # 'ImportFromXmlFile', 'Inline'
			-ScheduledTaskXmlFileToImportFrom '' `
			-ScheduledTaskFullName ($CommonScheduledTaskPath + 'Test-InlineAtStartup') `
			-ScheduledTaskDescription 'A test task set to trigger At Startup.' `
			-ApplicationPathToRun 'C:\Dummy.exe' `
			-ApplicationArguments '' `
			-WorkingDirectoryOptions 'ApplicationDirectory' ` # 'ApplicationDirectory', 'CustomDirectory'
			-CustomWorkingDirectory '' `
			-ScheduleTriggerType 'AtStartup' ` # 'DateTime', 'AtLogOn', 'AtStartup'
			-DateTimeScheduleStartTime '' `
			-DateTimeScheduleFrequencyOptions '' ` # 'Once', 'Daily', 'Weekly'
			-DateTimeScheduleFrequencyDailyInterval '' `
			-DateTimeScheduleFrequencyWeeklyInterval '' `
			-ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnThursday $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays $false `
			-ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays $false `
			-ShouldScheduledTaskRunRepeatedly $false `
			-ScheduleRepetitionIntervalInMinutes '' `
			-ScheduleRepetitionDurationInMinutes '' `
			-ScheduleStartTimeRandomDelayInMinutes '' `
			-ScheduledTaskAccountToRunAsOptions 'LocalService' ` # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
			-CustomAccountToRunScheduledTaskAsUsername '' `
			-CustomAccountToRunScheduledTaskAsPassword '' `
			-ShouldScheduledTaskBeEnabled $true `
			-ShouldScheduledTaskRunWithHighestPrivileges $false `
			-ShouldScheduledTaskRunAfterInstall $false `
			-ComputerNames '' `
			-Username '' `
			-Password '' `
			-UseCredSsp $false
	}
}