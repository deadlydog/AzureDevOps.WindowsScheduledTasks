param
(
	[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to uninstall.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskName,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to uninstall the scheduled task from.")]
	[string] $ComputerNames,

	[parameter(Mandatory=$false,HelpMessage="The username to use to connect to the computer(s).")]
	[string] $Username,

	[parameter(Mandatory=$false,HelpMessage="The password to use to connect to the computer(s).")]
	[string] $Password,

	[parameter(Mandatory=$true,HelpMessage="The description for the Scheduled Task.")]
	[string] $ScheduledTaskDescription,

	[parameter(Mandatory=$true,HelpMessage="The full path to the application executable file to run.")]
	[ValidateNotNullOrEmpty()]
	[string] $ApplicationPathToRun,

	[parameter(Mandatory=$false,HelpMessage="The arguments to pass to the application executable to run.")]
	[string] $ApplicationArguments,

	[parameter(Mandatory=$true,HelpMessage="How often the Scheduled Task should run.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduleFrequency,

	[parameter(Mandatory=$true,HelpMessage="When the Scheduled Task should start running.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduleStartTime,

	[parameter(Mandatory=$false,HelpMessage="How much potential delay to wait for after the Scheduled Tasks specified start time.")]
	[string] $ScheduleStartTimeRandomDelayInMinutes,

	[parameter(Mandatory=$false,HelpMessage="How long to wait between each running of the Scheduled Task.")]
	[string] $ScheduleRepeatIntervalInMinutes,

	[parameter(Mandatory=$false,HelpMessage="How long the Scheduled Task should keep repeating at the specified interval for.")]
	[string] $ScheduleRepeatIntervalDurationInMinutes = '$(ScheduledTaskRepeatIntervalDurationInMinutes)',

	[parameter(Mandatory=$false,HelpMessage="If the Scheduled Task should be ran immediately after installation or not.")]
	[bool] $RunScheduledTaskAfterInstallation
)

Process
{
	Write-Verbose "About to attempt to install Windows Scheduled Task '$ScheduledTaskName' on '$ComputerNames'." -Verbose
	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password
	Install-WindowsScheduledTask -ScheduledTaskName $ScheduledTaskName -ComputerName $computers -Credential $credential
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

	[string] $installWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Install-WindowsScheduledTask.psm1'
	Write-Verbose "Importing module '$installWindowsScheduledTaskModuleFilePath'." -Verbose
	Import-Module -Name $installWindowsScheduledTaskModuleFilePath -Force
}