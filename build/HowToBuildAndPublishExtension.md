# How to build and publish the VSTS extension's VSIX package

## Prerequisites

You need to have Node.js installed - https://nodejs.org/en/download

Once node is installed, insall the TFS Cross Platform Command Line Interface (tfx-cli) with the command:

```cmd
npm i -g tfx-cli
```

## Creating the VSIX package

Before creating the VSIX package be sure to update the `version` element in the `vss-extension.json` and `task.json` files appropriately.

To create the VSIX package file, run the following command from the directory containing the `vss-extension.json` file:

```cmd
tfx extension create --manifest-globs vss-extension.json
```

## Publishing the VSIX package

For now this must be done manually via your TFS instance or the [VSTS Marketplace][VstsMarketplaceUrl].


<!-- Links -->
[VstsMarketplaceUrl]: https://marketplace.visualstudio.com/vsts