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

	[parameter(Mandatory=$false,HelpMessage="If CredSSP should be used when connecting to remote computers or not.")]
	[bool] $UseCredSsp = $false
)

Process
{
	Write-Verbose "About to attempt to uninstall Windows Scheduled Task '$ScheduledTaskName' on '$ComputerNames'." -Verbose
	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password
	Uninstall-WindowsScheduledTask -ScheduledTaskName $ScheduledTaskName -ComputerName $computers -Credential $credential
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

	[string] $uninstallWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Uninstall-WindowsScheduledTask.psm1'
	Write-Verbose "Importing module '$uninstallWindowsScheduledTaskModuleFilePath'." -Verbose
	Import-Module -Name $uninstallWindowsScheduledTaskModuleFilePath -Force
}