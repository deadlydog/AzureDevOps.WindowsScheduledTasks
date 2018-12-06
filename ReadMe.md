# Windows Scheduled Tasks VSTS Extension

This is an VSTS extension that allows Windows Scheduled Tasks to easily be installed and uninstalled.

## Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide.

## Additional ideas to implement

* Allow XML file to be used to specify Scheduled Task parameters (allow for different credentials to run the task as).
* Allow jitter to be added to scheduled start time.
* Allow optionally using CredSSP


<!-- Links -->
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps