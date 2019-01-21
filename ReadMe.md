# Windows Scheduled Tasks Azure DevOps Extension

This is an Azure DevOps extension that allows Windows Scheduled Tasks to easily be installed and uninstalled.


## Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide.


## Additional ideas to implement

* Allow XML file to be used to specify Scheduled Task parameters (allow for different credentials to run the task as).
* Allow jitter to be added to scheduled start time.
* Allow optionally using CredSSP


## Donate

Buy me some maple syrup for providing this extension for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SW7LX32CWQJKN)


<!-- Links -->
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps