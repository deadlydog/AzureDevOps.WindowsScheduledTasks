Import-Module -Name Pester -RequiredVersion 4.10.1 -ErrorAction Stop

$repositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$tasksDirectory = Join-Path $repositoryRoot 'src\Tasks'
$restoreScript = Join-Path $repositoryRoot 'build\Restore-TaskSdk.ps1'
$testState = @{ InputValues = @{}; DownloadDirectory = $null }
$taskCases = @(Get-ChildItem -LiteralPath $tasksDirectory -Directory | ForEach-Object {
	@{ TaskName = $_.Name }
})

Describe 'PowerShell3 task entry points' {
	function Get-VstsInput { param($Name, [switch] $Require) }
	function Trace-VstsEnteringInvocation { param($InvocationInfo) }
	function Trace-VstsLeavingInvocation { param($InvocationInfo) }

	function New-TaskFixture([string] $taskName)
	{
		$sourceDirectory = Join-Path $tasksDirectory $taskName
		$definition = Get-Content -LiteralPath (Join-Path $sourceDirectory 'task.json') -Raw | ConvertFrom-Json
		$definition.execution.PSObject.Properties.Name | Should -Be 'PowerShell3'
		$target = $definition.execution.PowerShell3.target
		(Split-Path $target -Leaf) | Should -Be $target

		$fixtureDirectory = Join-Path $TestDrive $taskName
		$null = New-Item -Path (Join-Path $fixtureDirectory 'Code') -ItemType Directory -Force
		Copy-Item -LiteralPath (Join-Path $sourceDirectory $target) -Destination $fixtureDirectory -Force
		Copy-Item -LiteralPath (Join-Path $sourceDirectory 'task.json') -Destination $fixtureDirectory -Force

		$implementationName = $target.Replace('.ps1', '-TaskEntryPoint.ps1')
		$sourceImplementation = Join-Path $sourceDirectory "Code\$implementationName"
		$tokens = $null
		$parseErrors = $null
		$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourceImplementation, [ref] $tokens, [ref] $parseErrors)
		$parseErrors | Should -BeNullOrEmpty
		$implementation = Join-Path $fixtureDirectory "Code\$implementationName"
		# Keep the real parameter validation without manipulating Windows Scheduled Tasks.
		$stub = $ast.ParamBlock.Extent.Text + @'

[pscustomobject] @{
	Parameters = $PSBoundParameters
	WorkingDirectory = (Get-Location).Path
}
'@
		Set-Content -LiteralPath $implementation -Value $stub

		$testState.InputValues = @{}
		foreach ($taskInput in $definition.inputs)
		{
			$testState.InputValues[$taskInput.name] = $taskInput.defaultValue
		}
		$testState.InputValues.ScheduledTaskFullName = 'Folder\Task*'
		if ($taskName -eq 'InstallWindowsScheduledTask')
		{
			$testState.InputValues.ScheduledTaskDefinitionSource = 'InlineXml'
		}

		return @{
			EntryPoint = Join-Path $fixtureDirectory $target
			Implementation = $implementation
			Directory = $fixtureDirectory
			Definition = $definition
		}
	}

	BeforeEach {
		Mock Get-VstsInput {
			param($Name, [switch] $Require)
			if ($Require -and [string]::IsNullOrEmpty($testState.InputValues[$Name]))
			{
				throw "Required input '$Name' is missing."
			}
			return $testState.InputValues[$Name]
		}
		Mock Trace-VstsEnteringInvocation {}
		Mock Trace-VstsLeavingInvocation {}
	}

	It '<TaskName> forwards SDK inputs unchanged and restores the working directory' -TestCases $taskCases {
		param($TaskName)
		$fixture = New-TaskFixture $TaskName
		$testState.InputValues.ComputerNames = 'server1, server2'
		$testState.InputValues.Password = ' p''ass"$();`word '
		$testState.InputValues.ProtocolSkipCaCheckString = 'true'
		if ($TaskName -eq 'InstallWindowsScheduledTask')
		{
			$testState.InputValues.ScheduledTaskXml = "<Task>`r`n  <Description>O'Brien</Description>`r`n</Task>"
			$testState.InputValues.ScheduledTaskXmlFileToImportFrom = 'relative path\[task].xml'
			$testState.InputValues.ApplicationArguments = '--name "two words" $literal; &'
			$testState.InputValues.CustomAccountToRunScheduledTaskAsPassword = ' another secret '
		}
		$originalDirectory = (Get-Location).Path

		$result = & $fixture.EntryPoint

		foreach ($name in $testState.InputValues.Keys)
		{
			if (![string]::IsNullOrEmpty($testState.InputValues[$name]))
			{
				$result.Parameters[$name] | Should -BeExactly $testState.InputValues[$name]
			}
		}
		$result.Parameters.ContainsKey('Username') | Should -BeFalse
		$result.Parameters.ProtocolSkipCnCheckString | Should -BeExactly 'false'
		$result.WorkingDirectory | Should -Be $fixture.Directory
		(Get-Location).Path | Should -Be $originalDirectory
		Assert-MockCalled Get-VstsInput -Times $fixture.Definition.inputs.Count -Exactly -Scope It
		Assert-MockCalled Trace-VstsEnteringInvocation -Times 1 -Exactly -Scope It
		Assert-MockCalled Trace-VstsLeavingInvocation -Times 1 -Exactly -Scope It
	}

	It '<TaskName> propagates implementation failures and still cleans up' -TestCases $taskCases {
		param($TaskName)
		$fixture = New-TaskFixture $TaskName
		Add-Content -LiteralPath $fixture.Implementation -Value "throw 'Implementation failed.'"
		$originalDirectory = (Get-Location).Path

		{ & $fixture.EntryPoint } | Should -Throw 'Implementation failed.'

		(Get-Location).Path | Should -Be $originalDirectory
		Assert-MockCalled Trace-VstsLeavingInvocation -Times 1 -Exactly -Scope It
	}

	It '<TaskName> rejects a missing task name without prompting' -TestCases $taskCases {
		param($TaskName)
		$fixture = New-TaskFixture $TaskName
		$testState.InputValues.ScheduledTaskFullName = ''
		$originalDirectory = (Get-Location).Path

		{ & $fixture.EntryPoint } | Should -Throw "Required input 'ScheduledTaskFullName'"

		(Get-Location).Path | Should -Be $originalDirectory
		Assert-MockCalled Trace-VstsLeavingInvocation -Times 1 -Exactly -Scope It
	}

	It 'accepts <Source> installation inputs without requiring hidden fields' -TestCases @(
		@{ Source = 'XmlFile' }
		@{ Source = 'InlineXml' }
		@{ Source = 'Inline' }
	) {
		param($Source)
		$fixture = New-TaskFixture 'InstallWindowsScheduledTask'
		$testState.InputValues.ScheduledTaskDefinitionSource = $Source
		$testState.InputValues.ScheduledTaskXmlFileToImportFrom = ''
		$testState.InputValues.ScheduledTaskXml = ''
		$testState.InputValues.WorkingDirectoryOptions = ''
		$testState.InputValues.ScheduleTriggerType = ''
		$testState.InputValues.DateTimeScheduleFrequencyOptions = ''
		if ($Source -eq 'XmlFile')
		{
			$testState.InputValues.ScheduledTaskXmlFileToImportFrom = 'relative path\task.xml'
		}
		elseif ($Source -eq 'InlineXml')
		{
			$testState.InputValues.ScheduledTaskXml = '<Task />'
		}
		else
		{
			$testState.InputValues.ApplicationPathToRun = 'C:\Program Files\Application.exe'
			$testState.InputValues.WorkingDirectoryOptions = 'ApplicationDirectory'
			$testState.InputValues.ScheduleTriggerType = 'AtStartup'
		}

		$result = & $fixture.EntryPoint

		$result.Parameters.ScheduledTaskDefinitionSource | Should -Be $Source
		Assert-MockCalled Get-VstsInput -Times 0 -Exactly -Scope It -ParameterFilter {
			$Require -and $Name -notin @('ScheduledTaskFullName', 'ScheduledTaskDefinitionSource')
		}
	}

	It 'rejects a missing installation definition source without prompting' {
		$fixture = New-TaskFixture 'InstallWindowsScheduledTask'
		$testState.InputValues.ScheduledTaskDefinitionSource = ''

		{ & $fixture.EntryPoint } | Should -Throw "Required input 'ScheduledTaskDefinitionSource'"
	}

	It 'preserves the implementation scripts authentication validation' {
		$fixture = New-TaskFixture 'StartWindowsScheduledTask'
		$testState.InputValues.AuthenticationOptions = 'NotAnAuthenticationMechanism'

		{ & $fixture.EntryPoint } | Should -Throw 'ValidateSet'
	}
}

Describe 'Bundling the PowerShell task SDK' {
	BeforeEach {
		$testState.DownloadDirectory = $null
		Mock Save-Module {
			param($Name, $RequiredVersion, $Repository, $Path)
			$testState.DownloadDirectory = $Path
			$moduleDirectory = Join-Path $Path "VstsTaskSdk\$RequiredVersion"
			$null = New-Item -Path (Join-Path $moduleDirectory 'Strings') -ItemType Directory -Force
			Set-Content -LiteralPath (Join-Path $moduleDirectory 'VstsTaskSdk.psd1') -Value "@{ ModuleVersion = '$RequiredVersion' }"
			Set-Content -LiteralPath (Join-Path $moduleDirectory 'VstsTaskSdk.psm1') -Value '# SDK fixture'
			Set-Content -LiteralPath (Join-Path $moduleDirectory 'Strings\resources.resjson') -Value '{}'
		}
	}

	It 'copies a flattened SDK and its supporting files to every task and replaces stale files' {
		$fixtureTasks = Join-Path $TestDrive 'Tasks'
		foreach ($name in @('FirstTask', 'SecondTask'))
		{
			$taskDirectory = Join-Path $fixtureTasks $name
			$null = New-Item -Path (Join-Path $taskDirectory 'ps_modules\VstsTaskSdk') -ItemType Directory -Force
			Set-Content -LiteralPath (Join-Path $taskDirectory 'task.json') -Value '{}'
			Set-Content -LiteralPath (Join-Path $taskDirectory 'ps_modules\VstsTaskSdk\stale.txt') -Value 'old SDK'
		}

		& $restoreScript -TasksDirectory $fixtureTasks

		foreach ($name in @('FirstTask', 'SecondTask'))
		{
			$moduleDirectory = Join-Path $fixtureTasks "$name\ps_modules\VstsTaskSdk"
			Test-Path -LiteralPath (Join-Path $moduleDirectory 'VstsTaskSdk.psd1') | Should -BeTrue
			Test-Path -LiteralPath (Join-Path $moduleDirectory 'VstsTaskSdk.psm1') | Should -BeTrue
			Test-Path -LiteralPath (Join-Path $moduleDirectory 'Strings\resources.resjson') | Should -BeTrue
			Test-Path -LiteralPath (Join-Path $moduleDirectory 'stale.txt') | Should -BeFalse
		}
		Assert-MockCalled Save-Module -Times 1 -Exactly -Scope It
		Test-Path -LiteralPath $testState.DownloadDirectory | Should -BeFalse
	}

	It 'fails instead of packaging an SDK with a missing manifest' {
		$fixtureTasks = Join-Path $TestDrive 'MissingManifestTasks'
		$null = New-Item -Path (Join-Path $fixtureTasks 'Task') -ItemType Directory -Force
		Set-Content -LiteralPath (Join-Path $fixtureTasks 'Task\task.json') -Value '{}'
		Mock Save-Module { param($Path) $testState.DownloadDirectory = $Path }

		{ & $restoreScript -TasksDirectory $fixtureTasks } | Should -Throw 'manifest was not found'

		Test-Path -LiteralPath $testState.DownloadDirectory | Should -BeFalse
		Test-Path -LiteralPath (Join-Path $fixtureTasks 'Task\ps_modules') | Should -BeFalse
	}

	It 'propagates download failures and removes its temporary directory' {
		Mock Save-Module {
			param($Path)
			$testState.DownloadDirectory = $Path
			throw 'SDK download failed.'
		}

		{ & $restoreScript -TasksDirectory $tasksDirectory } | Should -Throw 'SDK download failed.'

		Test-Path -LiteralPath $testState.DownloadDirectory | Should -BeFalse
	}

	It 'stops manual packaging on SDK download failure before prompting for a version' {
		Mock Save-Module { throw 'SDK download failed.' }
		Mock Read-Host { throw 'Unexpected version prompt.' }
		$newVersionScript = Join-Path $repositoryRoot 'build\New-Version.ps1'

		{ & $newVersionScript } | Should -Throw 'SDK download failed.'

		Assert-MockCalled Read-Host -Times 0 -Exactly -Scope It
	}
}
