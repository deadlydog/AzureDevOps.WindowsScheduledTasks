# How to build and publish the Azure DevOps extension's VSIX package

## Automated builds and deployment

The building and publishing of this extension is fully automated via an Azure DevOps pipeline.

Every time a change is committed to the `master` branch [a new build][AzureDevOpsBuildPipelineUrl] is made.

If the build succeeds, [a new release][AzureDevOpsReleasePipelineUrl] will automatically be created which will publish the new version to [the Azure DevOps marketplace][ExtensionsAzureDevOpsMarketplaceUrl].

## Manual builds and deployments

If you want to manually build and publish a new version of the extension, you can follow these steps.

### Prerequisites

You need to have Node.js installed. [Get it here][NodeJsDownloadUrl].

Once node is installed, install the TFS Cross Platform Command Line Interface (tfx-cli) with the command:

```cmd
npm i -g tfx-cli
```

### Creating the VSIX package

#### Automated process to create the VSIX package

You can simply run the `New-Version.ps1` script to create a new VSIX package.
It will prompt you for the version number, and then create the VSIX file for you.

#### Manual process to create the VSIX package

Before creating the VSIX package be sure to update the `version` element in the `vss-extension.json` and `task.json` files appropriately.

To create the VSIX package file, run the following command from the directory containing the `vss-extension.json` file:

```cmd
tfx extension create --manifest-globs vss-extension.json
```

### Publishing the VSIX package

You can manually publish a new version of the extension at [my personal Azure DevOps Marketplace extensions page][MyAzureDevOpsMarketplaceExtensionsUrl].

<!-- Links -->
[ExtensionsAzureDevOpsMarketplaceUrl]: https://marketplace.visualstudio.com/items?itemName=deadlydog.WindowsScheduledTasksBuildAndReleaseTasks
[AzureDevOpsBuildPipelineUrl]: https://dev.azure.com/deadlydog/OpenSource/_build?definitionId=19
[AzureDevOpsReleasePipelineUrl]: https://dev.azure.com/deadlydog/OpenSource/_release?view=all&definitionId=1
[MyAzureDevOpsMarketplaceExtensionsUrl]: https://marketplace.visualstudio.com/manage/publishers/deadlydog
[NodeJsDownloadUrl]: https://nodejs.org/en/download