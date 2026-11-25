$ErrorActionPreference = 'Stop'
Trace-VstsEnteringInvocation $MyInvocation
$originalLocation = Get-Location

try
{
	Set-Location -LiteralPath $PSScriptRoot
	$taskDefinition = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'task.json') -Raw | ConvertFrom-Json
	$taskParameters = @{}
	foreach ($taskInput in $taskDefinition.inputs)
	{
		$value = Get-VstsInput -Name $taskInput.name -Require:($taskInput.name -in @('ScheduledTaskFullName', 'ScheduledTaskDefinitionSource'))
		if (![string]::IsNullOrEmpty($value))
		{
			$taskParameters[$taskInput.name] = $value
		}
	}

	& (Join-Path $PSScriptRoot 'Code\Install-WindowsScheduledTask-TaskEntryPoint.ps1') @taskParameters
}
finally
{
	Set-Location -LiteralPath $originalLocation.Path
	Trace-VstsLeavingInvocation $MyInvocation
}
