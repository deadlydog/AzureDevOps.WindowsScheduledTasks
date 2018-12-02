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

	# Ensure required file paths exist.
	if (!(Test-Path -Path $extensionJsonFilePath -PathType Leaf)) { throw "The file '$extensionJsonFilePath' does not exist, so exiting."}
	$taskJsonFilePaths | ForEach-Object {
		$taskJsonFilePath = $_
		if (!(Test-Path -Path $taskJsonFilePath -PathType Leaf)) { throw "The file '$taskJsonFilePath' does not exist, so exiting."}
	}

	# Get the current version and new version to use.
	[VersionNumber] $extensionVersionNumber = Get-ExtensionVersionNumber -extensionJsonFilePath $extensionJsonFilePath
	[VersionNumber] $newVersionNumberToUse = Prompt-UserForNewVersionNumber -currentVersion $extensionVersionNumber

	# Update the version in the files.
	Set-ExtensionVersionNumber -extensionJsonFilePath $extensionJsonFilePath -versionNumber $newVersionNumberToUse
	Set-TaskVersionNumber -taskJsonFilePaths $taskJsonFilePaths -versionNumber $newVersionNumberToUse

	Write-Output "The version field of all files has been updated to '$newVersionNumberToUse'."
}

Begin
{
	[string] $THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot

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
		[string] $jsonText = ConvertTo-Json -InputObject $json
		Set-Content -Path $jsonFilePath -Value $jsonText
	}

	function Prompt-UserForNewVersionNumber([VersionNumber] $currentVersion)
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

		Write-Verbose "New version to use is: $newVersionNumber" -Verbose

		return $newVersionNumber
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