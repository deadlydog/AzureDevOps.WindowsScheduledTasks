[CmdletBinding()]
param
(
	[string] $TasksDirectory
)

$ErrorActionPreference = 'Stop'
if (!$PSBoundParameters.ContainsKey('TasksDirectory'))
{
	$TasksDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'src\Tasks'
}
$sdkVersion = '0.21.8'
$taskDirectories = @(Get-ChildItem -LiteralPath $TasksDirectory -Directory | Where-Object {
	Test-Path -LiteralPath (Join-Path $_.FullName 'task.json') -PathType Leaf
})
if ($taskDirectories.Count -eq 0)
{
	throw "No task definitions were found in '$TasksDirectory'."
}

$downloadDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$null = New-Item -Path $downloadDirectory -ItemType Directory
try
{
	Save-Module -Name VstsTaskSdk -RequiredVersion $sdkVersion -Repository PSGallery -Path $downloadDirectory -Force
	$sdkDirectory = Join-Path $downloadDirectory "VstsTaskSdk\$sdkVersion"
	$sdkManifest = Join-Path $sdkDirectory 'VstsTaskSdk.psd1'
	if (!(Test-Path -LiteralPath $sdkManifest -PathType Leaf))
	{
		throw "The restored VstsTaskSdk $sdkVersion manifest was not found at '$sdkManifest'."
	}

	foreach ($taskDirectory in $taskDirectories)
	{
		$moduleDirectory = Join-Path $taskDirectory.FullName 'ps_modules\VstsTaskSdk'
		if (Test-Path -LiteralPath $moduleDirectory)
		{
			Remove-Item -LiteralPath $moduleDirectory -Recurse -Force
		}
		$null = New-Item -Path $moduleDirectory -ItemType Directory -Force
		Get-ChildItem -LiteralPath $sdkDirectory -Force | Copy-Item -Destination $moduleDirectory -Recurse -Force
		if (!(Test-Path -LiteralPath (Join-Path $moduleDirectory 'VstsTaskSdk.psd1') -PathType Leaf))
		{
			throw "VstsTaskSdk was not bundled for task '$($taskDirectory.Name)'."
		}
		Write-Verbose "Bundled VstsTaskSdk $sdkVersion for '$($taskDirectory.Name)'." -Verbose
	}
}
finally
{
	Remove-Item -LiteralPath $downloadDirectory -Recurse -Force
}
