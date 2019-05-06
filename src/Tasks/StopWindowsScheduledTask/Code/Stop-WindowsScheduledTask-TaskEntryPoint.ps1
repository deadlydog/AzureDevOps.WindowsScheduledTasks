param
(
	[parameter(Mandatory=$true,HelpMessage="The full name, including the path, of the Windows Scheduled Task to stop.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskFullName,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to stop the scheduled task on.")]
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
	Write-Verbose "Will attempt to stop Windows Scheduled Task '$ScheduledTaskFullName' on '$ComputerNames'." -Verbose

	[bool] $useCredSsp = Get-BoolValueFromString -string $UseCredSspString
	[bool] $protocolSkipCaCheck = Get-BoolValueFromString -string $ProtocolSkipCaCheckString
	[bool] $protocolSkipCnCheck = Get-BoolValueFromString -string $ProtocolSkipCnCheckString
	[bool] $protocolSkipRevocationCheck = Get-BoolValueFromString -string $ProtocolSkipRevocationCheckString

	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password
	[hashtable] $taskNameAndPath = Get-ScheduledTaskNameAndPath -fullTaskName $ScheduledTaskFullName

	[hashtable] $winRmSettings = Get-WinRmSettings -computers $computers -credential $credential -useCredSsp $useCredSsp -protocol $ProtocolOptions -skipCaCheck $protocolSkipCaCheck -skipCnCheck $protocolSkipCnCheck -skipRevocationCheck $protocolSkipRevocationCheck

	Stop-WindowsScheduledTask -ScheduledTaskName $taskNameAndPath.Name -ScheduledTaskPath $taskNameAndPath.Path -WinRmSettings $winRmSettings -Verbose
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

	[string] $userInputToWinRmSettingsMapperModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Shared\UserInputToWinRmSettingsMapper.psm1'
	Write-Debug "Importing module '$userInputToWinRmSettingsMapperModuleFilePath'."
	Import-Module -Name $userInputToWinRmSettingsMapperModuleFilePath -Force

	[string] $stopWindowsScheduledTaskModuleFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Stop-WindowsScheduledTask.psm1'
	Write-Debug "Importing module '$stopWindowsScheduledTaskModuleFilePath'."
	Import-Module -Name $stopWindowsScheduledTaskModuleFilePath -Force
}