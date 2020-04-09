# Change Log

This page is a list of *notable* changes made to the Windows Scheduled Tasks Azure DevOps extension.

## April 8, 2020 - v2.0.11

- fix: Fix repetition and random delay parameters to work when using Inline Scheduled Task settings.

## April 3, 2020 - v2.0.10

- fix: Make the extension compatible with PowerShell v3.

## November 26, 2019 - v2.0.7

- fix: Use fully qualified name for `Get-ScheduledTask` to avoid conflicting with the `Carbon` module on the target servers if it's installed.

## May 15, 2019 - v2.0.0

- feature: Allow all authentication types supported by WinRM; not just CredSSP.
- UI breaking change: CredSSP checkbox was removed and replaced with a radio button of many authentication types, so had to update all task versions to v2.

## May 14, 2019 - v1.2.1

- feature: Allow connecting over the HTTPS protocol.

## March 5, 2019 - v1.1.8

- fix: Allow Scheduled Task to be started immediately after install when using XML definition.

## March 1, 2019 - v1.1.1

- feature: Add tasks for Starting and Stopping Windows Scheduled Tasks.
- feature: Update extension and task icons to better communicate what they do.

## February 28, 2019 - v1.0.13

- fix: Prevent error from being thrown when "Run after installed" is selected on the install task.

## February 24, 2019 - v1.0.0

- Extension released publicly.
- Supports Installing, Uninstalling, Enabling, and Disabling Windows Scheduled Tasks.
