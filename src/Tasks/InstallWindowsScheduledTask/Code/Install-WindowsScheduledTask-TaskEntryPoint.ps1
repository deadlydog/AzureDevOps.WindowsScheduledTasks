param
(
	[parameter(Mandatory=$true,HelpMessage="Where the new Scheduled Task properties should be retrieved from.")]
	[ValidateSet('XmlFile', 'InlineXml', 'Inline')]
	[string] $ScheduledTaskDefinitionSource,

	[parameter(Mandatory=$false,HelpMessage="The XML file defining the properties of the Scheduled Task to install.")]
	[string] $ScheduledTaskXmlFileToImportFrom,

	[parameter(Mandatory = $false, HelpMessage = "The XML defining the properties of the Scheduled Task to install.")]
	[string] $ScheduledTaskXml,

	[parameter(Mandatory=$true,HelpMessage="The full name, including the path, of the Windows Scheduled Task to install.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskFullName,

	[parameter(Mandatory=$false,HelpMessage="The description for the Scheduled Task.")]
	[string] $ScheduledTaskDescription,

	[parameter(Mandatory=$false,HelpMessage="The full path to the application executable or script file to run.")]
	[string] $ApplicationPathToRun,

	[parameter(Mandatory=$false,HelpMessage="The arguments to pass to the application executable or script to run.")]
	[string] $ApplicationArguments,

	[parameter(Mandatory=$false,HelpMessage="The options for the working directory to run the application executable or script from.")]
	[ValidateSet('ApplicationDirectory', 'CustomDirectory')]
	[string] $WorkingDirectoryOptions,

	[parameter(Mandatory=$false,HelpMessage="The custom working directory to run the application executable or script from.")]
	[string] $CustomWorkingDirectory,

	[parameter(Mandatory=$false,HelpMessage="The type of event that should trigger the Scheduled Task to run.")]
	[ValidateSet('DateTime', 'AtLogOn', 'AtStartup')]
	[string] $ScheduleTriggerType,

	[parameter(Mandatory=$false,HelpMessage="The user that must log on to the computer in order for the Scheduled Task to be triggered to run.")]
	[string] $AtLogOnTriggerUsername,

	[parameter(Mandatory=$false,HelpMessage="The time that the Scheduled Task should start running at.")]
	[string] $DateTimeScheduleStartTime,

	[parameter(Mandatory=$false,HelpMessage="How often the Scheduled Task should run.")]
	[ValidateSet('Once', 'Daily', 'Weekly')]
	[string] $DateTimeScheduleFrequencyOptions,

	[parameter(Mandatory=$false,HelpMessage="The number of days between running the Scheduled Task again when on a Daily frequency.")]
	[string] $DateTimeScheduleFrequencyDailyInterval,

	[parameter(Mandatory=$false,HelpMessage="The number of weeks between running the Scheduled Task again when on a Weekly frequency.")]
	[string] $DateTimeScheduleFrequencyWeeklyInterval,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Mondays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Tuesdays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Wednesdays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Thursdays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Fridays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Saturdays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Sundays or not.")]
	[string] $ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task run repeatedly again after being triggered.")]
	[string] $ShouldScheduledTaskRunRepeatedlyString,

	[parameter(Mandatory=$false,HelpMessage="How long to wait before running the Scheduled Task again.")]
	[string] $ScheduleRepetitionIntervalInMinutes,

	[parameter(Mandatory=$false,HelpMessage="How long the Scheduled Task should keep repeating at the specified interval for.")]
	[string] $ScheduleRepetitionDurationInMinutes,

	[parameter(Mandatory=$false,HelpMessage="How much potential delay after the Scheduled Tasks specified start time to wait for before starting the Scheduled Task.")]
	[string] $ScheduleStartTimeRandomDelayInMinutes,

	[parameter(Mandatory=$false,HelpMessage="Options for the account that the Scheduled Task should run as.")]
	[ValidateSet('System', 'LocalService', 'NetworkService', 'CustomAccount')]
	[string] $ScheduledTaskAccountToRunAsOptions,

	[parameter(Mandatory=$false,HelpMessage="The Username of the custom account that the Scheduled Task should run as.")]
	[string] $CustomAccountToRunScheduledTaskAsUsername,

	[parameter(Mandatory=$false,HelpMessage="The Password of the custom account that the Scheduled Task should run as.")]
	[string] $CustomAccountToRunScheduledTaskAsPassword,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task be enabled when it's installed or not.")]
	[string] $ShouldScheduledTaskBeEnabledString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task run with the highest privileges.")]
	[string] $ShouldScheduledTaskRunWithHighestPrivilegesString,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task be run immediately after it's installed or not.")]
	[string] $ShouldScheduledTaskRunAfterInstallString,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to install the scheduled task on.")]
	[string] $ComputerNames,

	[parameter(Mandatory=$false,HelpMessage="The username to use to connect to the computer(s).")]
	[string] $Username,

	[parameter(Mandatory=$false,HelpMessage="The password to use to connect to the computer(s).")]
	[string] $Password,

	[parameter(Mandatory=$false,HelpMessage="If CredSSP should be used when connecting to remote computers or not.")]
	[string] $UseCredSspString,

	[parameter(Mandatory = $false, HelpMessage = "The protocol to use when connecting to remote computers.")]
	[ValidateSet('HTTP', 'HTTPS')]
	[string] $ProtocolOptions,

	[parameter(Mandatory = $false, HelpMessage = "If SkipCACheck should be used when connecting to remote computers or not.")]
	[string] $ProtocolSkipCaCheckString,

	[parameter(Mandatory = $false, HelpMessage = "If SkipCNCheck should be used when connecting to remote computers or not.")]
	[string] $ProtocolSkipCnCheckString,

	[parameter(Mandatory = $false, HelpMessage = "If SkipRevocationCheck should be used when connecting to remote computers or not.")]
	[string] $ProtocolSkipRevocationCheckString
)

Process
{
	Write-Verbose "Will attempt to install Windows Scheduled Task '$ScheduledTaskFullName' on '$ComputerNames'." -Verbose

	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnMondays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnFridays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString
	[bool] $shouldDateTimeScheduleFrequencyWeeklyRunOnSundays = Get-BoolValueFromString -string $ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString
	[bool] $shouldScheduledTaskRunRepeatedly = Get-BoolValueFromString -string $ShouldScheduledTaskRunRepeatedlyString
	[bool] $shouldScheduledTaskBeEnabled = Get-BoolValueFromString -string $ShouldScheduledTaskBeEnabledString
	[bool] $shouldScheduledTaskRunWithHighestPrivileges = Get-BoolValueFromString -string $ShouldScheduledTaskRunWithHighestPrivilegesString
	[bool] $shouldScheduledTaskRunAfterInstall = Get-BoolValueFromString -string $ShouldScheduledTaskRunAfterInstallString
	[bool] $useCredSsp = Get-BoolValueFromString -string $UseCredSspString
	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password

	[hashtable] $accountCredentialsToRunScheduledTaskAs = Get-AccountCredentialsToRunScheduledTaskAs -scheduldTaskAccountToRunAsOptions $ScheduledTaskAccountToRunAsOptions -customAccountToRunScheduledTaskAsUsername $CustomAccountToRunScheduledTaskAsUsername -customAccountToRunScheduledTaskAsPassword $CustomAccountToRunScheduledTaskAsPassword

	[hashtable] $taskNameAndPath = Get-ScheduledTaskNameAndPath -fullTaskName $ScheduledTaskFullName

	[bool] $usingXml = $false
	if ($ScheduledTaskDefinitionSource -eq 'XmlFile')
	{
		$ScheduledTaskXml = Get-XmlStringFromFile -xmlFilePath $ScheduledTaskXmlFileToImportFrom
		$usingXml = $true
	}

	if ($ScheduledTaskDefinitionSource -eq 'InlineXml')
	{
		$usingXml = $true
	}

	if ($usingXml)
	{
		if ([string]::IsNullOrWhiteSpace($ScheduledTaskXml))
		{
			throw 'You must provide valid XML for the Scheduled Task definition.'
		}

		Install-WindowsScheduledTask -Xml $ScheduledTaskXml -ScheduledTaskName $taskNameAndPath.Name -ScheduledTaskPath $taskNameAndPath.Path -AccountToRunScheduledTaskAsUsername $accountCredentialsToRunScheduledTaskAs.Username -AccountToRunScheduledTaskAsPassword $accountCredentialsToRunScheduledTaskAs.Password -ShouldScheduledTaskRunAfterInstall $shouldScheduledTaskRunAfterInstall -ComputerName $computers -Credential $credential -UseCredSsp $useCredSsp -Verbose
		return
	}

	[string] $workingDirectory = Get-WorkingDirectory -workingDirectoryOption $WorkingDirectoryOptions -customWorkingDirectory $CustomWorkingDirectory -applicationPath $ApplicationPathToRun

	[ciminstance[]] $scheduledTaskAction = Get-ScheduledTaskAction -applicationPathToRun $ApplicationPathToRun -applicationArguments $ApplicationArguments -workingDirectory $workingDirectory

	[ciminstance[]] $scheduledTaskTrigger = Get-ScheduledTaskTrigger -triggerType $ScheduleTriggerType -atLogOnTriggerUsername $AtLogOnTriggerUsername -dateTimeScheduleStartTime $DateTimeScheduleStartTime -dateTimeScheduleFrequencyOptions $DateTimeScheduleFrequencyOptions -dateTimeScheduleFrequencyDailyInterval $DateTimeScheduleFrequencyDailyInterval -dateTimeScheduleFrequencyWeeklyInterval $DateTimeScheduleFrequencyWeeklyInterval -shouldDateTimeScheduleFrequencyWeeklyRunOnMondays $shouldDateTimeScheduleFrequencyWeeklyRunOnMondays -shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays $shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays $shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays $shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays -shouldDateTimeScheduleFrequencyWeeklyRunOnFridays $shouldDateTimeScheduleFrequencyWeeklyRunOnFridays -shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays $shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays -shouldDateTimeScheduleFrequencyWeeklyRunOnSundays $shouldDateTimeScheduleFrequencyWeeklyRunOnSundays -shouldScheduledTaskRunRepeatedly $shouldScheduledTaskRunRepeatedly -scheduleRepetitionIntervalInMinutes $ScheduleRepetitionIntervalInMinutes -scheduleRepetitionDurationInMinutes $ScheduleRepetitionDurationInMinutes -scheduleStartTimeRandomDelayInMinutes $ScheduleStartTimeRandomDelayInMinutes

	[ciminstance] $scheduledTaskSettings = Get-ScheduledTaskSettings -shouldBeEnabled $shouldScheduledTaskBeEnabled

	[string] $scheduledTaskRunLevel = Get-ScheduledTaskRunLevel -shouldScheduledTaskRunWithHighestPrivileges $shouldScheduledTaskRunWithHighestPrivileges

	Install-WindowsScheduledTask -ScheduledTaskName $taskNameAndPath.Name -ScheduledTaskPath $taskNameAndPath.Path -AccountToRunScheduledTaskAsUsername $accountCredentialsToRunScheduledTaskAs.Username -AccountToRunScheduledTaskAsPassword $accountCredentialsToRunScheduledTaskAs.Password -ScheduledTaskDescription $ScheduledTaskDescription -ScheduledTaskAction $scheduledTaskAction -ScheduledTaskSettings $scheduledTaskSettings -ScheduledTaskTrigger $scheduledTaskTrigger -ScheduledTaskRunLevel $scheduledTaskRunLevel -ShouldScheduledTaskRunAfterInstall $shouldScheduledTaskRunAfterInstall -ComputerName $computers -Credential $credential -UseCredSsp $useCredSsp -Verbose
}

Begin
{
	# Turn on Strict Mode to help catch syntax-related errors.
	Set-StrictMode -Version Latest

	# Display environmental information before doing anything else in case we encounter errors.
	[string] $operatingSystemVersion = [System.Environment]::OSVersion
	[string] $powerShellVersion = $PSVersionTable.PSVersion
	Write-Verbose "Running on operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

	# Build paths to modules to import and import them.
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot
	[string] $codeDirectoryPath = $THIS_SCRIPTS_DIRECTORY_PATH

	[string] $utilitiesModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\Utilities.psm1'
	Write-Debug "Importing module '$utilitiesModuleFilePath'."
	Import-Module -Name $utilitiesModuleFilePath -Force

	[string] $userInputToScheduledTaskMapperModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\UserInputToScheduledTaskMapper.psm1'
	Write-Debug "Importing module '$userInputToScheduledTaskMapperModuleFilePath'."
	Import-Module -Name $userInputToScheduledTaskMapperModuleFilePath -Force

	[string] $userInputToWinRmSettingsMapperModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\UserInputToWinRmSettingsMapper.psm1'
	Write-Debug "Importing module '$userInputToWinRmSettingsMapperModuleFilePath'."
	Import-Module -Name $userInputToWinRmSettingsMapperModuleFilePath -Force

	[string] $installWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Install-WindowsScheduledTask.psm1'
	Write-Debug "Importing module '$installWindowsScheduledTaskModuleFilePath'."
	Import-Module -Name $installWindowsScheduledTaskModuleFilePath -Force
}