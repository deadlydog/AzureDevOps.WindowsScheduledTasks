# How to build and publish the Azure DevOps extension's VSIX package

## Automated builds and deployment

The building and publishing of this extension is fully automated via Azure DevOps [build](/pipelines/azure-devops-build.yaml) and release pipelines.

Every time a change is committed to the `main` branch [a new build][AzureDevOpsBuildPipelineUrl] is made.

If the build succeeds, [a new release][AzureDevOpsReleasePipelineUrl] will automatically be created which will publish the new version to a private extension on the marketplace and integration tests will run against it. If those succeed, the release can be manually approved to publish it to [the Azure DevOps marketplace][ExtensionsAzureDevOpsMarketplaceUrl].

## Manual builds and deployments

If you want to manually build and publish a new version of the extension, you can follow these steps.

### Prerequisites

You need to have Node.js installed. [Get it here][NodeJsDownloadUrl].

You also need Windows PowerShell with PowerShellGet (`Save-Module`) and access to the PowerShell Gallery during the build.

Once node is installed, install the TFS Cross Platform Command Line Interface (tfx-cli) with the command:

```cmd
npm i -g tfx-cli
```

### Creating the VSIX package

#### Automated process to create the VSIX package

You can simply run the `New-Version.ps1` script to create a new VSIX package.
It will prompt you for the version number, and then create the VSIX file for you.
It also runs `Restore-TaskSdk.ps1` to bundle the PowerShell task SDK before packaging.

#### Manual process to create the VSIX package

Before creating the VSIX package be sure to update the `version` element in the `vss-extension.json` and `task.json` files appropriately.

From the repository root, first restore the task SDK:

```PowerShell
.\build\Restore-TaskSdk.ps1
```

To create the VSIX package file, run the following command from the directory containing the `vss-extension.json` file:

```cmd
tfx extension create --manifest-globs vss-extension.json
```

### PowerShell task SDK

All six tasks use the `PowerShell3` execution handler and root-level entry scripts that read pipeline inputs through `Get-VstsInput`. The existing parameterized scripts under each task's `Code` directory remain callable by the integration tests.

`Restore-TaskSdk.ps1` downloads the pinned VstsTaskSdk version `0.21.8` from the PowerShell Gallery once and copies it into every task's `ps_modules\VstsTaskSdk` directory. It flattens the Gallery's version subdirectory so `VstsTaskSdk.psd1`, `VstsTaskSdk.psm1`, and the SDK's supporting files are directly beneath `VstsTaskSdk`, as required by the handler. Generated SDK directories are ignored by Git but included in the VSIX through the extension's existing `Tasks` file entry.

The Azure DevOps build and `New-Version.ps1` both perform this restoration automatically and stop on restoration errors. Agents running the packaged tasks do not need PowerShell Gallery access. See Microsoft's [PowerShell task SDK documentation](https://github.com/microsoft/azure-pipelines-task-lib/blob/master/powershell/Docs/README.md).

The checked-in task and extension versions are `0.0.0` placeholders. CI supplies the actual `2.3` release-series version with an automatically incremented patch and updates all task versions during packaging. Manual builds use the version selected through `New-Version.ps1`, or the versions you set before invoking `tfx` directly.

### Unit tests

Use Pester `4.10.1` with Windows PowerShell. Run only the non-privileged unit tests with:

```PowerShell
Import-Module Pester -RequiredVersion 4.10.1
Invoke-Pester -Script .\src\SharedTaskCode -EnableExit
```

Some existing test files install Pester at startup, so those files also require module-installation permission. The handler tests use implementation stubs with the real scripts' parameter validation; they do not create or modify Scheduled Tasks. CI runs only the unit-test directory. The tests under `src\IntegrationTests` modify the host OS and must be run separately on a suitable test machine.

### Publishing the VSIX package

You can manually publish a new version of the extension at [my personal Azure DevOps Marketplace extensions page][MyAzureDevOpsMarketplaceExtensionsUrl].

<!-- Links -->
[ExtensionsAzureDevOpsMarketplaceUrl]: https://marketplace.visualstudio.com/items?itemName=deadlydog.WindowsScheduledTasksBuildAndReleaseTasks
[AzureDevOpsBuildPipelineUrl]: https://dev.azure.com/deadlydog/OpenSource/_build?definitionId=32
[AzureDevOpsReleasePipelineUrl]: https://dev.azure.com/deadlydog/OpenSource/_release?view=all&definitionId=1
[MyAzureDevOpsMarketplaceExtensionsUrl]: https://marketplace.visualstudio.com/manage/publishers/deadlydog
[NodeJsDownloadUrl]: https://nodejs.org/en/download
