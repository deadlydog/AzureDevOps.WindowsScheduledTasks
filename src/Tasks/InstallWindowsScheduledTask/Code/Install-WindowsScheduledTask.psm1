#Requires -Version 3.0

function Install-WindowsScheduledTask
{
	[cmdletbinding(DefaultParameterSetName='Inline')]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to install.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler where the Windows Scheduled Task should be installed.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$true,HelpMessage="The username of the account that should be used to run the Scheduled Task.")]
		[ValidateNotNull()]
		[string] $AccountUsernameToRunScheduledTaskAs,

		[parameter(Mandatory=$false,HelpMessage="The password of the account that should be used to run the Scheduled Task.")]
		[string] $AccountPasswordToRunScheduledTaskAs,

		[parameter(ParameterSetName="Xml",Mandatory=$true,HelpMessage="The path to the XML file containing the Scheduled Task definition.")]
		[string] $XmlFilePath,

		[parameter(ParameterSetName="Inline",Mandatory=$false,HelpMessage="The description for the Scheduled Task.")]
		[string] $ScheduledTaskDescription,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task action.")]
		[ValidateNotNull]
		[CimInstance[]] $ScheduledTaskAction,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task settings.")]
		[ValidateNotNull]
		[CimInstance] $ScheduledTaskSettings,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task trigger.")]
		[ValidateNotNull]
		[CimInstance[]] $ScheduledTaskTrigger,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task run level (i.e. admin or regular user).")]
		[ValidateNotNullOrEmpty]
		[string] $ScheduledTaskRunLevel,

		[parameter(Mandatory=$false,HelpMessage="If the Scheduled Task should be ran immediately after installation or not.")]
		[bool] $ShouldScheduledTaskRunAfterInstall,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to uninstall the scheduled task from. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential,

		[parameter(Mandatory=$false,HelpMessage="If Cred SSP should be used when connecting to the remote computers or not.")]
		[bool] $UseCredSsp
	)

	Process
	{
		[string] $xml = Get-XmlStringFromFile -xmlFilePath $XmlFilePath

		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskDescription = $ScheduledTaskDescription
			AccountUsernameToRunScheduledTaskAs = $AccountUsernameToRunScheduledTaskAs
			AccountPasswordToRunScheduledTaskAs = $AccountPasswordToRunScheduledTaskAs
			Xml = $xml
			ScheduledTaskAction = $ScheduledTaskAction
			ScheduledTaskSettings = $ScheduledTaskSettings
			ScheduledTaskTrigger = $ScheduledTaskTrigger
			ScheduledTaskRunLevel = $ScheduledTaskRunLevel
			ShouldRunScheduledTaskAfterInstallation = $ShouldScheduledTaskRunAfterInstall
		}

		Invoke-InstallWindowsScheduledTaskOnComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential -useCredSsp $UseCredSsp
	}

	Begin
	{
		function Get-XmlStringFromFile([string] $xmlFilePath)
		{
			[string] $xml = [string]::Empty
			if (![string]::IsNullOrWhiteSpace($XmlFilePath))
			{
				if (!(Test-Path -Path $XmlFilePath -PathType Leaf))
				{
					throw "Could not find the specified XML file '$xmlFilePath' to read the Scheduled Task definition from."
				}

				$xml = Get-Content -Path $XmlFilePath -Raw
			}
		}

		function Invoke-InstallWindowsScheduledTaskOnComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential, [bool] $useCredSsp)
		{
			[bool] $noComputersWereSpecified = ($null -eq $computers -or $computers.Count -eq 0)
			[bool] $noCredentialWasSpecified = ($null -eq $credential)

			# If we are connecting to localhost, we don't need to worry about CredSSP.
			if ($noComputersWereSpecified)
			{
				if ($noCredentialWasSpecified)
				{
					Invoke-Command -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
				else
				{
					Invoke-Command -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
				}
			}
			else
			{
				if ($noCredentialWasSpecified)
				{
					if ($useCredSsp)
					{
						Invoke-Command -ComputerName $computers -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Authentication Credssp -Verbose
					}
					else
					{
						Invoke-Command -ComputerName $computers -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
					}
				}
				else
				{
					if ($useCredSsp)
					{
						Invoke-Command -ComputerName $computers -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Authentication Credssp -Verbose
					}
					else
					{
						Invoke-Command -ComputerName $computers -Credential $credential -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose
					}
				}
			}
		}

		$installScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			[bool] $installUsingXmlFile = ![string]::IsNullOrWhiteSpace($scheduledTaskSettings.Xml)

			$scheduledTask = $null
			if ($installUsingXmlFile)
			{
				Write-Verbose "Installing Scheduled Task using specifed XML definition." -Verbose
				$scheduledTask = Register-ScheduledTask -TaskName $scheduledTaskSettings.ScheduledTaskName -TaskPath $scheduledTaskSettings.ScheduledTaskPath -User $scheduledTaskSettings.AccountUsernameToRunScheduledTaskAs -Password $scheduledTaskSettings.AccountPasswordToRunScheduledTaskAs -Force -Xml $scheduledTaskSettings.Xml
			}
			else
			{
				Write-Verbose "Installing Scheduled Task using inline definition." -Verbose
				$scheduledTask = Register-ScheduledTask -TaskName $scheduledTaskSettings.ScheduledTaskName -TaskPath $scheduledTaskSettings.ScheduledTaskPath -User $scheduledTaskSettings.AccountUsernameToRunScheduledTaskAs -Password $scheduledTaskSettings.AccountPasswordToRunScheduledTaskAs -Force -Description $scheduledTaskSettings.ScheduledTaskDescription -Action $scheduledTaskSettings.ScheduledTaskAction -Settings $scheduledTaskSettings.ScheduledTaskSettings -Trigger $scheduledTaskSettings.ScheduledTaskTrigger -RunLevel $scheduledTaskSettings.ScheduledTaskRunLevel
			}

			if ($scheduledTaskSettings.ShouldRunScheduledTaskAfterInstallation)
			{
				Write-Verbose "Triggering the Scheduled Task '$taskName' on computer '$computerName' to run now." -Verbose
				$scheduledTask | Start-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Install-WindowsScheduledTask