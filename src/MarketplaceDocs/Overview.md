# Windows Scheduled Tasks

This extension provides build/release tasks that can be used to install and uninstall Windows Scheduled Tasks.


## Requirements

### Windows Version

This extension requires the computer that the Scheduled Task will be installed/uninstalled on to be Windows 8 or Windows Server 2012 or greater, as that's the first version of Windows that introduced the [ScheduledTasks PowerShell cmdlets](https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps) that this extension uses.

### CredSSP Enabled on Remote Computers

If you are connecting to a remote computer, it must have CredSSP enabled on it. You can do this by remote desktoping onto the computer and running the following command from an Admin PowerShell console:

```PowerShell
Enable-WSManCredSSP -Role Server -Force
```