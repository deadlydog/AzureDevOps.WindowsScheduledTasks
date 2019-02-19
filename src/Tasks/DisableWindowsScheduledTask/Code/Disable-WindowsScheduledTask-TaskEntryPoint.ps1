param
(
	[parameter(Mandatory=$true,HelpMessage="The full name, including the path, of the Windows Scheduled Task to disable.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskFullName,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to disable the scheduled task on.")]
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
	Write-Verbose "About to attempt to disable Windows Scheduled Task '$ScheduledTaskFullName' on '$ComputerNames'." -Verbose

	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password
	[hashtable] $taskNameAndPath = Get-ScheduledTaskNameAndPath -fullTaskName $ScheduledTaskFullName

	Disable-WindowsScheduledTask -ScheduledTaskName $taskNameAndPath.Name -ScheduledTaskPath $taskNameAndPath.Path -ComputerName $computers -Credential $credential -UseCredSsp $UseCredSsp
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
	Write-Debug "Importing module '$utilitiesModuleFilePath'."
	Import-Module -Name $utilitiesModuleFilePath -Force

	[string] $userInputToScheduledTaskMapperModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\UserInputToScheduledTaskMapper.psm1'
	Write-Debug "Importing module '$userInputToScheduledTaskMapperModuleFilePath'."
	Import-Module -Name $userInputToScheduledTaskMapperModuleFilePath -Force

	[string] $disableWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Disable-WindowsScheduledTask.psm1'
	Write-Debug "Importing module '$disableWindowsScheduledTaskModuleFilePath'."
	Import-Module -Name $disableWindowsScheduledTaskModuleFilePath -Force
}