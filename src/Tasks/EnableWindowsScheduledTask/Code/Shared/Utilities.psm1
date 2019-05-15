# This file should only be modified if it is the one in the `SharedTaskCode` directory.
# Otherwise changes here will be overwritten the next time the Copy Files script is ran.

function Get-BoolValueFromString([string] $string, [switch] $required)
{
	if ([string]::IsNullOrWhiteSpace($string) -and $required.IsPresent)
	{
		throw 'A non-empty string must be provided when calling Get-BoolValueFromString.'
	}

	if ($string -ieq 'true')
	{
		return $true
	}
	return $false
}

function Get-XmlStringFromFile([string] $xmlFilePath)
{
	[string] $xml = [string]::Empty
	if (![string]::IsNullOrWhiteSpace($xmlFilePath))
	{
		if (!(Test-Path -Path $xmlFilePath -PathType Leaf))
		{
			throw "Could not find the specified XML file '$xmlFilePath' to read the Scheduled Task definition from."
		}

		Write-Verbose "Reading XML from file '$xmlFilePath'." -Verbose
		$xml = Get-Content -Path $xmlFilePath -Raw
	}
	return $xml
}

Export-ModuleMember -Function Get-BoolValueFromString
Export-ModuleMember -Function Get-XmlStringFromFile
