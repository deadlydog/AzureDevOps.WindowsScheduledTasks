# These tests create and manipulate real Scheduled Tasks on the localhost.
# The Scheduled Tasks it manipulates are isolated in their own directory, and get cleaned up when the tests are done.
#Requires -RunAsAdministrator

Process
{
	Describe 'Installing Scheduled Tasks' {
		Context 'When installing a Scheduled Task' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'For an inline definition with an AtStartup trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml file definition with an AtStartup trigger, it gets created as expected.'
					scheduledTaskParameters = $XmlFileAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline definition with an AtLogOn trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineAtLogOnScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline xml definition with an AtLogOn trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineXmlAtLogOnScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline definition with a DateTime trigger, it gets created as expected.'
					scheduledTaskParameters = $InlineDateTimeScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an xml file definition with a DateTime trigger, it gets created as expected.'
					scheduledTaskParameters = $XmlFileDateTimeScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an inline xml definition, it gets created as expected.'
					scheduledTaskParameters = $InlineXmlScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For an invalid inline xml definition, an exception should be thrown.'
					scheduledTaskParameters = $InvalidBadXmlInlineXmlScheduledTaskParameters
					expectExceptionToBeThrown = $true
				}
				@{	testDescription = 'For an invalid empty inline xml definition, an exception should be thrown.'
					scheduledTaskParameters = $InvalidEmptyXmlInlineXmlScheduledTaskParameters
					expectExceptionToBeThrown = $true
				}
				@{	testDescription = 'For an invalid whitespace inline xml definition, an exception should be thrown.'
					scheduledTaskParameters = $InvalidWhitespaceXmlInlineXmlScheduledTaskParameters
					expectExceptionToBeThrown = $true
				}
				@{	testDescription = 'For a Weekly DateTime trigger on one day of the week, it gets created as expected.'
					scheduledTaskParameters = $WeeklyScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For a Weekly DateTime trigger on multiple days of the week, it gets created as expected.'
					scheduledTaskParameters = $WeeklyMultipleDaysScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For a Weekly DateTime trigger with no days of the week specified, an exception should be thrown.'
					scheduledTaskParameters = $InvalidWeeklyBecauseNoWeekdaysSpecifiedScheduledTaskParameters
					expectExceptionToBeThrown = $true
				}
				@{	testDescription = 'For a definition with no Scheduled Task Description, it gets created as expected.'
					scheduledTaskParameters = $NoDescriptionScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'For a definition set to run after it is installed, it gets created as expected without throwing an error.'
					scheduledTaskParameters = $StartImmediatelyAfterInstallScheduledTaskParameters
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

		Context 'When the parameters are valid and uninstalling multiple Scheduled Tasks that do exist' {
			It 'Should uninstall all of the Scheduled Tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $uninstallMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Ensure multiple tasks exist before acting.
				Install-ScheduledTask -scheduledTaskParameters $InlineAtStartupScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $XmlFileAtStartupScheduledTaskParameters
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

		Context 'When the Scheduled Task to uninstall does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Uninstall-ScheduledTask -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $NeverInstalledScheduledTaskParameters.ScheduledTaskFullName
				$scheduledTask | Should -BeNullOrEmpty
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When uninstalling multiple Scheduled Tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $uninstallMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Act.
				$warningOutput = Uninstall-ScheduledTask -scheduledTaskParameters $uninstallMultipleTasksParameters 3>&1

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $uninstallMultipleTasksParameters.ScheduledTaskFullName
				$scheduledTask | Should -BeNullOrEmpty
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}
	}

	Describe 'Enabling Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is disabled, it gets enabled as expected.'
					scheduledTaskParameters = $DisabledScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already enabled, it stays enabled as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before enabling it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsEnabledCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the parameters are valid and enabling multiple Scheduled Tasks that do exist' {
			It 'Should enable all of the Scheduled Tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $enableMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Ensure multiple tasks exist before acting.
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $XmlFileAtStartupScheduledTaskParameters
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Enable-ScheduledTaskCustom -scheduledTaskParameters $enableMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.Settings.Enabled | Should -BeTrue
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $XmlFileAtStartupScheduledTaskParameters
			}
		}

		Context 'When the Scheduled Task to enable does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Enable-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When enabling multiple Scheduled Tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $enableMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Act.
				$warningOutput = Enable-ScheduledTaskCustom -scheduledTaskParameters $enableMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}
	}

	Describe 'Disabling Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is enabled, it gets disabled as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already disabled, it stays disabled as expected.'
					scheduledTaskParameters = $DisabledScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before enabling it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsDisabledCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the parameters are valid and disabling multiple Scheduled Tasks that do exist' {
			It 'Should disable all of the Scheduled Tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $disableMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Ensure multiple tasks exist before acting
				Install-ScheduledTask -scheduledTaskParameters $XmlFileAtStartupScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Disable-ScheduledTaskCustom -scheduledTaskParameters $disableMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.Settings.Enabled | Should -BeFalse
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $XmlFileAtStartupScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
			}
		}

		Context 'When the Scheduled Task to disable does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Disable-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When disabling multiple Scheduled Tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $disableMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Act.
				$warningOutput = Disable-ScheduledTaskCustom -scheduledTaskParameters $disableMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}
	}

	Describe 'Starting Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is stopped, it gets started as expected.'
					scheduledTaskParameters = $RunForAFewSecondsScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already started, it stays running as expected.'
					scheduledTaskParameters = $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before starting it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsStartedCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the parameters are valid and starting multiple Scheduled Tasks that do exist' {
			It 'Should start all of the Scheduled Tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $startMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Ensure multiple tasks exist before acting.
				[hashtable] $runForAFewSecondsScheduledTaskParameters2 = $RunForAFewSecondsScheduledTaskParameters.Clone()
				$runForAFewSecondsScheduledTaskParameters2.ScheduledTaskFullName += '2'
				Install-ScheduledTask -scheduledTaskParameters $RunForAFewSecondsScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $runForAFewSecondsScheduledTaskParameters2
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Start-ScheduledTaskCustom -scheduledTaskParameters $startMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.State | Should -Be 'Running'
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $RunForAFewSecondsScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $runForAFewSecondsScheduledTaskParameters2
			}
		}

		Context 'When the Scheduled Task to start does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Start-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When starting multiple Scheduled Tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $startMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Act.
				$warningOutput = Start-ScheduledTaskCustom -scheduledTaskParameters $startMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When the Scheduled Task to start is disabled' {
			It 'Should throw an exception' {
				# Need to install expected Scheduled Task before trying to start it.
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters

				# Act and assert.
				{ Start-ScheduledTaskCustom -scheduledTaskParameters $DisabledScheduledTaskParameters } | Should -Throw

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
			}
		}
	}

	Describe 'Stopping Scheduled Tasks' {
		Context 'When the parameters are valid and the Scheduled Task exists' {
			[hashtable[]] $tests = @(
				@{	testDescription = 'And the Scheduled Task is started, it gets stopped as expected.'
					scheduledTaskParameters = $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
				@{	testDescription = 'And the Scheduled Task is already stopped, it stays stopped as expected.'
					scheduledTaskParameters = $InlineAtStartupScheduledTaskParameters
					expectExceptionToBeThrown = $false
				}
			)
			$tests | ForEach-Object {
				[hashtable] $parameters = $_

				# Need to install expected Scheduled Task before starting it.
				Install-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters

				Assert-ScheduledTaskIsStoppedCorrectly @parameters

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $parameters.scheduledTaskParameters
			}
		}

		Context 'When the parameters are valid and stopping multiple Scheduled Tasks that do exist' {
			It 'Should stop all of the Scheduled Tasks' {
				# Arrange.
				[string] $taskFullNameWithWildcardForMultipleTasks = "$CommonScheduledTaskPath*"
				[hashtable] $stopMultipleTasksParameters = @{
					ScheduledTaskFullName = $taskFullNameWithWildcardForMultipleTasks
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Ensure multiple tasks exist before acting.
				[hashtable] $runForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters2 = $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters.Clone()
				$runForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters2.ScheduledTaskFullName += '2'
				Install-ScheduledTask -scheduledTaskParameters $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters
				Install-ScheduledTask -scheduledTaskParameters $runForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters2
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks.Length | Should -Be 2

				# Act.
				Stop-ScheduledTaskCustom -scheduledTaskParameters $stopMultipleTasksParameters

				# Assert.
				$scheduledTasks = Get-ScheduledTaskByFullName -taskFullName $taskFullNameWithWildcardForMultipleTasks
				$scheduledTasks | Should -Not -BeNullOrEmpty
				$scheduledTasks | ForEach-Object {
					$_.State | Should -Be 'Ready'
				}

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters
				Uninstall-ScheduledTask -scheduledTaskParameters $runForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters2
			}
		}

		Context 'When the Scheduled Task to stop does not exist' {
			It 'Should log a warning, but still continue' {
				# Act.
				$warningOutput = Stop-ScheduledTaskCustom -scheduledTaskParameters $NeverInstalledScheduledTaskParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When stopping multiple Scheduled Tasks that do not exist' {
			It 'Should log a warning, but still continue' {
				# Arrange.
				[hashtable] $stopMultipleTasksParameters = @{
					ScheduledTaskFullName = '\APathThatDoesNotExist\*'
					ComputerNames = ''
					Username = ''
					Password = ''
					UseCredSsp = 'false'
				}

				# Act.
				$warningOutput = Stop-ScheduledTaskCustom -scheduledTaskParameters $stopMultipleTasksParameters 3>&1

				# Assert.
				$warningOutput | Should -BeLike "*was not found on computer*"
			}
		}

		Context 'When the Scheduled Task to stop is disabled' {
			It 'Should should remain disabled' {
				# Need to install expected Scheduled Task before trying to stop it.
				Install-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters

				# Act.
				Stop-ScheduledTaskCustom -scheduledTaskParameters $DisabledScheduledTaskParameters

				# Assert.
				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $DisabledScheduledTaskParameters.ScheduledTaskFullName
				$scheduledTask | Should -Not -BeNullOrEmpty
				$scheduledTask.State | Should -Be 'Disabled'

				# Cleanup now that we're done.
				Uninstall-ScheduledTask -scheduledTaskParameters $DisabledScheduledTaskParameters
			}
		}
	}

	# This should be the last to to run to ensure all test tasks are uninstalled to keep everything nice and clean.
	Write-Output "Uninstalling any lingering Scheduled Tasks. Typically nothing should be left to uninstall at this point."
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
	[string] $EnableScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.
	[string] $DisableScheduledTaskEntryPointScriptPath = [string]::Empty # Populated dynamically below.

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

	[string] $enableScheduledTaskEntryPointScriptName = 'Enable-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $EnableScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $enableScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($EnableScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$enableScheduledTaskEntryPointScriptName' file."
	}

	[string] $disableScheduledTaskEntryPointScriptName = 'Disable-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $DisableScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $disableScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($DisableScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$disableScheduledTaskEntryPointScriptName' file."
	}

	[string] $startScheduledTaskEntryPointScriptName = 'Start-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $StartScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $startScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($StartScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$startScheduledTaskEntryPointScriptName' file."
	}

	[string] $stopScheduledTaskEntryPointScriptName = 'Stop-WindowsScheduledTask-TaskEntryPoint.ps1'
	[string] $StopScheduledTaskEntryPointScriptPath = Get-ChildItem -Path $srcDirectoryPath -Recurse -Force -File -Include $stopScheduledTaskEntryPointScriptName | Select-Object -First 1 -ExpandProperty FullName
	if ([string]::IsNullOrWhiteSpace($StopScheduledTaskEntryPointScriptPath))
	{
		throw "Could not locate the '$stopScheduledTaskEntryPointScriptName' file."
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

	# Enable-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Enable-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $enableTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $EnableScheduledTaskEntryPointScriptPath @enableTaskParameters"
	}

	# Disable-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Disable-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $disableTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $DisableScheduledTaskEntryPointScriptPath @disableTaskParameters"
	}

	# Start-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Start-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $startTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $StartScheduledTaskEntryPointScriptPath @startTaskParameters"
	}

	# Stop-ScheduledTask is a native cmdlet name, so we need to call ours something else.
	function Stop-ScheduledTaskCustom([hashtable] $scheduledTaskParameters)
	{
		[hashtable] $stopTaskParameters = @{
			ScheduledTaskFullName = $scheduledTaskParameters.ScheduledTaskFullName
			ComputerNames = $scheduledTaskParameters.ComputerNames
			Username = $scheduledTaskParameters.Username
			Password = $scheduledTaskParameters.Password
			UseCredSsp = $scheduledTaskParameters.UseCredSsp
		}
		Invoke-Expression -Command "& $StopScheduledTaskEntryPointScriptPath @stopTaskParameters"
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

				$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
				$scheduledTask | Should -BeNullOrEmpty
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

	function Assert-ScheduledTaskIsEnabledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Enable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Enable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.Settings.Enabled | Should -BeTrue
		}
	}

	function Assert-ScheduledTaskIsDisabledCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Disable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Disable-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.Settings.Enabled | Should -BeFalse
		}
	}

	function Assert-ScheduledTaskIsStartedCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Start-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Start-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.State | Should -Be 'Running'
		}
	}

	function Assert-ScheduledTaskIsStoppedCorrectly([string] $testDescription, [hashtable] $scheduledTaskParameters, [bool] $expectExceptionToBeThrown)
	{
		It $testDescription {
			if ($expectExceptionToBeThrown)
			{
				# Act and Assert.
				{ Stop-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters } | Should -Throw
				return
			}

			# Act.
			Stop-ScheduledTaskCustom -scheduledTaskParameters $scheduledTaskParameters

			# Assert.
			$scheduledTask = Get-ScheduledTaskByFullName -taskFullName $scheduledTaskParameters.ScheduledTaskFullName
			$scheduledTask | Should -Not -BeNullOrEmpty
			$scheduledTask.State | Should -Be 'Ready'
		}
	}

	# Scheduled Task that should never be installed, as it's used to run tests against Scheduled Tasks that are not installed.
	[hashtable] $NeverInstalledScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an Inline definition and an AtStartup trigger.
	[hashtable] $InlineAtStartupScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an XML file definition and an AtStartup trigger.
	[hashtable] $XmlFileAtStartupScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'XmlFile' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'AtStartup.xml'
		ScheduledTaskXml = ''
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an Inline definition and an AtLogOn trigger.
	[hashtable] $InlineAtLogOnScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an XML file definition and an AtLogOn trigger.
	[hashtable] $InlineXmlAtLogOnScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'InlineXml' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'AtLogOn.xml'
		ScheduledTaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>A test task set to trigger At Log On.</Description>
    <URI>\WindowsScheduledTasksTests\Test-InlineAtLogOn</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)</UserId>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <Duration>PT10M</Duration>
      <WaitTimeout>PT1H</WaitTimeout>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\SomeDirectory\Dummy.exe</Command>
      <Arguments>/some arguments /more args</Arguments>
      <WorkingDirectory>C:\SomeDirectory</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineAtLogOn')
		ScheduledTaskDescription = 'A test task set to trigger At Log On.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'AtLogOn' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = ''
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'System' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an Inline definition and an DateTime trigger.
	[hashtable] $InlineDateTimeScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineDateTime')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an XML File definition and a DateTime trigger.
	[hashtable] $XmlFileDateTimeScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'XmlFile' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = Get-XmlDefinitionPath -fileName 'DateTime.xml'
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-XmlDateTime')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an XML definition and a DateTime trigger.
	[hashtable] $InlineXmlScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'InlineXml' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>A test task set to trigger Once at a DateTime.</Description>
    <URI>\WindowsScheduledTasksTests\Test-InlineDateTime</URI>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <StartBoundary>2050-01-01T01:00:00-06:00</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-20</UserId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <Duration>PT10M</Duration>
      <WaitTimeout>PT1H</WaitTimeout>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\SomeDirectory\Dummy.exe</Command>
      <Arguments>/some arguments /more args</Arguments>
      <WorkingDirectory>C:\SomeDirectory</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
'@
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InlineXml')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an invalid XML definition.
	[hashtable] $InvalidBadXmlInlineXmlScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'InlineXml' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>A test task set to trigger Once at a DateTime.</Description>
'@
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InvalidBadInlineXml')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an invalid empty XML definition.
	[hashtable] $InvalidEmptyXmlInlineXmlScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'InlineXml' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InvalidEmptyInlineXml')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	# Scheduled Task with an invalid whitespace XML definition.
	[hashtable] $InvalidWhitespaceXmlInlineXmlScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'InlineXml' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = '     '
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-InvalidWhitespaceInlineXml')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'C:\SomeDirectory\Dummy.exe'
		ApplicationArguments = '/some arguments /more args'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $DisabledScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-DisabledTask')
		ScheduledTaskDescription = 'A test task that gets installed as disabled.'
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'false'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $WeeklyScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-Weekly')
		ScheduledTaskDescription = 'A test task for a Weekly trigger with a single weekday specified.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Weekly' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = '1'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $WeeklyMultipleDaysScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-WeeklyMultipleDays')
		ScheduledTaskDescription = 'A test task for a Weekly trigger with multiple weekdays specified.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '01/01/2050 01:00:00'
		DateTimeScheduleFrequencyOptions = 'Weekly' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = '1'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'true'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $InvalidWeeklyBecauseNoWeekdaysSpecifiedScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-Weekly')
		ScheduledTaskDescription = 'A test task for a Weekly trigger with no weekdays specified.'
		ApplicationPathToRun = 'C:\Dummy.exe'
		ApplicationArguments = ''
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Weekly' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = '1'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $NoDescriptionScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-')
		ScheduledTaskDescription = ''
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
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'LocalService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $StartImmediatelyAfterInstallScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-tartAfterInstall')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'PowerShell.exe'
		ApplicationArguments = '-Command Start-Sleep -Milliseconds 10'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'true'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $RunForAFewSecondsScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-RunForAFewSeconds')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'PowerShell.exe'
		ApplicationArguments = '-Command Start-Sleep -Seconds 5'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'false'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}

	[hashtable] $RunForAFewSecondsAndStartImmediatelyAfterInstallScheduledTaskParameters = @{
		ScheduledTaskDefinitionSource = 'Inline' # 'XmlFile', 'InlineXml', 'Inline'
		ScheduledTaskXmlFileToImportFrom = ''
		ScheduledTaskXml = ''
		ScheduledTaskFullName = ($CommonScheduledTaskPath + 'Test-RunForAFewSecondsAndStartAfterInstall')
		ScheduledTaskDescription = 'A test task set to trigger Once at a DateTime.'
		ApplicationPathToRun = 'PowerShell.exe'
		ApplicationArguments = '-Command Start-Sleep -Seconds 10'
		WorkingDirectoryOptions = 'ApplicationDirectory' # 'ApplicationDirectory', 'CustomDirectory'
		CustomWorkingDirectory = ''
		ScheduleTriggerType = 'DateTime' # 'DateTime', 'AtLogOn', 'AtStartup'
		AtLogOnTriggerUsername = ''
		DateTimeScheduleStartTime = '2050-01-01T01:00:00'
		DateTimeScheduleFrequencyOptions = 'Once' # 'Once', 'Daily', 'Weekly'
		DateTimeScheduleFrequencyDailyInterval = ''
		DateTimeScheduleFrequencyWeeklyInterval = ''
		ShouldDateTimeScheduleFrequencyWeeklyRunOnMondaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnTuesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnWednesdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnThursdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnFridaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSaturdaysString = 'false'
		ShouldDateTimeScheduleFrequencyWeeklyRunOnSundaysString = 'false'
		ShouldScheduledTaskRunRepeatedlyString = 'false'
		ScheduleRepetitionIntervalInMinutes = ''
		ScheduleRepetitionDurationInMinutes = ''
		ScheduleStartTimeRandomDelayInMinutes = ''
		ScheduledTaskAccountToRunAsOptions = 'NetworkService' # 'System', 'LocalService', 'NetworkService', 'CustomAccount'
		CustomAccountToRunScheduledTaskAsUsername = ''
		CustomAccountToRunScheduledTaskAsPassword = ''
		ShouldScheduledTaskBeEnabledString = 'true'
		ShouldScheduledTaskRunWithHighestPrivilegesString = 'false'
		ShouldScheduledTaskRunAfterInstallString = 'true'
		ComputerNames = ''
		Username = ''
		Password = ''
		UseCredSsp = 'false'
		ProtocolOptions = 'HTTP' # 'HTTP', 'HTTPS'
		ProtocolSkipCaCheckString = 'false'
		ProtocolSkipCnCheckString = 'false'
		ProtocolSkipRevocationCheckString = 'false'
	}
}