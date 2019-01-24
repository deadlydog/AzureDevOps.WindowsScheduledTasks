param
(
	[parameter(Mandatory=$false,HelpMessage="Where the new Scheduled Task properties should be retrieved from.")]
	[ValidateSet('ImportFromXmlFile', 'Inline')]
	[string] $ScheduledTaskDefinitionSource,

	[parameter(Mandatory=$true,HelpMessage="The XML file defining the properties of the Scheduled Task to install.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskXmlFileToImportFrom,

	[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to install.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskName,

	[parameter(Mandatory=$false,HelpMessage="The description for the Scheduled Task.")]
	[string] $ScheduledTaskDescription,

	[parameter(Mandatory=$true,HelpMessage="The full path to the application executable or script file to run.")]
	[ValidateNotNullOrEmpty()]
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

	[parameter(Mandatory=$false,HelpMessage="The time that the Scheduled Task should start running at.")]
	[string] $DateTimeScheduleStartTime,

	[parameter(Mandatory=$false,HelpMessage="How often the Scheduled Task should run.")]
	[ValidateSet('Once', 'Daily', 'Weekly')]
	[string] $DateTimeScheduleFrequencyOptions,

	[parameter(Mandatory=$false,HelpMessage="The number of days between running the Scheduled Task again when on a Daily frequency.")]
	[string] $DateTimeScheduleFrequencyDailyInterval,

	[parameter(Mandatory=$false,HelpMessage="The number of weeks between running the Scheduled Task again when on a Weekly frequency.")]
	[string] $DateTimeScheduleFrequencyWeeklyInterval,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran multiple days a week or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Mondays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Tuesdays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Wednesdays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Thursdays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Fridays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Saturdays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task on a Weekly frequency be ran on Sundays or not.")]
	[bool] $ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task run repeatedly again after being triggered.")]
	[bool] $ShouldScheduledTaskRunRepeatedly,

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
	[bool] $ShouldScheduledTaskBeEnabled,

	[parameter(Mandatory=$false,HelpMessage="Should the Scheduled Task be run immediately after it's installed or not.")]
	[bool] $ShouldScheduledTaskRunAfterInstall,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to install the scheduled task on.")]
	[string] $ComputerNames,

	[parameter(Mandatory=$false,HelpMessage="The username to use to connect to the computer(s).")]
	[string] $Username,

	[parameter(Mandatory=$false,HelpMessage="The password to use to connect to the computer(s).")]
	[string] $Password,

	[parameter(Mandatory=$false,HelpMessage="If CredSSP should be used when connecting to remote computers or not.")]
	[bool] $UseCredSsp
)

Process
{
	Write-Verbose "About to attempt to install Windows Scheduled Task '$ScheduledTaskName' on '$ComputerNames'." -Verbose
	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password

	[hashtable] $accountCredentialsToRunScheduledTaskAs = Get-AccountCredentialsToRunScheduledTaskAs -scheduldTaskAccountToRunAsOptions $ScheduldTaskAccountToRunAsOptions -customAccountToRunScheduledTaskAsUsername $CustomAccountToRunScheduledTaskAsUsername -customAccountToRunScheduledTaskAsPassword $CustomAccountToRunScheduledTaskAsPassword

	[hashtable] $taskNameAndPath = Get-ScheduledTaskNameAndPath -fullTaskName $ScheduledTaskName

	if ($ScheduledTaskDefinitionSource -eq 'ImportFromXmlFile')
	{
		Install-WindowsScheduledTask -ScheduledTaskName $taskNameAndPath.Name -ScheduledTaskPath $taskNameAndPath.Path -AccountCredentialsToRunScheduledTaskAs $accountCredentialsToRunScheduledTaskAs -ComputerName $computers -Credential $credential
		return
	}

	[string] $workingDirectory = Get-WorkingDirectory -workingDirectoryOption $WorkingDirectoryOptions -customWorkingDirectory $CustomWorkingDirectory -applicationPath $ApplicationPathToRun

	$scheduledTaskTrigger = Get-ScheduledTaskTrigger -triggerType $ScheduleTriggerType -dateTimeScheduleStartTime $DateTimeScheduleStartTime -dateTimeScheduleFrequencyOptions $DateTimeScheduleFrequencyOptions -dateTimeScheduleFrequencyDailyInterval $DateTimeScheduleFrequencyDailyInterval -dateTimeScheduleFrequencyWeeklyInterval $DateTimeScheduleFrequencyWeeklyInterval -shouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek $ShouldDateTimeScheduleFrequencyWeeklyRunMulipleTimesAWeek -shouldDateTimeScheduleFrequencyWeeklyRunOnMondays $ShouldDateTimeScheduleFrequencyWeeklyRunOnMondays -shouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays $ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays $ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdays -shouldDateTimeScheduleFrequencyWeeklyRunOnThursdays $ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdays -shouldDateTimeScheduleFrequencyWeeklyRunOnFridays $ShouldDateTimeScheduleFrequencyWeeklyRunOnFridays -shouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays $ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdays -shouldDateTimeScheduleFrequencyWeeklyRunOnSundays $ShouldDateTimeScheduleFrequencyWeeklyRunOnSundays -shouldScheduledTaskRunRepeatedly $ShouldScheduledTaskRunRepeatedly -scheduleRepetitionIntervalInMinutes $ScheduleRepetitionIntervalInMinutes -scheduleRepetitionDurationInMinutes $ScheduleRepetitionDurationInMinutes -scheduleStartTimeRandomDelayInMinutes $ScheduleStartTimeRandomDelayInMinutes



	Install-WindowsScheduledTask -ScheduledTaskName $ScheduledTaskName -ComputerName $computers -Credential $credential -ScheduledTaskDescription $ScheduledTaskDescription -ApplicationPathToRun $ApplicationPathToRun -ApplicationArguments $ApplicationArguments -WorkingDirectory $workingDirectory
}

Begin
{
	# Display environmental information before doing anything else in case we encounter errors.
	[string] $operatingSystemVersion = [System.Environment]::OSVersion
	[string] $powerShellVersion = $PSVersionTable.PSVersion
	Write-Verbose "Running on operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

	# Build paths to modules to import and import them.
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot
	[string] $codeDirectoryPath = $THIS_SCRIPTS_DIRECTORY_PATH

	[string] $utilitiesModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\Utilities.psm1'
	Write-Verbose "Importing module '$utilitiesModuleFilePath'." -Verbose
	Import-Module -Name $utilitiesModuleFilePath -Force

	[string] $userInputToScheduledTaskMapperModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\UserInputToScheduledTaskMapper.psm1'
	Write-Verbose "Importing module '$userInputToScheduledTaskMapperModuleFilePath'." -Verbose
	Import-Module -Name $userInputToScheduledTaskMapperModuleFilePath -Force

	[string] $installWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Install-WindowsScheduledTask.psm1'
	Write-Verbose "Importing module '$installWindowsScheduledTaskModuleFilePath'." -Verbose
	Import-Module -Name $installWindowsScheduledTaskModuleFilePath -Force
}