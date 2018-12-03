Process
{
	# Get required file paths.
	[string] $gitRepoRoot = Split-Path -Path $THIS_SCRIPTS_DIRECTORY_PATH -Parent
	[string] $srcDirectoryPath = Join-Path $gitRepoRoot -ChildPath 'src'
	[string] $extensionJsonFilePath = Join-Path $srcDirectoryPath -ChildPath 'vss-extension.json'
	[string[]] $taskJsonFilePaths = @(
		Join-Path -Path $srcDirectoryPath -ChildPath 'Tasks\InstallWindowsScheduledTask\task.json'
		Join-Path -Path $srcDirectoryPath -ChildPath 'Tasks\UninstallWindowsScheduledTask\task.json'
	)

	Confirm-RequiredFilesExist -extensionJsonFilePath $extensionJsonFilePath -taskJsonFilePaths $taskJsonFilePaths

	Set-VersionNumberInFiles -extensionJsonFilePath $extensionJsonFilePath -taskJsonFilePaths $taskJsonFilePaths

	New-VsixPackage -extensionJsonFilePath $extensionJsonFilePath
}

Begin
{
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot

	function Confirm-RequiredFilesExist([string] $extensionJsonFilePath, [string[]] $taskJsonFilePaths)
	{
		if (!(Test-Path -Path $extensionJsonFilePath -PathType Leaf))
		{
			throw "The file '$extensionJsonFilePath' does not exist, so exiting."
		}

		$taskJsonFilePaths | ForEach-Object {
			$taskJsonFilePath = $_
			if (!(Test-Path -Path $taskJsonFilePath -PathType Leaf))
			{
				throw "The file '$taskJsonFilePath' does not exist, so exiting."
			}
		}
	}

	function Set-VersionNumberInFiles([string] $extensionJsonFilePath, [string[]] $taskJsonFilePaths)
	{
		# Get the current version and new version to use.
		[VersionNumber] $extensionVersionNumber = Get-ExtensionVersionNumber -extensionJsonFilePath $extensionJsonFilePath
		[VersionNumber] $newVersionNumberToUse = Read-NewVersionNumberFromUser -currentVersion $extensionVersionNumber

		# Update the version in the files.
		Set-ExtensionVersionNumber -extensionJsonFilePath $extensionJsonFilePath -versionNumber $newVersionNumberToUse
		Set-TaskVersionNumber -taskJsonFilePaths $taskJsonFilePaths -versionNumber $newVersionNumberToUse

		Write-Output "The version field of all files has been updated to '$newVersionNumberToUse'."
	}

	function Get-ExtensionVersionNumber([ValidateScript({Test-Path -Path $_ -PathType Leaf})][string] $extensionJsonFilePath)
	{
		[PSCustomObject] $json = Read-JsonFromFile -jsonFilePath $extensionJsonFilePath
		[string] $version = $json.version
		[VersionNumber] $versionNumber = [VersionNumber]::new($version)
		return $versionNumber
	}

	function Set-ExtensionVersionNumber([ValidateScript({Test-Path -Path $_ -PathType Leaf})][string] $extensionJsonFilePath, [VersionNumber] $versionNumber)
	{
		[PSCustomObject] $json = Read-JsonFromFile -jsonFilePath $extensionJsonFilePath
		$json.version = $versionNumber.ToString()
		Write-Verbose "Updating the version field of file '$extensionJsonFilePath' to '$versionNumber'." -Verbose
		Write-JsonToFile -jsonFilePath $extensionJsonFilePath -json $json
	}

	function Set-TaskVersionNumber([ValidateScript({$_ | Test-Path -PathType Leaf})][string[]] $taskJsonFilePaths, [VersionNumber] $versionNumber)
	{
		$taskJsonFilePaths | ForEach-Object {
			[string] $taskJsonFilePath = $_

			[PSCustomObject] $json = Read-JsonFromFile -jsonFilePath $taskJsonFilePath
			$json.version = $versionNumber
			Write-Verbose "Updating the version field of file '$taskJsonFilePath' to '$versionNumber'." -Verbose
			Write-JsonToFile -jsonFilePath $taskJsonFilePath -json $json
		}
	}

	function Read-JsonFromFile([ValidateScript({Test-Path -Path $_ -PathType Leaf})][string] $jsonFilePath)
	{
		[string] $jsonText = Get-Content -Path $extensionJsonFilePath -Raw
		[PSCustomObject] $jsonContents = ConvertFrom-Json -InputObject $jsonText
		return $jsonContents
	}

	function Write-JsonToFile([string] $jsonFilePath, [PSCustomObject] $json)
	{
		[string] $jsonText = (ConvertTo-Json -InputObject $json -Depth 99) | Format-Json
		Set-Content -Path $jsonFilePath -Value $jsonText
	}

	function Read-NewVersionNumberFromUser([VersionNumber] $currentVersion)
	{
		[string] $newVersionToUse = Read-Host -Prompt "What should the new version be? Current version is '$currentVersion'. Version must have 3 parts (e.g. Major.Minor.Patch). Leave blank to just increment Patch version"

		[VersionNumber] $newVersionNumber = $null
		if ([string]::IsNullOrWhiteSpace($newVersionToUse))
		{
			$newVersionNumber = [VersionNumber]::new($currentVersion)
			$newVersionNumber.Patch = $newVersionNumber.Patch + 1
		}
		else
		{
			$newVersionNumber = [VersionNumber]::new($newVersionToUse)
		}

		Write-Verbose "New version specified to use is: $newVersionNumber" -Verbose

		return $newVersionNumber
	}

	# Formats JSON in a nicer format than the built-in ConvertTo-Json does.
	# Code take from: https://github.com/PowerShell/PowerShell/issues/2736
	function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json)
	{
		$indent = 0;
		($json -Split [System.Environment]::NewLine | ForEach-Object {
			if ($_ -match '[\}\]]')
			{
				# This line contains  ] or }, decrement the indentation level
				$indent--
			}
			$line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
			if ($_ -match '[\{\[]')
			{
				# This line contains [ or {, increment the indentation level
				$indent++
			}
			$line
		}) -Join [System.Environment]::NewLine
	}

	function New-VsixPackage([ValidateScript({Test-Path -Path $_ -PathType Leaf})][string] $extensionJsonFilePath)
	{
		Write-Verbose "Creating new vsix extension package file." -Verbose
		[string] $parentDirectoryPath = Split-Path -Path $extensionJsonFilePath -Parent
		Set-Location $parentDirectoryPath
		tfx extension create --manifest-globs "$extensionJsonFilePath"
	}

	class VersionNumber
	{
		[int] $Major
		[int] $Minor
		[int] $Patch

		VersionNumber([string] $version)
		{
			[VersionNumber]::ValidateVersionString($version)

			[string[]] $versionParts = $version -split '\.'
			$this.Major = $versionParts[0]
			$this.Minor = $versionParts[1]
			$this.Patch = $versionParts[2]
		}

		VersionNumber([int] $major, [int] $minor, [int] $patch)
		{
			$this.Major = $major
			$this.Minor = $minor
			$this.Patch = $patch
		}

		[string] ToString()
		{
			[string] $majorPart = $this.Major
			[string] $minorPart = $this.Minor
			[string] $patchPart = $this.Patch
			return "$majorPart.$minorPart.$patchPart"
		}

		static [void] ValidateVersionString([string] $version)
		{
			[string] $versionNumberRegex = '^\d+\.\d+\.\d+$'
			if (!($version -match $versionNumberRegex))
			{
				throw "The version number '$version' is not valid. Version numbers must have 3 parts. e.g. Major.Minor.Patch"
			}
		}
	}
}