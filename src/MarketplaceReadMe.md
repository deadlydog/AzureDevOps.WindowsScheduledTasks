# Windows Scheduled Tasks

This Azure DevOps (i.e. TFS) extension provides Build and Release Pipeline tasks that allow Windows Scheduled Tasks to easily be installed, uninstalled, enabled, and disabled on the local or remote computer(s).

## Features

- Install a Windows Scheduled Task by specifying properties inline, XML inline, or from an XML file.
- Replace an existing Windows Scheduled Task by overwriting it.
- Enable, Disable, and Uninstall a Windows Scheduled Task.
  - Supports wildcards for modifying many Schedules Tasks easily, or when you only know part of the Scheduled Task's name.
- Multiple computers can be specified to easily run the task against all of them.
- Supports connecting to remote computers via WinRM and optionally using [CredSSP][CredSspDocumentationUrl].

## Target computer requirements

The computer that is or will be hosting the Windows Scheduled Task must meet the following minimum requirements:

- Be running Windows 8 or Windows Server 2012 or higher ([the PowerShell cmdlets used by this task][PowerShellScheduledTasksDocumentationUrl] were introduced in these versions).
- Have Windows Remote Management 3.0 or later installed (for remote computers, as Windows PowerShell uses WinRM to connect to remote computers).
- You may need to enable PowerShell Remoting on the remote computer by running `Enable-PSRemoting` from an administrator PowerShell command prompt on the remote computer (for remote computers).

For more information, [read Microsoft's documentation][PowerShellRemotingRequirementsDocumentationUrl].

### Connecting to a remote computer with CredSSP

If you are connecting to a remote computer and want to use CredSSP, it must have CredSSP enabled on it. You can do this by running the following command from an administrator PowerShell command prompt on the remote computer:

```PowerShell
Enable-WSManCredSSP -Role Server -Force
```

## Defining the Scheduled Task definition properties inline vs. using an XML file

Reasons you may want to define all of the properties inline in the Build/Release task:

- Convenience and ease of use; no need to general XML.
- No need to include an XML file in your source control or build artifacts for the deployment to use.

Reasons you may want to use inline XML:

- Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use XML.
- No need to include an XML file in your source control or build artifacts for the deployment to use.

Reasons you may want to use an XML file:

- Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use XML.
- Using an XML file allows you to have the Scheduled Task definition committed to source control alongside your code so you can track changes to it.

When using XML you will still need to specify the `Scheduled Task Name` and `User To Run As`.

### How to create your Scheduled Task XML definition file

If your Scheduled Task already exists in the Windows `Task Scheduler`, simply right-click on the Scheduled Task and choose `Export`.

![Export Windows Scheduled Task screenshot][ExportWindowsScheduledTaskScreenshotImage]

If your Scheduled Task does not already exist, create a new Scheduled Task in the Windows `Task Scheduler`, configure it the way you want, test it (if possible), and the export the XML file.

If you prefer, you can also export the Scheduled Task via [the `Export-ScheduledTask` PowerShell cmdlet][PowerShellExportScheduledTaskDocumentationUrl].

## Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide.

## Additional ideas to implement

- Allow task to be deleted immediately after installing it and running it.
- Support task having multiple actions when specifying properties inline.
- Add option to allow using SSL.

## Donate

Buy me some maple syrup for providing this extension open source and for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SW7LX32CWQJKN)

<!-- Links -->
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps
[PowerShellExportScheduledTaskDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/export-scheduledtask?view=win10-ps
[CredSspDocumentationUrl]: https://docs.microsoft.com/en-us/windows/desktop/secauthn/credential-security-support-provider
[PowerShellRemotingRequirementsDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_requirements?view=powershell-6
[ExportWindowsScheduledTaskScreenshotImage]: Images/ExportWindowsScheduledTaskScreenshot.png