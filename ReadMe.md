# Windows Scheduled Tasks Azure DevOps Extension

This [Azure DevOps (i.e. TFS) extension][ExtensionInAzureDevOpsMarketplaceUrl] provides Build and Release Pipeline tasks that allow Windows Scheduled Tasks to easily be installed, uninstalled, enabled, and disabled on the local or remote computer(s).

Current build status: [![Build Status](https://dev.azure.com/deadlydog/OpenSource/_apis/build/status/AzureDevOps.WindowsScheduledTasks?branchName=master)](https://dev.azure.com/deadlydog/OpenSource/_build/latest?definitionId=19&branchName=master)
[![Deployment Status](https://vsrm.dev.azure.com/deadlydog/_apis/public/Release/badge/baf297a4-1582-49bd-b9ca-6d38492faafa/1/1)](https://dev.azure.com/deadlydog/OpenSource/_release?definitionId=1)

## Features

- Install a Windows Scheduled Task by specifying properties inline, XML inline, or from an XML file.
  - Replace an existing Windows Scheduled Task of the same name by overwriting it.
- Enable, Disable, and Uninstall a Windows Scheduled Task.
  - Supports wildcards for modifying many Schedules Tasks easily, or when you only know part of the Scheduled Task's name.
- Multiple computers can be specified to easily run the task against all of them.
- Supports connecting to remote computers via WinRM and optionally using [CredSSP][CredSspDocumentationUrl].

## Requirements

The computer that will be hosting the Windows Scheduled Task must meet the following minimum requirements:

- Be running Windows 8 or Windows Server 2012 or higher ([the PowerShell cmdlets used by this task][PowerShellScheduledTasksDocumentationUrl] were introduced in these versions).

If the Windows Scheduled Task is on a remote computer, it must also meet these requirements:

- Have Windows Remote Management 3.0 or later installed, as Windows PowerShell uses WinRM to connect to remote computers.
- You may need to enable PowerShell Remoting on the remote computer by running `Enable-PSRemoting` from an administrator PowerShell command prompt on the remote computer.

For more information, [read Microsoft's documentation][PowerShellRemotingRequirementsDocumentationUrl].

### Connecting to a remote computer with CredSSP

If you are connecting to a remote computer and want to use CredSSP, it must have CredSSP enabled on it. You can do this by running the following command from an administrator PowerShell command prompt on the remote computer:

```PowerShell
Enable-WSManCredSSP -Role Server -Force
```

## Defining the Scheduled Task definition properties

Reasons you may want to define all of the properties `Inline` in the Build/Release task:

- Convenience and ease of use; no need to generate XML.
- No need to include an XML file in your source control or build artifacts for the deployment to use.

Reasons you may want to use `Inline XML`:

- Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use XML.
- No need to include an XML file in your source control or build artifacts for the deployment to use.

Reasons you may want to use an `XML file`:

- Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use XML.
- Using an XML file allows you to have the Scheduled Task definition committed to source control alongside your code so you can track changes to it.

When using XML you will still need to specify the `Scheduled Task Name` and `User To Run As`.

### How to create your Scheduled Task XML definition file

If your Scheduled Task already exists in the Windows `Task Scheduler`, simply right-click on the Scheduled Task and choose `Export`.

![Export Windows Scheduled Task screenshot][ExportWindowsScheduledTaskScreenshotImage]

If your Scheduled Task does not already exist, create a new Scheduled Task in the Windows `Task Scheduler`, configure it the way you want, test it (if possible), and the export the XML file.

If you prefer, you can also export the Scheduled Task via [the `Export-ScheduledTask` PowerShell cmdlet][PowerShellExportScheduledTaskDocumentationUrl].

## Feedback

Ratings and feedback are very much appreciated. If you have a spare moment, please [leave a review][ExtensionRatingAndReviewInAzureDevOpsMarketplaceUrl].

If you encounter problems or would like to request new features, please do so on [the GitHub issues page][ExtensionGitHubRepositoryIssuesUrl], as it facilitates discussions much better than the marketplace Q&A and Rating/Review pages.

### Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide.

### Additional ideas to implement

- Allow task to be deleted immediately after installing it and running it.
- Add option to allow using SSL.
- Add Start and Stop tasks for running and stopping existing Scheduled Tasks.

## Donate

Buy me some maple syrup for providing this extension open source and for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SW7LX32CWQJKN)

<!-- Links -->
[ExtensionInAzureDevOpsMarketplaceUrl]: https://marketplace.visualstudio.com/items?itemName=deadlydog.WindowsScheduledTasksBuildAndReleaseTasks
[ExtensionGitHubRepositoryIssuesUrl]: https://github.com/deadlydog/AzureDevOps.WindowsScheduledTasks/issues
[ExtensionRatingAndReviewInAzureDevOpsMarketplaceUrl]: https://marketplace.visualstudio.com/items?itemName=deadlydog.WindowsScheduledTasksBuildAndReleaseTasks#review-details
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps
[PowerShellExportScheduledTaskDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/export-scheduledtask?view=win10-ps
[CredSspDocumentationUrl]: https://docs.microsoft.com/en-us/windows/desktop/secauthn/credential-security-support-provider
[PowerShellRemotingRequirementsDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_requirements?view=powershell-6
[ExportWindowsScheduledTaskScreenshotImage]: src/Images/ExportWindowsScheduledTaskScreenshot.png