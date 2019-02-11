# Windows Scheduled Tasks Azure DevOps Extension

This is an Azure DevOps extension that allows Windows Scheduled Tasks to easily be installed and uninstalled.

Build status: [![Build Status](https://dev.azure.com/deadlydog/AzureDevOps.WindowsScheduledTasks/_apis/build/status/deadlydog.AzureDevOps.WindowsScheduledTasks?branchName=master)](https://dev.azure.com/deadlydog/AzureDevOps.WindowsScheduledTasks/_build/latest?definitionId=17?branchName=master)


## Defining the Scheduled Task definition properties inline vs. using an XML file

Reasons you may want to define all of the properties inline in the Build/Release task:

* Convenience and ease of use

Reasons you may want to use an XML file instead:

* Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use an XML file.
* Using an XML file allows you to have the Scheduled Task definition committed to source control so you can track changes to it.

When using an XML file you will still need to define inline the `Scheduled Task Name` and `User To Run As`.

### How to create your Scheduled Task XML definition file

If your Scheduled Task already exists in the Windows `Task Scheduler`, simply right-click on the Scheduled Task and choose `Export`.

![Export Windows Scheduled Task screenshot][ExportWindowsScheduledTaskScreenshotImage]

If your Scheduled Task does not already exist, create a new Scheduled Task in the Windows `Task Scheduler`, configure it the way you want, test it (if possible), and the export the XML file.

If you prefer, you can also [export the Scheduled Task via the `Export-ScheduledTask` PowerShell cmdlet][PowerShellExportScheduledTaskDocumentationUrl].


## Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide.


## Additional ideas to implement

* Allow task to be deleted immediately after installing it and running it.


## Donate

Buy me some maple syrup for providing this extension for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SW7LX32CWQJKN)


<!-- Links -->
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps
[PowerShellExportScheduledTaskDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/export-scheduledtask?view=win10-ps
[ExportWindowsScheduledTaskScreenshotImage]: src/Images/ExportWindowsScheduledTaskScreenshot.png