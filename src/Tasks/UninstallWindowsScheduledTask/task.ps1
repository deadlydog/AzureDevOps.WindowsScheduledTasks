[string] $serverNames = '$(Servers)'
[string] $scheduledTaskName = '$(ScheduledTaskName)'
[string] $username = '$(UsernameToConnectToServersWith)'
[SecureString] $password = '$(PasswordToConnectToServersWith)' | ConvertTo-SecureString -AsPlainText -Force
Write-Host "Uninstalling Scheduled Task '$scheduledTaskName' on '$serverNames'."

[string[]] $servers = $serverNames -split ','
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

[hashtable] $scheduledTaskSettings = @{
	TaskName = $scheduledTaskName
}

$uninstallScheduledTaskScriptBlock = {
	param ([hashtable] $scheduledTaskSettings)
	$serverName = $Env:COMPUTERNAME

	$taskNameParts = $scheduledTaskSettings.TaskName -split '\\'
	$taskName = $taskNameParts | Select-Object -Last 1
	$taskPath = '\' + $scheduledTaskSettings.TaskName.Substring(0, $scheduledTaskSettings.TaskName.Length - $taskName.Length)

	$task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
	if ($task -eq $null)
	{
		Write-Host "A scheduled task with the path '$taskPath' and name '$taskName' was not found on server '$serverName', so no scheduled tasks will be uninstalled."
		return
	}

	Write-Host "Uninstalling Scheduled Task '$taskName' on server '$serverName'."
	$task | Disable-ScheduledTask
	$task | Stop-ScheduledTask
	$task | Unregister-ScheduledTask -Confirm:$false
}

Invoke-Command -ComputerName $servers -Credential $credential -ScriptBlock $uninstallScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose